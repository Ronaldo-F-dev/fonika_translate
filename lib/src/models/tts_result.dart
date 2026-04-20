import 'dart:typed_data';

/// Result of a text-to-speech (TTS) operation.
///
/// Contains the audio bytes and format information. Typically used when calling
/// the API for African language TTS (fon, yoruba, hausa).
class TtsResult {
  /// Whether the TTS operation was successful.
  final bool success;

  /// ISO 639-1 language code (e.g. 'fon').
  final String language;

  /// The text that was synthesized.
  final String text;

  /// Raw audio bytes (WAV for Fon, MP3 for Yoruba/Hausa), or null if not available.
  final Uint8List? audioBytes;

  /// Audio format ('wav' or 'mp3'), or null if not available.
  final String? audioFormat;

  const TtsResult({
    required this.success,
    required this.language,
    required this.text,
    this.audioBytes,
    this.audioFormat,
  });

  /// Returns true if audio bytes are available and not empty.
  bool get hasAudio => audioBytes != null && audioBytes!.isNotEmpty;
}
