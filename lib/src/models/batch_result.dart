/// A single item in a batch translation result.
class BatchTranslationItem {
  /// Position in the original batch (0-indexed).
  final int index;

  /// Whether this item was translated successfully.
  final bool success;

  /// The original text that was translated.
  final String originalText;

  /// The translated text, or null if translation failed.
  final String? translatedText;

  /// Error message if translation failed, or null if successful.
  final String? error;

  const BatchTranslationItem({
    required this.index,
    required this.success,
    required this.originalText,
    this.translatedText,
    this.error,
  });

  /// Creates a [BatchTranslationItem] from API JSON response.
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
  /// Whether the entire batch operation was successful.
  final bool success;

  /// List of translation results, one per input text.
  final List<BatchTranslationItem> items;

  const BatchTranslationResult({
    required this.success,
    required this.items,
  });

  /// Creates a [BatchTranslationResult] from API JSON response.
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
