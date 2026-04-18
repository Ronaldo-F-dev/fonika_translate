import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class FonikaHttpClient {
  final String baseUrl;
  final String? apiToken;
  final Duration timeout;

  FonikaHttpClient({
    required this.baseUrl,
    this.apiToken,
    this.timeout = const Duration(seconds: 60),
  });

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (apiToken != null) 'Authorization': 'Bearer $apiToken',
      };

  Map<String, String> get _authOnlyHeaders => {
        if (apiToken != null) 'Authorization': 'Bearer $apiToken',
      };

  Future<Map<String, dynamic>> get(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    final response =
        await http.get(uri, headers: _headers).timeout(timeout);
    return _handleJson(response);
  }

  Future<Map<String, dynamic>> post(
      String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await http
        .post(uri, headers: _headers, body: jsonEncode(body))
        .timeout(timeout);
    return _handleJson(response);
  }

  Future<Uint8List> postBytes(
      String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await http
        .post(uri, headers: _headers, body: jsonEncode(body))
        .timeout(timeout);
    _checkStatus(response);
    return response.bodyBytes;
  }

  Future<dynamic> postMultipart(
    String path,
    Map<String, String> fields,
    Map<String, http.MultipartFile> files, {
    bool returnBytes = false,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll(_authOnlyHeaders)
      ..fields.addAll(fields)
      ..files.addAll(files.values);

    final streamed = await request.send().timeout(timeout);
    final response = await http.Response.fromStream(streamed);

    if (returnBytes) {
      _checkStatus(response);
      return response.bodyBytes;
    }
    return _handleJson(response);
  }

  Map<String, dynamic> _handleJson(http.Response response) {
    _checkStatus(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  void _checkStatus(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw FonikaApiException(
        statusCode: response.statusCode,
        message: _extractError(response.body),
      );
    }
  }

  String _extractError(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      return json['detail']?.toString() ??
          json['message']?.toString() ??
          body;
    } catch (_) {
      return body;
    }
  }
}

class FonikaApiException implements Exception {
  final int statusCode;
  final String message;

  const FonikaApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'FonikaApiException($statusCode): $message';
}
