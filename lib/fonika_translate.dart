library fonika_translate;

export 'src/fonika_client.dart';

// Models
export 'src/models/batch_result.dart';
export 'src/models/cache_stats.dart';
export 'src/models/health_status.dart';
export 'src/models/language.dart';
export 'src/models/pdf_result.dart';
export 'src/models/stt_result.dart';
export 'src/models/translation_result.dart';
export 'src/models/tts_result.dart';
export 'src/models/voice_languages.dart';

// Exceptions
export 'src/client/http_client.dart' show FonikaApiException;

// Local translations (for advanced use)
export 'src/services/local_translations_service.dart';
