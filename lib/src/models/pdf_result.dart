import 'dart:typed_data';

/// Result of translating a PDF file.
///
/// Can return either translated PDF bytes (for PDF output) or extracted/translated text
/// (for JSON output).
class PdfTranslateResult {
  /// Whether the operation was successful.
  final bool success;

  /// Translated text if returned as JSON, null if returned as PDF.
  final String? translatedText;

  /// PDF file bytes if returned as PDF, null if returned as JSON.
  final Uint8List? pdfBytes;

  /// Character count in the original PDF.
  final int? originalCharacters;

  /// Character count in the translated result.
  final int? translatedCharacters;

  /// Message from the API (e.g. error details).
  final String? message;

  const PdfTranslateResult({
    required this.success,
    this.translatedText,
    this.pdfBytes,
    this.originalCharacters,
    this.translatedCharacters,
    this.message,
  });

  /// Returns true if the result contains JSON text (not PDF).
  bool get isJson => translatedText != null;

  /// Creates a [PdfTranslateResult] from API JSON response.
  factory PdfTranslateResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    return PdfTranslateResult(
      success: json['success'] as bool,
      translatedText: data['text'] as String?,
      originalCharacters: data['original_characters'] as int?,
      translatedCharacters: data['translated_characters'] as int?,
      message: json['message'] as String?,
    );
  }

  /// Creates a [PdfTranslateResult] from raw PDF bytes.
  factory PdfTranslateResult.fromBytes(Uint8List bytes) {
    return PdfTranslateResult(success: true, pdfBytes: bytes);
  }
}

/// Result of extracting text from a PDF file (without translation).
class PdfExtractResult {
  /// Whether the extraction was successful.
  final bool success;

  /// Full concatenated text from all pages.
  final String fullText;

  /// List of text extracted from each page.
  final List<String> pages;

  /// Total number of pages in the PDF.
  final int totalPages;

  /// Total number of characters extracted.
  final int totalCharacters;

  const PdfExtractResult({
    required this.success,
    required this.fullText,
    required this.pages,
    required this.totalPages,
    required this.totalCharacters,
  });

  /// Creates a [PdfExtractResult] from API JSON response.
  factory PdfExtractResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return PdfExtractResult(
      success: json['success'] as bool,
      fullText: data['full_text'] as String,
      pages: (data['pages'] as List<dynamic>).cast<String>(),
      totalPages: data['total_pages'] as int,
      totalCharacters: data['total_characters'] as int,
    );
  }
}
