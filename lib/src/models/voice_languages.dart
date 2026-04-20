/// Available languages for TTS and ASR operations from the API.
class VoiceLanguagesResult {
  /// Map of languages supported for text-to-speech, keyed by language code.
  final Map<String, VoiceLanguageInfo> tts;

  /// Map of languages supported for speech-to-text, keyed by language code.
  final Map<String, VoiceLanguageInfo> asr;

  const VoiceLanguagesResult({required this.tts, required this.asr});

  /// Creates a [VoiceLanguagesResult] from API JSON response.
  factory VoiceLanguagesResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return VoiceLanguagesResult(
      tts: _parse(data['tts'] as Map<String, dynamic>? ?? {}),
      asr: _parse(data['asr'] as Map<String, dynamic>? ?? {}),
    );
  }

  static Map<String, VoiceLanguageInfo> _parse(Map<String, dynamic> map) {
    return map.map(
      (k, v) => MapEntry(
        k,
        VoiceLanguageInfo.fromJson(v as Map<String, dynamic>),
      ),
    );
  }
}

/// Information about a single language supported for TTS or ASR.
class VoiceLanguageInfo {
  /// Human-readable language name.
  final String name;

  /// Model or voice identifier used for this language, if applicable.
  final String? model;

  const VoiceLanguageInfo({required this.name, this.model});

  /// Creates a [VoiceLanguageInfo] from API JSON response.
  factory VoiceLanguageInfo.fromJson(Map<String, dynamic> json) {
    return VoiceLanguageInfo(
      name: json['name'] as String,
      model: json['model'] as String?,
    );
  }
}
