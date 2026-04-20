# fonika_translate

**Multilingual translation, TTS and ASR for Flutter** — built by [229Langues](https://229langues.bj).

Supports African languages (Fon, Yoruba, Hausa, Adja, Bariba) + 100+ world languages.  
**Offline-first**: local keys → device cache → API, with automatic retry and exponential backoff.

[![pub version](https://img.shields.io/pub/v/fonika_translate.svg)](https://pub.dev/packages/fonika_translate)

---

## Features

| Feature | African languages | European / World languages |
|---|---|---|
| Text translation | ✅ API (100+ langs incl. Bariba) | ✅ Same API |
| Batch translation | ✅ | ✅ |
| TTS (audio synthesis) | ✅ API → Fon, Yoruba, Hausa | ✅ Platform TTS (flutter_tts) |
| ASR (speech-to-text) | ✅ API → Fon, Adja, Yoruba, Hausa | ✅ Platform ASR (speech_to_text) |
| Local translations (offline) | ✅ | ✅ |
| Device cache (SharedPreferences) | ✅ | ✅ |
| Retry with backoff | ✅ | ✅ |
| Flutter widgets | ✅ | ✅ |
| PDF translation | ✅ | ✅ |
| TXT file translation | ✅ | ✅ |
| PDF text extraction | ✅ | ✅ |

---

## Installation

```yaml
dependencies:
  fonika_translate: ^0.1.0
```

### Android permissions

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.INTERNET"/>
```

### iOS permissions

Add to `ios/Runner/Info.plist`:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>Microphone access is needed for speech recognition.</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>Speech recognition is used for voice input.</string>
```

---

## Quick start

```dart
import 'package:fonika_translate/fonika_translate.dart';

final fonika = FonikaTranslate(
  apiToken: 'YOUR_TOKEN',      // API token
  maxRetries: 3,               // retries on 5xx / 429
  deviceCacheTtl: const Duration(days: 7),
);

await fonika.init();
```

---

## Flutter widgets

### FonikaProvider

Wrap your app once with `FonikaProvider` to make the client available anywhere in the widget tree:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final fonika = FonikaTranslate(apiToken: 'YOUR_TOKEN');
  await fonika.init();

  // Load your local translations (optional)
  fonika.loadTranslations({
    'fr': {'greeting': 'Bonjour !', 'app': {'title': 'Mon App'}},
    'en': {'greeting': 'Hello!',    'app': {'title': 'My App'}},
  });

  runApp(
    FonikaProvider(
      client: fonika,
      child: const MyApp(),
    ),
  );
}
```

Retrieve the client anywhere below in the tree:

```dart
final fonika = FonikaProvider.of(context);
```

### FonikaTranslatedText

Translates a key or plain text and renders it as a `Text` widget. Checks local translations first — no network call if the key is found:

```dart
// Resolves 'greeting' from local translations → 'Hello!' (toLang: en)
FonikaTranslatedText(
  'greeting',
  toLang: 'en',
  style: const TextStyle(fontWeight: FontWeight.bold),
)

// Falls back to API for arbitrary text
FonikaTranslatedText(
  'Bonjour le monde',
  toLang: 'en',
)
```

### FonikaSpeakButton

A ready-to-use speak icon button. Automatically routes to the 229Langues API for African languages and to the platform TTS for all other languages:

```dart
FonikaSpeakButton(
  text: 'Bonjour le monde',
  language: 'fr',    // platform TTS
  iconSize: 28,
)

FonikaSpeakButton(
  text: 'È dó wɛ̀',
  language: 'fon',   // 229Langues API
  iconSize: 28,
)
```

### FonikaListenButton

A mic toggle button that uses the platform ASR engine. Fires `onResult` with the final transcript and `onPartialResult` during speech:

```dart
FonikaListenButton(
  language: 'fr',
  iconSize: 36,
  onResult:        (text) => print('Final: $text'),
  onPartialResult: (text) => print('Partial: $text'),
  onError:         (e)    => print('Error: $e'),
)
```

### FonikaTranslationField

A `TextField` that automatically translates its content in real-time as the user types. Perfect for forms where users need live translation feedback:

```dart
FonikaTranslationField(
  controller: myController,
  toLang: 'en',
  fromLang: 'fr',
  decoration: const InputDecoration(
    labelText: 'Type to translate',
    border: OutlineInputBorder(),
  ),
  debounceDuration: const Duration(milliseconds: 500),
)
```

The widget displays:
- **Loading state** while translating
- **Translated text** below the field in gray italic text
- **Error messages** if translation fails
- Custom translation display via `translationBuilder` parameter

---

## Translation

### Priority chain

Every `translate()` call follows this order — no API call is made unless necessary:

1. **Local translations** — keys loaded via `loadTranslations()` or assets
2. **Device cache** — SharedPreferences cache (configurable TTL)
3. **229Langues API** — network call with automatic retry/backoff

### Single text

```dart
final result = await fonika.translate(
  'Bonjour, comment allez-vous ?',
  fromLang: 'fr',
  toLang: 'en',
);
print(result.translatedText); // Hello, how are you?
print(result.fromLocal);      // true if from local/cache, false if from API
```

### Batch

```dart
final result = await fonika.translateBatch(
  ['Bonjour', 'Merci', 'Au revoir'],
  toLang: 'en',
);
for (final item in result.items) {
  print('${item.originalText} → ${item.translatedText}');
}
```

### Advanced options

```dart
await fonika.translate(
  'text',
  toLang: 'en',
  skipLocal: false,       // set true to bypass local translations
  skipDeviceCache: false, // set true to bypass device cache
  saveToCache: true,      // set false to skip writing to device cache
);
```

### Supported languages

```dart
final langs = await fonika.getLanguages();
print('${langs.total} languages available');
```

---

## Local translations (offline-first)

Local translations are **always checked first**. A matching key never triggers a network call.

### Load from a Map

```dart
fonika.loadTranslations({
  'fr': {
    'app': {'title': 'Mon Application'},
    'greeting': 'Bonjour !',
  },
  'en': {
    'app': {'title': 'My Application'},
    'greeting': 'Hello!',
  },
});

final t = await fonika.translate('greeting', toLang: 'fr');
print(t.translatedText); // Bonjour !
print(t.fromLocal);      // true
```

Nested keys are flattened with dot-notation: `app.title`, `auth.login.button`, etc.

### Load from Flutter assets

```yaml
# pubspec.yaml
flutter:
  assets:
    - assets/i18n/fr.json
    - assets/i18n/en.json
```

```dart
await fonika.init(assetPaths: [
  'assets/i18n/fr.json',
  'assets/i18n/en.json',
]);

// Or load additional locales after init:
await fonika.loadTranslationAssets(['assets/i18n/de.json']);
```

JSON format (flat or nested):

```json
{
  "greeting": "Bonjour !",
  "auth": {
    "login": "Se connecter",
    "logout": "Se déconnecter"
  }
}
```

### Direct local lookup (no API fallback)

```dart
final value = fonika.localTranslate('auth.login', 'fr');
// Returns null if not found
```

---

## Device cache

Translations returned by the API are automatically stored in SharedPreferences and reused on subsequent calls (until TTL expires). Configure the TTL in the constructor:

```dart
final fonika = FonikaTranslate(
  apiToken: 'YOUR_TOKEN',
  deviceCacheTtl: const Duration(days: 7), // default: 7 days
);
```

### Cache management

```dart
// Number of entries currently cached
final count = await fonika.getDeviceCacheCount();

// Remove only expired entries
final removed = await fonika.evictExpiredDeviceCache();

// Wipe the entire device cache
await fonika.clearDeviceCache();
```

---

## Retry and backoff

The client automatically retries failed requests on HTTP 5xx and 429 (rate limit) responses — useful for API cold starts:

```dart
final fonika = FonikaTranslate(
  apiToken: 'YOUR_TOKEN',
  maxRetries: 3, // attempts: 1 initial + 3 retries
);
```

Backoff delays: **1 s → 2 s → 4 s** (exponential doubling).

---

## TTS (Text-to-Speech)

### Speak — auto routing

`speak()` automatically selects the right engine based on language:

```dart
// French → platform TTS (flutter_tts)
await fonika.speak('Bonjour le monde', 'fr');

// Fon → 229Langues API (plays via audioplayers)
await fonika.speak('È dó wɛ̀', 'fon');
```

**African TTS languages**: `fon`, `yoruba`, `hausa`

### Get raw audio bytes (African languages only)

```dart
final tts = await fonika.tts('È dó wɛ̀', 'fon');
// tts.audioBytes — Uint8List (WAV for Fon, MP3 for Yoruba/Hausa)
// tts.audioFormat — 'wav' or 'mp3'
```

### Platform TTS controls

```dart
await fonika.stopSpeaking();
await fonika.pauseSpeaking();

final langs = await fonika.getDeviceTtsLanguages();
```

---

## ASR (Speech-to-Text)

### Transcribe an audio file (African languages)

```dart
import 'dart:io';

final result = await fonika.transcribeAudio(
  File('/path/to/audio.wav'),
  'fon',
);
print(result.transcription);
print(result.duration); // seconds
```

**African ASR languages**: `fon`, `adja`, `yoruba`, `hausa`

### Live microphone recognition (platform ASR)

```dart
await fonika.startListening(
  'fr',
  onResult: (text, isFinal) {
    print('$text${isFinal ? ' [final]' : '...'}');
  },
  onDone: () => print('Done'),
  listenFor: const Duration(seconds: 30),
  pauseFor: const Duration(seconds: 3),
);

// Stop early
await fonika.stopListening();

// Check state
print(fonika.isListening);
```

---

## PDF & file translation

```dart
import 'dart:io';

// Translate PDF — returns translated PDF bytes
final pdf = await fonika.translatePdf(File('doc.pdf'), toLang: 'fr');

// Translate PDF — returns JSON with translated text
final json = await fonika.translatePdf(
  File('doc.pdf'),
  toLang: 'en',
  returnJson: true,
);
print(json.translatedText);

// Extract text from PDF (no translation)
final extract = await fonika.extractPdfText(File('doc.pdf'));
print('${extract.totalPages} pages, ${extract.totalCharacters} chars');

// Translate a .txt file
final txt = await fonika.translateTxtFile(File('doc.txt'), toLang: 'en');
```

---

## API cache & health

```dart
// Server-side cache stats
final stats = await fonika.getCacheStats();
print('${stats.totalCached} cached, hit rate: ${stats.hitRate}');

// Clear server-side cache
await fonika.clearApiCache();

// API health
final health = await fonika.healthCheck();
print(health.isHealthy); // true
```

---

## Error handling

The package provides specific exception types for granular error handling:

```dart
try {
  await fonika.translate('Hello', toLang: 'fr');
} on FonikaInitException catch (e) {
  // fonika.init() was not called
  print('Initialize first: ${e.message}');
} on FonikaAuthException catch (e) {
  // Missing or invalid API token
  print('Auth error: ${e.message}');
} on LanguageNotSupportedException catch (e) {
  // Language code is not supported
  print('Language "${e.languageCode}" not supported');
} on FonikaNetworkException catch (e) {
  // Network timeout or connection issues
  print('Network error (${e.statusCode}): ${e.message}');
} on FonikaAsrException catch (e) {
  // Speech-to-text failed
  print('ASR error: ${e.message}');
} on FonikaTtsException catch (e) {
  // Text-to-speech failed
  print('TTS error: ${e.message}');
} on FonikaPdfException catch (e) {
  // PDF operation failed
  print('PDF error: ${e.message}');
} on FonikaApiException catch (e) {
  // Generic API error
  print('API error ${e.statusCode}: ${e.message}');
} on FonikaException catch (e) {
  // Catch all fonika exceptions
  print('Fonika error: ${e.message}');
} catch (e) {
  // Unexpected error
  print('Unexpected error: $e');
}
```

**Exception hierarchy:**
- `FonikaException` (base class)
  - `FonikaInitException` — client not initialized
  - `FonikaAuthException` — authentication failed
  - `LanguageNotSupportedException` — language not supported
  - `FonikaNetworkException` — network/timeout issues
  - `FonikaAsrException` — speech-to-text errors
  - `FonikaTtsException` — text-to-speech errors
  - `FonikaPdfException` — PDF operation errors
  - `FonikaApiException` — generic API errors (5xx, 4xx, etc)

---

## Advanced: LocalTranslationsService

```dart
fonika.local.merge('fr', {'new.key': 'nouvelle valeur'});
fonika.local.unload('de');
print(fonika.local.loadedLanguages);
print(fonika.local.totalKeys);
```

---

## Publisher

**[229Langues](https://229langues.bj)** — open-source tools for African language processing.

- Author: AWADEME Finanfa Ronaldo
- Contact: awademeronaldoo@gmail.com
- GitHub: [Ronaldo-F-dev](https://github.com/Ronaldo-F-dev)
