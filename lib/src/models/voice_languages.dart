class VoiceLanguagesResult {
  final Map<String, VoiceLanguageInfo> tts;
  final Map<String, VoiceLanguageInfo> asr;

  const VoiceLanguagesResult({required this.tts, required this.asr});

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

class VoiceLanguageInfo {
  final String name;
  final String? model;

  const VoiceLanguageInfo({required this.name, this.model});

  factory VoiceLanguageInfo.fromJson(Map<String, dynamic> json) {
    return VoiceLanguageInfo(
      name: json['name'] as String,
      model: json['model'] as String?,
    );
  }
}
