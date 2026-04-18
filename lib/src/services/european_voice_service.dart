import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Maps ISO 639-1 language codes to BCP-47 locale codes for platform TTS/ASR.
const Map<String, String> languageBcp47 = {
  // European
  'af': 'af-ZA',
  'be': 'be-BY',
  'bg': 'bg-BG',
  'bs': 'bs-BA',
  'ca': 'ca-ES',
  'cs': 'cs-CZ',
  'cy': 'cy-GB',
  'da': 'da-DK',
  'de': 'de-DE',
  'el': 'el-GR',
  'en': 'en-US',
  'eo': 'eo',
  'es': 'es-ES',
  'et': 'et-EE',
  'eu': 'eu-ES',
  'fi': 'fi-FI',
  'fr': 'fr-FR',
  'ga': 'ga-IE',
  'gl': 'gl-ES',
  'hr': 'hr-HR',
  'hu': 'hu-HU',
  'hy': 'hy-AM',
  'is': 'is-IS',
  'it': 'it-IT',
  'ka': 'ka-GE',
  'kk': 'kk-KZ',
  'lb': 'lb-LU',
  'lt': 'lt-LT',
  'lv': 'lv-LV',
  'mk': 'mk-MK',
  'mt': 'mt-MT',
  'nl': 'nl-NL',
  'no': 'nb-NO',
  'pl': 'pl-PL',
  'pt': 'pt-PT',
  'ro': 'ro-RO',
  'ru': 'ru-RU',
  'sk': 'sk-SK',
  'sl': 'sl-SI',
  'sq': 'sq-AL',
  'sr': 'sr-RS',
  'sv': 'sv-SE',
  'tr': 'tr-TR',
  'uk': 'uk-UA',
  // Asian & other widely supported
  'ar': 'ar-SA',
  'bn': 'bn-IN',
  'fa': 'fa-IR',
  'gu': 'gu-IN',
  'he': 'he-IL',
  'hi': 'hi-IN',
  'id': 'id-ID',
  'ja': 'ja-JP',
  'km': 'km-KH',
  'kn': 'kn-IN',
  'ko': 'ko-KR',
  'lo': 'lo-LA',
  'ml': 'ml-IN',
  'mr': 'mr-IN',
  'ms': 'ms-MY',
  'my': 'my-MM',
  'ne': 'ne-NP',
  'pa': 'pa-IN',
  'si': 'si-LK',
  'sw': 'sw-KE',
  'ta': 'ta-IN',
  'te': 'te-IN',
  'th': 'th-TH',
  'ur': 'ur-PK',
  'vi': 'vi-VN',
  'zh': 'zh-CN',
  'zu': 'zu-ZA',
};

/// Resolves a language code to a BCP-47 locale.
/// Accepts both short codes ('fr') and full locales ('fr-FR').
String resolveBcp47(String lang) {
  if (lang.contains('-') || lang.contains('_')) return lang;
  return languageBcp47[lang.toLowerCase()] ?? lang;
}

class EuropeanVoiceService {
  late final FlutterTts _tts;
  late final SpeechToText _stt;

  bool _ttsInitialized = false;
  bool _sttInitialized = false;
  bool _isListening = false;

  double speechRate;
  double pitch;
  double volume;

  EuropeanVoiceService({
    this.speechRate = 0.5,
    this.pitch = 1.0,
    this.volume = 1.0,
  });

  // ---------------------------------------------------------------------------
  // Lifecycle

  Future<void> init() async {
    _tts = FlutterTts();
    _stt = SpeechToText();
    await _initTts();
    _ttsInitialized = true;
  }

  Future<void> _initTts() async {
    await _tts.setVolume(volume);
    await _tts.setSpeechRate(speechRate);
    await _tts.setPitch(pitch);
  }

  Future<bool> initStt() async {
    if (_sttInitialized) return true;
    _sttInitialized = await _stt.initialize(
      onError: (_) {},
      onStatus: (_) {},
    );
    return _sttInitialized;
  }

  Future<void> dispose() async {
    await _tts.stop();
    await _stt.stop();
  }

  // ---------------------------------------------------------------------------
  // TTS

  /// Speaks [text] using the device's platform TTS engine.
  ///
  /// [language] accepts ISO codes ('fr', 'en') or BCP-47 ('fr-FR', 'en-US').
  Future<void> speak(String text, String language) async {
    if (!_ttsInitialized) await init();
    final locale = resolveBcp47(language);
    await _tts.setLanguage(locale);
    await _tts.speak(text);
  }

  Future<void> stopSpeaking() async {
    await _tts.stop();
  }

  Future<void> pauseSpeaking() async {
    await _tts.pause();
  }

  /// Returns list of languages available on the device for TTS.
  Future<List<String>> availableTtsLanguages() async {
    if (!_ttsInitialized) await init();
    final langs = await _tts.getLanguages as List<dynamic>?;
    return langs?.cast<String>() ?? [];
  }

  Future<void> setRate(double rate) async {
    speechRate = rate;
    await _tts.setSpeechRate(rate);
  }

  Future<void> setPitch(double p) async {
    pitch = p;
    await _tts.setPitch(p);
  }

  // ---------------------------------------------------------------------------
  // ASR / STT

  bool get isListening => _isListening;

  /// Starts live speech recognition for [language].
  ///
  /// [onResult] is called with partial and final transcriptions.
  /// [onDone] is called when recognition ends.
  Future<bool> startListening(
    String language, {
    required void Function(String text, bool isFinal) onResult,
    void Function()? onDone,
    Duration? listenFor,
    Duration? pauseFor,
  }) async {
    final available = await initStt();
    if (!available) return false;

    final locale = resolveBcp47(language).replaceAll('-', '_');
    _isListening = true;

    await _stt.listen(
      onResult: (SpeechRecognitionResult result) {
        onResult(result.recognizedWords, result.finalResult);
        if (result.finalResult) {
          _isListening = false;
          onDone?.call();
        }
      },
      localeId: locale,
      listenFor: listenFor ?? const Duration(seconds: 30),
      pauseFor: pauseFor ?? const Duration(seconds: 3),
      cancelOnError: true,
    );

    return true;
  }

  Future<void> stopListening() async {
    _isListening = false;
    await _stt.stop();
  }

  Future<void> cancelListening() async {
    _isListening = false;
    await _stt.cancel();
  }

  /// Returns list of locales available on the device for ASR.
  Future<List<String>> availableSttLocales() async {
    await initStt();
    final locales = await _stt.locales();
    return locales.map((l) => l.localeId).toList();
  }
}
