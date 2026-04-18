class SttResult {
  final bool success;
  final String transcription;
  final String language;
  final double? duration;

  const SttResult({
    required this.success,
    required this.transcription,
    required this.language,
    this.duration,
  });

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
