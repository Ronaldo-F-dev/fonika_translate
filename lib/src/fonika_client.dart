import 'dart:io';

import 'package:audioplayers/audioplayers.dart';

import 'client/http_client.dart';
import 'models/batch_result.dart';
import 'models/cache_stats.dart';
import 'models/health_status.dart';
import 'models/language.dart';
import 'models/pdf_result.dart';
import 'models/stt_result.dart';
import 'models/translation_result.dart';
import 'models/tts_result.dart';
import 'models/voice_languages.dart';
import 'services/african_voice_service.dart';
import 'services/cache_service.dart';
import 'services/european_voice_service.dart';
import 'services/local_translations_service.dart';
import 'services/pdf_service.dart';
import 'services/translation_service.dart';

export 'services/african_voice_service.dart'
    show africanTtsLanguages, africanAsrLanguages;
export 'services/european_voice_service.dart' show resolveBcp47, languageBcp47;

/// Main entry point for the fonika_translate package.
///
/// Centralizes translation, TTS, ASR, PDF and local translations in one class.
///
/// ## Quick start
/// ```dart
/// final fonika = FonikaTranslate(apiToken: 'YOUR_TOKEN');
/// await fonika.init();
///
/// // API translation
/// final result = await fonika.translate('Bonjour', toLang: 'en');
/// print(result.translatedText); // Hello
///
/// // Local-first translation (key lookup before API)
/// fonika.loadTranslations({'fr': {'app.title': 'Mon Application'}});
/// final t = await fonika.translate('app.title', toLang: 'fr');
/// print(t.fromLocal); // true
///
/// // Speak in French (platform TTS)
/// await fonika.speak('Bonjour le monde', 'fr');
///
/// // Speak in Fon (API TTS)
/// final tts = await fonika.tts('È dó wɛ̀', 'fon');
/// ```
class FonikaTranslate {
  static const String defaultBaseUrl = 'https://ronaldodev-api.hf.space';

  final String? apiToken;
  final String baseUrl;
  final Duration timeout;

  late final FonikaHttpClient _http;
  late final TranslationService _translation;
  late final LocalTranslationsService _local;
  late final AfricanVoiceService _africanVoice;
  late final EuropeanVoiceService _europeanVoice;
  late final PdfService _pdf;
  late final CacheService _cache;

  bool _initialized = false;

  FonikaTranslate({
    this.apiToken,
    this.baseUrl = defaultBaseUrl,
    this.timeout = const Duration(seconds: 60),
    double ttsSpeechRate = 0.5,
    double ttsPitch = 1.0,
    double ttsVolume = 1.0,
  }) {
    _http = FonikaHttpClient(
      baseUrl: baseUrl,
      apiToken: apiToken,
      timeout: timeout,
    );
    _translation = TranslationService(_http);
    _local = LocalTranslationsService();
    _africanVoice = AfricanVoiceService(_http);
    _europeanVoice = EuropeanVoiceService(
      speechRate: ttsSpeechRate,
      pitch: ttsPitch,
      volume: ttsVolume,
    );
    _pdf = PdfService(_http);
    _cache = CacheService(_http);
  }

  /// Initializes platform TTS engine and optionally loads asset translations.
  ///
  /// Call this once, typically in your app's `initState` or service locator.
  /// [assetPaths]: list of Flutter asset paths to load as local translations.
  Future<void> init({List<String>? assetPaths}) async {
    await _europeanVoice.init();
    if (assetPaths != null && assetPaths.isNotEmpty) {
      await _local.loadFromAssets(assetPaths);
    }
    _initialized = true;
  }

  void _assertInit() {
    if (!_initialized) {
      throw StateError(
          'FonikaTranslate not initialized. Call await fonika.init() first.');
    }
  }

  // ---------------------------------------------------------------------------
  // Local Translations

  /// Loads translations from a Map. Prioritized over API calls.
  ///
  /// Supports nested JSON (flattened to dot-notation internally):
  /// ```dart
  /// fonika.loadTranslations({
  ///   'fr': {'app': {'title': 'Mon App'}, 'greeting': 'Bonjour'},
  ///   'en': {'app': {'title': 'My App'}, 'greeting': 'Hello'},
  /// });
  /// ```
  void loadTranslations(Map<String, Map<String, dynamic>> translations) {
    _local.load(translations);
  }

  /// Loads translations from Flutter asset files.
  ///
  /// ```dart
  /// await fonika.loadTranslationAssets(['assets/i18n/fr.json', 'assets/i18n/en.json']);
  /// ```
  Future<void> loadTranslationAssets(List<String> assetPaths) async {
    await _local.loadFromAssets(assetPaths);
  }

  /// Loads translations from raw JSON strings keyed by language code.
  void loadTranslationsFromJson(Map<String, String> jsonByLang) {
    _local.loadFromJson(jsonByLang);
  }

  /// Direct local lookup without API fallback.
  ///
  /// Returns null if the key is not found in local translations.
  String? localTranslate(String key, String lang) =>
      _local.translate(key, lang);

  /// Exposes the local translations service for advanced use.
  LocalTranslationsService get local => _local;

  // ---------------------------------------------------------------------------
  // Translation

  /// Translates [text] to [toLang].
  ///
  /// **Priority:**
  /// 1. If [text] matches a key in local translations for [toLang] → local result (no API call)
  /// 2. API call with automatic language detection
  ///
  /// Set [skipLocal] to true to bypass local lookup and always call the API.
  Future<TranslationResult> translate(
    String text, {
    String toLang = 'en',
    String fromLang = 'auto',
    bool saveToCache = true,
    bool skipLocal = false,
  }) async {
    if (!skipLocal) {
      final localValue = _local.translate(text, toLang);
      if (localValue != null) {
        return TranslationResult.fromLocal(text, localValue, toLang);
      }
    }
    return _translation.translate(text,
        toLang: toLang, fromLang: fromLang, saveToCache: saveToCache);
  }

  /// Translates a list of [texts] in one API call.
  ///
  /// Local lookup is applied per item — only items not found locally are
  /// sent to the API.
  Future<BatchTranslationResult> translateBatch(
    List<String> texts, {
    String toLang = 'en',
    String fromLang = 'auto',
    bool skipLocal = false,
  }) async {
    if (skipLocal) {
      return _translation.translateBatch(texts, toLang: toLang, fromLang: fromLang);
    }

    final toApi = <int, String>{};
    final localResults = <int, String>{};

    for (var i = 0; i < texts.length; i++) {
      final local = _local.translate(texts[i], toLang);
      if (local != null) {
        localResults[i] = local;
      } else {
        toApi[i] = texts[i];
      }
    }

    // All resolved locally
    if (toApi.isEmpty) {
      return BatchTranslationResult(
        success: true,
        items: List.generate(
          texts.length,
          (i) => BatchTranslationItem(
            index: i,
            success: true,
            originalText: texts[i],
            translatedText: localResults[i],
          ),
        ),
      );
    }

    // Translate only unknown texts via API
    final apiResult = await _translation.translateBatch(
      toApi.values.toList(),
      toLang: toLang,
      fromLang: fromLang,
    );

    final apiKeys = toApi.keys.toList();
    final merged = List.generate(texts.length, (i) {
      if (localResults.containsKey(i)) {
        return BatchTranslationItem(
          index: i,
          success: true,
          originalText: texts[i],
          translatedText: localResults[i],
        );
      }
      final apiIndex = apiKeys.indexOf(i);
      final apiItem = apiResult.items[apiIndex];
      return BatchTranslationItem(
        index: i,
        success: apiItem.success,
        originalText: apiItem.originalText,
        translatedText: apiItem.translatedText,
        error: apiItem.error,
      );
    });

    return BatchTranslationResult(success: apiResult.success, items: merged);
  }

  /// Returns all languages supported by the API.
  Future<LanguagesResult> getLanguages() => _translation.getLanguages();

  // ---------------------------------------------------------------------------
  // TTS

  /// Speaks [text] in [language] using the appropriate engine:
  /// - African (fon / yoruba / hausa): fetches audio from the 229Langues API
  ///   and plays it via audioplayers.
  /// - All other languages: uses the device platform TTS (flutter_tts).
  ///
  /// For African languages, this internally calls [tts] and plays the bytes.
  Future<void> speak(String text, String language) async {
    _assertInit();
    final lang = language.toLowerCase();
    if (africanTtsLanguages.contains(lang)) {
      final result = await _africanVoice.tts(text, lang);
      if (result.hasAudio) {
        await _playAfricanAudio(result);
      }
    } else {
      await _europeanVoice.speak(text, language);
    }
  }

  /// Returns raw audio bytes from the 229Langues API TTS.
  ///
  /// Only supported for African languages: fon, yoruba, hausa.
  /// For other languages use [speak] which uses the platform engine.
  Future<TtsResult> tts(String text, String language) async {
    final lang = language.toLowerCase();
    if (!africanTtsLanguages.contains(lang)) {
      throw UnsupportedError(
          'tts() only supports African languages: ${africanTtsLanguages.join(', ')}.\n'
          'For other languages, use speak() which uses platform TTS.');
    }
    return _africanVoice.tts(text, lang);
  }

  Future<void> stopSpeaking() async {
    _assertInit();
    await _europeanVoice.stopSpeaking();
  }

  Future<void> pauseSpeaking() async {
    _assertInit();
    await _europeanVoice.pauseSpeaking();
  }

  /// Returns voice languages available from the 229Langues API.
  Future<VoiceLanguagesResult> getAfricanVoiceLanguages() =>
      _africanVoice.getVoiceLanguages();

  /// Returns TTS languages available on the device (platform).
  Future<List<String>> getDeviceTtsLanguages() {
    _assertInit();
    return _europeanVoice.availableTtsLanguages();
  }

  // ---------------------------------------------------------------------------
  // ASR / STT

  /// Transcribes an audio [file] in [language] using the 229Langues API.
  ///
  /// Only supported for African languages: fon, adja, yoruba, hausa.
  Future<SttResult> transcribeAudio(File audioFile, String language) {
    return _africanVoice.stt(audioFile, language);
  }

  /// Starts live speech recognition using the device microphone.
  ///
  /// Uses the device platform ASR (speech_to_text).
  /// [language] accepts ISO codes or BCP-47 locales.
  /// [onResult] is called with (text, isFinal) pairs.
  Future<bool> startListening(
    String language, {
    required void Function(String text, bool isFinal) onResult,
    void Function()? onDone,
    Duration? listenFor,
    Duration? pauseFor,
  }) {
    _assertInit();
    return _europeanVoice.startListening(
      language,
      onResult: onResult,
      onDone: onDone,
      listenFor: listenFor,
      pauseFor: pauseFor,
    );
  }

  Future<void> stopListening() {
    _assertInit();
    return _europeanVoice.stopListening();
  }

  bool get isListening => _europeanVoice.isListening;

  /// Returns locales available for ASR on the device.
  Future<List<String>> getDeviceSttLocales() {
    _assertInit();
    return _europeanVoice.availableSttLocales();
  }

  // ---------------------------------------------------------------------------
  // PDF

  /// Translates a PDF file.
  ///
  /// If [returnJson] is true, returns the translated text as a string.
  /// Otherwise, returns the translated PDF as bytes.
  Future<PdfTranslateResult> translatePdf(
    File file, {
    String toLang = 'en',
    String fromLang = 'auto',
    bool returnJson = false,
  }) {
    return _pdf.translatePdf(file,
        toLang: toLang, fromLang: fromLang, returnJson: returnJson);
  }

  /// Extracts all text from a PDF file without translating.
  Future<PdfExtractResult> extractPdfText(File file) {
    return _pdf.extractText(file);
  }

  /// Translates a plain text (.txt) file.
  Future<PdfTranslateResult> translateTxtFile(
    File file, {
    String toLang = 'en',
    String fromLang = 'auto',
    bool returnJson = true,
  }) {
    return _pdf.translateTxtFile(file,
        toLang: toLang, fromLang: fromLang, returnJson: returnJson);
  }

  // ---------------------------------------------------------------------------
  // Cache & Health

  Future<CacheStats> getCacheStats() => _cache.getStats();

  Future<void> clearCache() => _cache.clear();

  Future<HealthStatus> healthCheck() => _cache.healthCheck();

  // ---------------------------------------------------------------------------
  // Private helpers

  final AudioPlayer _audioPlayer = AudioPlayer();

  Future<void> _playAfricanAudio(TtsResult result) async {
    await _audioPlayer.play(BytesSource(result.audioBytes!));
  }
}
