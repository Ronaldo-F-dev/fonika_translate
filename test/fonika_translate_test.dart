import 'package:flutter_test/flutter_test.dart';
import 'package:fonika_translate/fonika_translate.dart';

void main() {
  group('LocalTranslationsService', () {
    late LocalTranslationsService service;

    setUp(() {
      service = LocalTranslationsService();
    });

    test('loads flat map and translates key', () {
      service.load({
        'fr': {'greeting': 'Bonjour', 'farewell': 'Au revoir'},
        'en': {'greeting': 'Hello', 'farewell': 'Goodbye'},
      });

      expect(service.translate('greeting', 'fr'), 'Bonjour');
      expect(service.translate('greeting', 'en'), 'Hello');
      expect(service.translate('farewell', 'fr'), 'Au revoir');
    });

    test('flattens nested map to dot-notation keys', () {
      service.load({
        'fr': {
          'auth': {'login': 'Connexion', 'logout': 'Déconnexion'},
          'app': {'title': 'Mon Application'},
        },
      });

      expect(service.translate('auth.login', 'fr'), 'Connexion');
      expect(service.translate('auth.logout', 'fr'), 'Déconnexion');
      expect(service.translate('app.title', 'fr'), 'Mon Application');
    });

    test('returns null for missing key', () {
      service.load({'fr': {'hello': 'Bonjour'}});
      expect(service.translate('missing.key', 'fr'), isNull);
    });

    test('falls back to base language from regional variant', () {
      service.load({
        'en': {'title': 'Title'},
      });
      expect(service.translate('title', 'en-US'), 'Title');
      expect(service.translate('title', 'en-GB'), 'Title');
    });

    test('merge adds keys to existing language', () {
      service.load({'fr': {'a': 'Alpha'}});
      service.merge('fr', {'b': 'Beta'});
      expect(service.translate('a', 'fr'), 'Alpha');
      expect(service.translate('b', 'fr'), 'Beta');
    });

    test('loadFromJson parses JSON string', () {
      service.loadFromJson({'fr': '{"hello": "Bonjour", "world": "Monde"}'});
      expect(service.translate('hello', 'fr'), 'Bonjour');
      expect(service.translate('world', 'fr'), 'Monde');
    });

    test('unload removes a language', () {
      service.load({'fr': {'key': 'valeur'}});
      service.unload('fr');
      expect(service.translate('key', 'fr'), isNull);
    });

    test('clear removes all languages', () {
      service.load({
        'fr': {'a': 'A'},
        'en': {'a': 'B'},
      });
      service.clear();
      expect(service.loadedLanguages, isEmpty);
    });

    test('contains returns correct result', () {
      service.load({'fr': {'title': 'Titre'}});
      expect(service.contains('title', 'fr'), isTrue);
      expect(service.contains('missing', 'fr'), isFalse);
    });

    test('keysFor returns all keys for a language', () {
      service.load({'fr': {'a': '1', 'b': '2', 'c': '3'}});
      expect(service.keysFor('fr'), containsAll(['a', 'b', 'c']));
    });

    test('fallback parameter returned when key missing', () {
      service.load({'fr': {}});
      expect(
        service.translate('missing', 'fr', fallback: 'default'),
        'default',
      );
    });
  });

  group('TranslationResult', () {
    test('fromLocal sets correct fields', () {
      final result = TranslationResult.fromLocal('app.title', 'Mon App', 'fr');
      expect(result.success, isTrue);
      expect(result.fromLocal, isTrue);
      expect(result.translatedText, 'Mon App');
      expect(result.originalText, 'app.title');
      expect(result.targetLanguage, 'fr');
    });
  });

  group('HealthStatus', () {
    test('isHealthy returns true for healthy status', () {
      const status = HealthStatus(
        status: 'healthy',
        message: 'OK',
        database: 'connected',
      );
      expect(status.isHealthy, isTrue);
      expect(status.isDatabaseConnected, isTrue);
    });
  });

  group('AfricanVoiceService language detection', () {
    test('africanTtsLanguages contains fon, yoruba, hausa', () {
      expect(africanTtsLanguages, containsAll(['fon', 'yoruba', 'hausa']));
    });

    test('africanAsrLanguages contains fon, adja, yoruba, hausa', () {
      expect(africanAsrLanguages,
          containsAll(['fon', 'adja', 'yoruba', 'hausa']));
    });
  });

  group('resolveBcp47', () {
    test('resolves fr to fr-FR', () {
      expect(resolveBcp47('fr'), 'fr-FR');
    });

    test('resolves en to en-US', () {
      expect(resolveBcp47('en'), 'en-US');
    });

    test('passthrough for already-qualified locale', () {
      expect(resolveBcp47('fr-CA'), 'fr-CA');
    });

    test('passthrough for unknown code', () {
      expect(resolveBcp47('xyz'), 'xyz');
    });
  });

  group('TranslationResult serialization (device cache)', () {
    test('toJson / fromCacheJson round-trip', () {
      const original = TranslationResult(
        success: true,
        translatedText: 'Hello',
        sourceLanguage: 'fr',
        sourceLanguageName: 'French',
        targetLanguage: 'en',
        targetLanguageName: 'English',
        originalText: 'Bonjour',
        fromLocal: false,
      );

      final json = original.toJson();
      final restored = TranslationResult.fromCacheJson(json);

      expect(restored.success, original.success);
      expect(restored.translatedText, original.translatedText);
      expect(restored.sourceLanguage, original.sourceLanguage);
      expect(restored.targetLanguage, original.targetLanguage);
      expect(restored.originalText, original.originalText);
      expect(restored.fromLocal, original.fromLocal);
    });

    test('toJson includes all required fields', () {
      const result = TranslationResult(
        success: true,
        translatedText: 'Goodbye',
        sourceLanguage: 'fr',
        sourceLanguageName: 'French',
        targetLanguage: 'en',
        targetLanguageName: 'English',
        originalText: 'Au revoir',
      );
      final json = result.toJson();
      expect(json.containsKey('translatedText'), isTrue);
      expect(json.containsKey('sourceLanguage'), isTrue);
      expect(json.containsKey('targetLanguage'), isTrue);
      expect(json.containsKey('originalText'), isTrue);
      expect(json.containsKey('fromLocal'), isTrue);
    });
  });
}
