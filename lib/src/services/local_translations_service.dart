import 'dart:convert';
import 'package:flutter/services.dart';

/// Offline-first translation store.
///
/// Priority order when calling [translate]:
///   1. Local translations loaded here
///   2. API (handled by the main [FonikaTranslate] client)
///
/// Supports dot-notation keys: "auth.login.title" → nested JSON.
/// Supports loading from Flutter assets or raw maps.
class LocalTranslationsService {
  final Map<String, Map<String, String>> _store = {};

  /// Total number of keys loaded across all languages.
  int get totalKeys =>
      _store.values.fold(0, (sum, map) => sum + map.length);

  /// Languages currently loaded.
  List<String> get loadedLanguages => _store.keys.toList();

  /// Load translations from a plain Map.
  ///
  /// Example:
  /// ```dart
  /// service.load({
  ///   'fr': {'app.title': 'Mon App', 'auth.login': 'Se connecter'},
  ///   'en': {'app.title': 'My App', 'auth.login': 'Login'},
  /// });
  /// ```
  void load(Map<String, Map<String, dynamic>> translations) {
    for (final entry in translations.entries) {
      _store[entry.key] = _flatten(entry.value);
    }
  }

  /// Load translations from Flutter asset files.
  ///
  /// Each file must be a JSON object. The language code is derived from the
  /// filename: `assets/i18n/fr.json` → `fr`, `assets/i18n/en-US.json` → `en-US`.
  ///
  /// Call this in [FonikaTranslate.init] or lazily before first use.
  ///
  /// ```dart
  /// await service.loadFromAssets([
  ///   'assets/i18n/fr.json',
  ///   'assets/i18n/en.json',
  /// ]);
  /// ```
  Future<void> loadFromAssets(List<String> assetPaths) async {
    for (final path in assetPaths) {
      final content = await rootBundle.loadString(path);
      final json = jsonDecode(content) as Map<String, dynamic>;
      final lang = _langCodeFromPath(path);
      _store[lang] = {...?_store[lang], ..._flatten(json)};
    }
  }

  /// Load translations from raw JSON strings, keyed by language code.
  ///
  /// Useful when you fetch translations from a remote source.
  void loadFromJson(Map<String, String> jsonByLang) {
    for (final entry in jsonByLang.entries) {
      final json = jsonDecode(entry.value) as Map<String, dynamic>;
      _store[entry.key] = {...?_store[entry.key], ..._flatten(json)};
    }
  }

  /// Merges additional keys into an already-loaded language.
  void merge(String lang, Map<String, dynamic> additional) {
    _store[lang] = {...?_store[lang], ..._flatten(additional)};
  }

  /// Removes all translations for a specific language.
  void unload(String lang) => _store.remove(lang);

  /// Clears all loaded translations.
  void clear() => _store.clear();

  /// Returns the translated string for [key] in [lang], or [fallback].
  ///
  /// Also checks the base language if a regional variant is provided:
  /// looking up `en-US` will also search `en` if not found.
  String? translate(String key, String lang, {String? fallback}) {
    final result = _store[lang]?[key] ??
        _store[_baseLang(lang)]?[key] ??
        fallback;
    return result;
  }

  /// Returns true if [key] exists in [lang] (or its base language).
  bool contains(String key, String lang) {
    return (_store[lang]?.containsKey(key) ?? false) ||
        (_store[_baseLang(lang)]?.containsKey(key) ?? false);
  }

  /// Returns all keys available for [lang].
  List<String> keysFor(String lang) =>
      {...?_store[lang], ...?_store[_baseLang(lang)]}.keys.toList();

  // ---------------------------------------------------------------------------

  String _langCodeFromPath(String path) {
    final filename = path.split('/').last;
    return filename.contains('.') ? filename.split('.').first : filename;
  }

  String _baseLang(String lang) {
    return lang.contains('-') ? lang.split('-').first : lang;
  }

  /// Recursively flattens nested JSON into dot-notation keys.
  Map<String, String> _flatten(Map<String, dynamic> json,
      {String prefix = ''}) {
    final result = <String, String>{};
    for (final entry in json.entries) {
      final key = prefix.isEmpty ? entry.key : '$prefix.${entry.key}';
      if (entry.value is Map<String, dynamic>) {
        result.addAll(
            _flatten(entry.value as Map<String, dynamic>, prefix: key));
      } else if (entry.value != null) {
        result[key] = entry.value.toString();
      }
    }
    return result;
  }
}
