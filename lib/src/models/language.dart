/// Represents a supported language.
class Language {
  /// ISO 639-1 language code (e.g. 'fr', 'en', 'fon').
  final String code;

  /// Human-readable language name (e.g. 'French', 'English', 'Fon').
  final String name;

  const Language({required this.code, required this.name});

  @override
  String toString() => '$code: $name';
}

/// Result of fetching all supported languages from the API.
class LanguagesResult {
  /// Whether the API call was successful.
  final bool success;

  /// Total number of supported languages.
  final int total;

  /// List of all supported languages.
  final List<Language> languages;

  const LanguagesResult({
    required this.success,
    required this.total,
    required this.languages,
  });

  /// Creates a [LanguagesResult] from API JSON response.
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

  /// Finds a language by its code.
  ///
  /// Returns the [Language] matching the given [code], or null if not found.
  Language? byCode(String code) {
    try {
      return languages.firstWhere((l) => l.code == code);
    } catch (_) {
      return null;
    }
  }
}
