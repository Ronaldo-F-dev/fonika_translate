import 'dart:typed_data';

class TtsResult {
  final bool success;
  final String language;
  final String text;
  final Uint8List? audioBytes;
  final String? audioFormat;

  const TtsResult({
    required this.success,
    required this.language,
    required this.text,
    this.audioBytes,
    this.audioFormat,
  });

  bool get hasAudio => audioBytes != null && audioBytes!.isNotEmpty;
}
