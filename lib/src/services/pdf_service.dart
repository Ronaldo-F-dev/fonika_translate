import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../client/http_client.dart';
import '../models/pdf_result.dart';

/// Internal service for PDF translation and text extraction.
///
/// Handles PDF file operations including translation and text extraction.
/// Used internally by [FonikaTranslate] — not intended for direct use.
class PdfService {
  final FonikaHttpClient _client;

  PdfService(this._client);

  /// Translates a PDF file.
  ///
  /// If [returnJson] is true, returns translated text as JSON.
  /// If [returnJson] is false, returns the translated PDF as bytes.
  Future<PdfTranslateResult> translatePdf(
    File file, {
    String toLang = 'en',
    String fromLang = 'auto',
    bool returnJson = false,
  }) async {
    final multipartFile = await http.MultipartFile.fromPath('file', file.path);

    if (returnJson) {
      final json = await _client.postMultipart(
        '/api/v1/pdf/translate',
        {
          'from_lang': fromLang,
          'to_lang': toLang,
          'return_json': 'true',
        },
        {'file': multipartFile},
      ) as Map<String, dynamic>;
      return PdfTranslateResult.fromJson(json);
    }

    final bytes = await _client.postMultipart(
      '/api/v1/pdf/translate',
      {'from_lang': fromLang, 'to_lang': toLang},
      {'file': multipartFile},
      returnBytes: true,
    ) as Uint8List;

    return PdfTranslateResult.fromBytes(bytes);
  }

  /// Extracts text from a PDF file without translation.
  ///
  /// Returns a [PdfExtractResult] containing the full text and per-page text.
  Future<PdfExtractResult> extractText(File file) async {
    final multipartFile = await http.MultipartFile.fromPath('file', file.path);
    final json = await _client.postMultipart(
      '/api/v1/pdf/extract-text',
      {},
      {'file': multipartFile},
    ) as Map<String, dynamic>;
    return PdfExtractResult.fromJson(json);
  }

  Future<PdfTranslateResult> translateTxtFile(
    File file, {
    String toLang = 'en',
    String fromLang = 'auto',
    bool returnJson = true,
  }) async {
    final multipartFile = await http.MultipartFile.fromPath('file', file.path);
    final json = await _client.postMultipart(
      '/api/v1/text/translate-file',
      {
        'from_lang': fromLang,
        'to_lang': toLang,
        'return_json': returnJson.toString(),
      },
      {'file': multipartFile},
    ) as Map<String, dynamic>;
    return PdfTranslateResult.fromJson(json);
  }
}
