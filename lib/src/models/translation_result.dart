class TranslationResult {
  final bool success;
  final String translatedText;
  final String sourceLanguage;
  final String sourceLanguageName;
  final String targetLanguage;
  final String targetLanguageName;
  final String originalText;
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

  factory TranslationResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    final meta = data['metadata'] as Map<String, dynamic>? ?? {};
    return TranslationResult(
      success: json['success'] as bool,
      translatedText: data['text'] as String,
      sourceLanguage: data['source_language'] as String,
      sourceLanguageName: data['source_language_name'] as String,
      targetLanguage: data['target_language'] as String,
      targetLanguageName: data['target_language_name'] as String,
      originalText: meta['original_text'] as String? ?? '',
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

  @override
  String toString() => 'TranslationResult($originalText → $translatedText [$targetLanguage])';
}
