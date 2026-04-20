/// Result of a speech-to-text (STT/ASR) transcription operation.
class SttResult {
  /// Whether the transcription was successful.
  final bool success;

  /// The transcribed text.
  final String transcription;

  /// ISO 639-1 language code of the audio (e.g. 'fon').
  final String language;

  /// Duration of the audio in seconds, or null if not available.
  final double? duration;

  const SttResult({
    required this.success,
    required this.transcription,
    required this.language,
    this.duration,
  });

  /// Creates an [SttResult] from API JSON response.
  factory SttResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return SttResult(
      success: json['success'] as bool,
      transcription: data['transcription'] as String,
      language: data['language'] as String,
      duration: (data['duration'] as num?)?.toDouble(),
    );
  }

  @override
  String toString() => 'SttResult([$language] "$transcription")';
}
