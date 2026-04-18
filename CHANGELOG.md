## 0.1.0

- **Device cache**: translations are stored locally with configurable TTL (default 7 days) — works offline after first fetch
- **Retry + backoff**: automatic retry (up to 3×) with exponential backoff on server errors and cold starts
- **Widgets**: `FonikaProvider`, `FonikaTranslatedText`, `FonikaSpeakButton`, `FonikaListenButton`
- **Full priority chain**: local keys → device cache → API
- New `FonikaTranslate` params: `maxRetries`, `deviceCacheTtl`
- New methods: `clearDeviceCache()`, `getDeviceCacheCount()`, `evictExpiredDeviceCache()`

## 0.0.2

- Fix: upgrade speech_to_text to v7.x for Android Gradle compatibility

## 0.0.1

- Initial release
- Translation: single text, batch, auto language detection
- Local translations: offline-first with JSON/Map support, dot-notation keys
- PDF: translate and extract text
- TTS: African languages via API (Fon, Yoruba, Hausa) + European via platform
- ASR: African languages via API (Fon, Adja, Yoruba, Hausa) + European via platform
- Cache: stats and clear
- Health check endpoint
