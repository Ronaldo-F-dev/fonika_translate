class Language {
  final String code;
  final String name;

  const Language({required this.code, required this.name});

  @override
  String toString() => '$code: $name';
}

class LanguagesResult {
  final bool success;
  final int total;
  final List<Language> languages;

  const LanguagesResult({
    required this.success,
    required this.total,
    required this.languages,
  });

  factory LanguagesResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    final langs = data['languages'] as Map<String, dynamic>;
    return LanguagesResult(
      success: json['success'] as bool,
      total: data['total'] as int,
      languages: langs.entries
          .map((e) => Language(code: e.key, name: e.value as String))
          .toList(),
    );
  }

  Language? byCode(String code) {
    try {
      return languages.firstWhere((l) => l.code == code);
    } catch (_) {
      return null;
    }
  }
}
