import '../client/http_client.dart';
import '../models/batch_result.dart';
import '../models/language.dart';
import '../models/translation_result.dart';

class TranslationService {
  final FonikaHttpClient _client;

  TranslationService(this._client);

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

  Future<LanguagesResult> getLanguages() async {
    final json = await _client.get('/api/v1/languages');
    return LanguagesResult.fromJson(json);
  }
}
