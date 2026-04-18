import 'dart:typed_data';

class PdfTranslateResult {
  final bool success;
  final String? translatedText;
  final Uint8List? pdfBytes;
  final int? originalCharacters;
  final int? translatedCharacters;
  final String? message;

  const PdfTranslateResult({
    required this.success,
    this.translatedText,
    this.pdfBytes,
    this.originalCharacters,
    this.translatedCharacters,
    this.message,
  });

  bool get isJson => translatedText != null;

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

  factory PdfTranslateResult.fromBytes(Uint8List bytes) {
    return PdfTranslateResult(success: true, pdfBytes: bytes);
  }
}

class PdfExtractResult {
  final bool success;
  final String fullText;
  final List<String> pages;
  final int totalPages;
  final int totalCharacters;

  const PdfExtractResult({
    required this.success,
    required this.fullText,
    required this.pages,
    required this.totalPages,
    required this.totalCharacters,
  });

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
