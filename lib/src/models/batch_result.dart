class BatchTranslationItem {
  final int index;
  final bool success;
  final String originalText;
  final String? translatedText;
  final String? error;

  const BatchTranslationItem({
    required this.index,
    required this.success,
    required this.originalText,
    this.translatedText,
    this.error,
  });

  factory BatchTranslationItem.fromJson(Map<String, dynamic> json) {
    return BatchTranslationItem(
      index: json['index'] as int,
      success: json['success'] as bool,
      originalText: json['original_text'] as String,
      translatedText: json['translated_text'] as String?,
      error: json['error'] as String?,
    );
  }
}

class BatchTranslationResult {
  final bool success;
  final List<BatchTranslationItem> items;

  const BatchTranslationResult({
    required this.success,
    required this.items,
  });

  factory BatchTranslationResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as List<dynamic>;
    return BatchTranslationResult(
      success: json['success'] as bool,
      items: data
          .map((e) =>
              BatchTranslationItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
