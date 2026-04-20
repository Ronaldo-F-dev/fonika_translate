import '../client/http_client.dart';
import '../models/batch_result.dart';
import '../models/language.dart';
import '../models/translation_result.dart';

/// Internal service for translation API calls.
///
/// This service handles all translation requests to the 229Langues API.
/// Used internally by [FonikaTranslate] — not intended for direct use.
class TranslationService {
  final FonikaHttpClient _client;

  TranslationService(this._client);

  /// Translates [text] to [toLang].
  ///
  /// Performs a single translation API call. Returns a [TranslationResult]
  /// containing the translated text and language metadata.
  Future<TranslationResult> translate(
    String text, {
    String toLang = 'en',
    String fromLang = 'auto',
    bool saveToCache = true,
  }) async {
    final json = await _client.post('/api/v1/translate', {
      'text': text,
      'from_lang': fromLang,
      'to_lang': toLang,
      'save_to_cache': saveToCache,
    });
    return TranslationResult.fromJson(json);
  }

  /// Translates a batch of [texts] to [toLang].
  ///
  /// More efficient than multiple [translate] calls. Returns a [BatchTranslationResult]
  /// containing individual results for each input text.
  Future<BatchTranslationResult> translateBatch(
    List<String> texts, {
    String toLang = 'en',
    String fromLang = 'auto',
  }) async {
    final json = await _client.post('/api/v1/translate/batch', {
      'texts': texts,
      'from_lang': fromLang,
      'to_lang': toLang,
    });
    return BatchTranslationResult.fromJson(json);
  }

  /// Fetches all supported languages from the API.
  ///
  /// Returns a [LanguagesResult] containing language codes and names.
  Future<LanguagesResult> getLanguages() async {
    final json = await _client.get('/api/v1/languages');
    return LanguagesResult.fromJson(json);
  }
}
