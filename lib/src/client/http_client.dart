import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../exceptions.dart';

class FonikaHttpClient {
  final String baseUrl;
  final String apiToken;
  final Map<String, String> headers;
  final String authorizationToken;
  final Duration timeout;
  final http.Client _client;

  /// Max number of retry attempts on server errors or timeouts.
  /// Set to 0 to disable retries.
  final int maxRetries;

  FonikaHttpClient({
    required this.baseUrl,
    required this.apiToken,
    required this.authorizationToken,
    Map<String, String>? headers,
    this.timeout = const Duration(seconds: 60),
    this.maxRetries = 3,
    http.Client? client,
  })  : headers = headers ?? const {},
        _client = client ?? http.Client();

  Map<String, String> get _jsonHeaders => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authorizationToken',
        'X-API-Key': apiToken,
        ...headers,
      };

  Map<String, String> get _multipartHeaders => {
        'Authorization': 'Bearer $authorizationToken',
        'X-API-Key': apiToken,
        ...headers,
      };

  // ---------------------------------------------------------------------------
  // Public methods — all wrapped with retry

  Future<Map<String, dynamic>> get(String path) => _withRetry(() => _get(path));

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) =>
      _withRetry(() => _post(path, body));

  Future<Uint8List> postBytes(String path, Map<String, dynamic> body) =>
      _withRetry(() => _postBytes(path, body));

  Future<dynamic> postMultipart(
    String path,
    Map<String, String> fields,
    Map<String, http.MultipartFile> files, {
    bool returnBytes = false,
  }) =>
      _withRetry(
          () => _postMultipart(path, fields, files, returnBytes: returnBytes));

  // ---------------------------------------------------------------------------
  // Retry logic

  Future<T> _withRetry<T>(Future<T> Function() fn) async {
    int attempt = 0;
    while (true) {
      try {
        return await fn();
      } on FonikaApiException catch (e) {
        if (attempt >= maxRetries || !_isRetryable(e.statusCode)) rethrow;
        await _backoff(attempt);
        attempt++;
      } catch (_) {
        // TimeoutException, SocketException, etc.
        if (attempt >= maxRetries) rethrow;
        await _backoff(attempt);
        attempt++;
      }
    }
  }

  /// Retryable: 5xx server errors and 429 rate limit (HF Spaces cold start).
  bool _isRetryable(int statusCode) => statusCode >= 500 || statusCode == 429;

  /// Exponential backoff: 1s, 2s, 4s, 8s…
  Future<void> _backoff(int attempt) =>
      Future.delayed(Duration(seconds: math.pow(2, attempt).toInt()));

  // ---------------------------------------------------------------------------
  // Internal implementations (no retry)

  Future<Map<String, dynamic>> _get(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    final response =
        await _client.get(uri, headers: _jsonHeaders).timeout(timeout);
    return _handleJson(response);
  }

  Future<Map<String, dynamic>> _post(
      String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await _client
        .post(uri, headers: _jsonHeaders, body: jsonEncode(body))
        .timeout(timeout);
    return _handleJson(response);
  }

  Future<Uint8List> _postBytes(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await _client
        .post(uri, headers: _jsonHeaders, body: jsonEncode(body))
        .timeout(timeout);
    _checkStatus(response);
    return response.bodyBytes;
  }

  Future<dynamic> _postMultipart(
    String path,
    Map<String, String> fields,
    Map<String, http.MultipartFile> files, {
    bool returnBytes = false,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll(_multipartHeaders)
      ..fields.addAll(fields)
      ..files.addAll(files.values);

    final streamed = await _client.send(request).timeout(timeout);
    final response = await http.Response.fromStream(streamed);

    if (returnBytes) {
      _checkStatus(response);
      return response.bodyBytes;
    }
    return _handleJson(response);
  }

  // ---------------------------------------------------------------------------

  Map<String, dynamic> _handleJson(http.Response response) {
    _checkStatus(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  void _checkStatus(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw FonikaApiException(
        response.statusCode,
        _extractError(response.body),
      );
    }
  }

  String _extractError(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      return json['detail']?.toString() ?? json['message']?.toString() ?? body;
    } catch (_) {
      return body;
    }
  }
}
