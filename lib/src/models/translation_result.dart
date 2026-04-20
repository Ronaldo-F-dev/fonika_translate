/// Result of a single text translation operation.
///
/// Contains the translated text, language metadata, and origin information
/// (whether it came from local translations, device cache, or API).
class TranslationResult {
  /// Whether the API call was successful.
  final bool success;

  /// The translated text.
  final String translatedText;

  /// ISO 639-1 code of the detected or specified source language (e.g. 'fr').
  final String sourceLanguage;

  /// Human-readable name of the source language (e.g. 'French').
  final String sourceLanguageName;

  /// ISO 639-1 code of the target language (e.g. 'en').
  final String targetLanguage;

  /// Human-readable name of the target language (e.g. 'English').
  final String targetLanguageName;

  /// The original text that was translated.
  final String originalText;

  /// Whether this translation came from local translations (true) or API (false).
  final bool fromLocal;

  const TranslationResult({
    required this.success,
    required this.translatedText,
    required this.sourceLanguage,
    required this.sourceLanguageName,
    required this.targetLanguage,
    required this.targetLanguageName,
    required this.originalText,
    this.fromLocal = false,
  });

  /// Creates a [TranslationResult] from API JSON response.
  factory TranslationResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    final meta = data['metadata'] as Map<String, dynamic>? ?? {};
    return TranslationResult(
      success: (json['success'] as bool?) ?? true,
      translatedText: (data['text'] as String?) ?? '',
      sourceLanguage: (data['source_language'] as String?) ?? 'auto',
      sourceLanguageName: (data['source_language_name'] as String?) ?? '',
      targetLanguage: (data['target_language'] as String?) ?? '',
      targetLanguageName: (data['target_language_name'] as String?) ?? '',
      originalText: (meta['original_text'] as String?) ?? '',
    );
  }

  factory TranslationResult.fromLocal(
      String key, String value, String targetLang) {
    return TranslationResult(
      success: true,
      translatedText: value,
      sourceLanguage: 'local',
      sourceLanguageName: 'Local',
      targetLanguage: targetLang,
      targetLanguageName: targetLang,
      originalText: key,
      fromLocal: true,
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'translatedText': translatedText,
        'sourceLanguage': sourceLanguage,
        'sourceLanguageName': sourceLanguageName,
        'targetLanguage': targetLanguage,
        'targetLanguageName': targetLanguageName,
        'originalText': originalText,
        'fromLocal': fromLocal,
      };

  factory TranslationResult.fromCacheJson(Map<String, dynamic> json) {
    return TranslationResult(
      success: json['success'] as bool,
      translatedText: json['translatedText'] as String,
      sourceLanguage: json['sourceLanguage'] as String,
      sourceLanguageName: json['sourceLanguageName'] as String,
      targetLanguage: json['targetLanguage'] as String,
      targetLanguageName: json['targetLanguageName'] as String,
      originalText: json['originalText'] as String,
      fromLocal: json['fromLocal'] as bool? ?? false,
    );
  }

  @override
  String toString() => 'TranslationResult($originalText → $translatedText [$targetLanguage])';
}
