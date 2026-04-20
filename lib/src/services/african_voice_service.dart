import 'dart:io';
import 'package:http/http.dart' as http;
import '../client/http_client.dart';
import '../models/stt_result.dart';
import '../models/tts_result.dart';
import '../models/voice_languages.dart';

/// Supported African languages for TTS via the 229Langues API.
const Set<String> africanTtsLanguages = {'fon', 'yoruba', 'hausa'};

/// Supported African languages for ASR (speech-to-text) via the 229Langues API.
const Set<String> africanAsrLanguages = {'fon', 'adja', 'yoruba', 'hausa'};

/// Audio format returned per language.
const Map<String, String> africanAudioFormat = {
  'fon': 'wav',
  'yoruba': 'mp3',
  'hausa': 'mp3',
};

/// Internal service for African language TTS and ASR via the 229Langues API.
///
/// Handles speech synthesis and speech-to-text for African languages.
/// Used internally by [FonikaTranslate] — not intended for direct use.
class AfricanVoiceService {
  final FonikaHttpClient _client;

  AfricanVoiceService(this._client);

  /// Returns true if the language is supported for TTS.
  bool supportsTts(String language) =>
      africanTtsLanguages.contains(language.toLowerCase());

  /// Returns true if the language is supported for ASR.
  bool supportsAsr(String language) =>
      africanAsrLanguages.contains(language.toLowerCase());

  /// Returns raw audio bytes for the given [text] in [language].
  ///
  /// [language] must be one of: fon, yoruba, hausa.
  /// Returns [TtsResult] with [audioBytes] set on success.
  Future<TtsResult> tts(String text, String language) async {
    final lang = language.toLowerCase();
    if (!supportsTts(lang)) {
      throw UnsupportedError(
          'African TTS does not support "$language". '
          'Supported: ${africanTtsLanguages.join(', ')}');
    }

    final bytes =
        await _client.postBytes('/api/v1/tts', {'text': text, 'language': lang});

    return TtsResult(
      success: true,
      language: lang,
      text: text,
      audioBytes: bytes,
      audioFormat: africanAudioFormat[lang] ?? 'wav',
    );
  }

  /// Transcribes an audio [file] in [language].
  ///
  /// [language] must be one of: fon, adja, yoruba, hausa.
  Future<SttResult> stt(File file, String language) async {
    final lang = language.toLowerCase();
    if (!supportsAsr(lang)) {
      throw UnsupportedError(
          'African ASR does not support "$language". '
          'Supported: ${africanAsrLanguages.join(', ')}');
    }

    final multipartFile =
        await http.MultipartFile.fromPath('audio', file.path);
    final json = await _client.postMultipart(
      '/api/v1/stt',
      {'language': lang},
      {'audio': multipartFile},
    ) as Map<String, dynamic>;

    return SttResult.fromJson(json);
  }

  Future<VoiceLanguagesResult> getVoiceLanguages() async {
    final json = await _client.get('/api/v1/voice/languages');
    return VoiceLanguagesResult.fromJson(json);
  }
}
