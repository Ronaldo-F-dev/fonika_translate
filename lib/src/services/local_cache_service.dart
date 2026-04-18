import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/translation_result.dart';

/// Persistent local cache for API translations, stored on the device.
///
/// Priority in [FonikaTranslate.translate]:
///   1. Local translations (key-based)
///   2. **This cache** (previous API results)
///   3. API call
///
/// Entries expire after [ttl] (default 7 days).
class LocalCacheService {
  static const String _prefix = 'fonika_c_';

  final Duration ttl;
  SharedPreferences? _prefs;

  LocalCacheService({this.ttl = const Duration(days: 7)});

  Future<void> _ensureInit() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Returns a cached [TranslationResult] or null if not found / expired.
  Future<TranslationResult?> get(
      String text, String fromLang, String toLang) async {
    await _ensureInit();
    final key = _key(text, fromLang, toLang);
    final raw = _prefs!.getString(key);
    if (raw == null) return null;

    final json = jsonDecode(raw) as Map<String, dynamic>;
    final ts = json['_ts'] as int?;
    if (ts != null) {
      final ageMs = DateTime.now().millisecondsSinceEpoch - ts;
      if (ageMs > ttl.inMilliseconds) {
        await _prefs!.remove(key);
        return null;
      }
    }
    return TranslationResult.fromCacheJson(json);
  }

  /// Stores a [TranslationResult] in the cache.
  Future<void> put(String text, String fromLang, String toLang,
      TranslationResult result) async {
    await _ensureInit();
    final key = _key(text, fromLang, toLang);
    final json = result.toJson();
    json['_ts'] = DateTime.now().millisecondsSinceEpoch;
    await _prefs!.setString(key, jsonEncode(json));
  }

  /// Removes all cached translations from the device.
  Future<void> clear() async {
    await _ensureInit();
    final keys =
        _prefs!.getKeys().where((k) => k.startsWith(_prefix)).toList();
    for (final k in keys) {
      await _prefs!.remove(k);
    }
  }

  /// Number of entries currently in the device cache.
  Future<int> count() async {
    await _ensureInit();
    return _prefs!.getKeys().where((k) => k.startsWith(_prefix)).length;
  }

  /// Removes entries older than [ttl] to free up storage.
  Future<int> evictExpired() async {
    await _ensureInit();
    final keys =
        _prefs!.getKeys().where((k) => k.startsWith(_prefix)).toList();
    int removed = 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final k in keys) {
      final raw = _prefs!.getString(k);
      if (raw == null) continue;
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        final ts = json['_ts'] as int?;
        if (ts != null && (now - ts) > ttl.inMilliseconds) {
          await _prefs!.remove(k);
          removed++;
        }
      } catch (_) {
        await _prefs!.remove(k);
        removed++;
      }
    }
    return removed;
  }

  String _key(String text, String fromLang, String toLang) {
    // Short hash to keep keys concise in SharedPreferences
    final hash = text.hashCode.abs();
    return '$_prefix${fromLang}_${toLang}_$hash';
  }
}
