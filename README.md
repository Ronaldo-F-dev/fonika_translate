# fonika_translate

**Multilingual translation, TTS and ASR for Flutter** — built by [229Langues](https://229langues.bj).

Supports African languages (Fon, Yoruba, Hausa, Adja, Bariba) + 100+ world languages.  
**Offline-first**: local translations are always checked before any API call.

---

## Features

| Feature | African languages | European / World languages |
|---|---|---|
| Text translation | ✅ API (100+ langs incl. Bariba) | ✅ Same API |
| Batch translation | ✅ | ✅ |
| TTS (audio synthesis) | ✅ API → Fon, Yoruba, Hausa | ✅ Platform TTS (flutter_tts) |
| ASR (speech-to-text) | ✅ API → Fon, Adja, Yoruba, Hausa | ✅ Platform ASR (speech_to_text) |
| Local translations (offline) | ✅ | ✅ |
| PDF translation | ✅ | ✅ |
| TXT file translation | ✅ | ✅ |
| PDF text extraction | ✅ | ✅ |
| Translation cache | ✅ | ✅ |

---

## Installation

```yaml
dependencies:
  fonika_translate: ^0.0.1
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

final fonika = FonikaTranslate(apiToken: 'YOUR_HF_TOKEN');
await fonika.init();
```

---

## Translation

### Single text

```dart
final result = await fonika.translate(
  'Bonjour, comment allez-vous ?',
  fromLang: 'fr',
  toLang: 'en',
);
print(result.translatedText); // Hello, how are you?
print(result.fromLocal);      // false — came from API
```

### Batch

```dart
final result = await fonika.translateBatch(
  ['Bonjour', 'Merci', 'Au revoir'],
  fromLang: 'fr',
  toLang: 'en',
);
for (final item in result.items) {
  print('${item.originalText} → ${item.translatedText}');
}
```

### Supported languages

```dart
final langs = await fonika.getLanguages();
print('${langs.total} languages available');
```

---

## Local translations (offline-first)

Local translations are **always checked first**. If a key is found, no API call is made.

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

// Resolved locally — no network call
final t = await fonika.translate('greeting', toLang: 'fr');
print(t.translatedText); // Bonjour !
print(t.fromLocal);      // true
```

Nested keys are flattened using dot-notation: `app.title`, `auth.login.button`, etc.

### Load from Flutter assets

Add your JSON files to `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/i18n/fr.json
    - assets/i18n/en.json
```

Then load them:

```dart
await fonika.init(assetPaths: [
  'assets/i18n/fr.json',
  'assets/i18n/en.json',
]);

// Or after init:
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

## TTS (Text-to-Speech)

### Speak — auto routing

`speak()` automatically selects the right engine based on language:

```dart
// French → platform TTS (flutter_tts)
await fonika.speak('Bonjour le monde', 'fr');

// Fon → 229Langues API audio (plays via audioplayers)
await fonika.speak('È dó wɛ̀', 'fon');
```

### Get raw audio bytes (African languages only)

```dart
final tts = await fonika.tts('È dó wɛ̀', 'fon');
// tts.audioBytes — Uint8List (WAV for Fon, MP3 for Yoruba/Hausa)
// tts.audioFormat — 'wav' or 'mp3'
```

**African TTS languages**: `fon`, `yoruba`, `hausa`

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
print(result.duration); // in seconds
```

**African ASR languages**: `fon`, `adja`, `yoruba`, `hausa`

### Live microphone recognition (platform ASR)

```dart
await fonika.startListening(
  'fr',
  onResult: (text, isFinal) {
    print('$text${isFinal ? ' ✓' : '...'}');
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

## Cache & Health

```dart
final stats = await fonika.getCacheStats();
print('${stats.totalCached} cached, hit rate: ${stats.hitRate}');

await fonika.clearCache();

final health = await fonika.healthCheck();
print(health.isHealthy); // true
```

---

## Advanced: LocalTranslationsService

Access the underlying service for fine-grained control:

```dart
fonika.local.merge('fr', {'new.key': 'nouvelle valeur'});
fonika.local.unload('de');
print(fonika.local.loadedLanguages);
print(fonika.local.totalKeys);
```

---

## Error handling

```dart
try {
  await fonika.translate('Hello', toLang: 'fr');
} on FonikaApiException catch (e) {
  print('API error ${e.statusCode}: ${e.message}');
} on UnsupportedError catch (e) {
  print('Language not supported: $e');
}
```

---

## Publisher

**[229Langues](https://229langues.bj)** — open-source tools for African language processing.

- Author: AWADEME Finanfa Ronaldo
- Contact: awademeronaldoo@gmail.com
- GitHub: [Ronaldo-F-dev](https://github.com/Ronaldo-F-dev)
