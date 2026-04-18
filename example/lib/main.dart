import 'package:flutter/material.dart';
import 'package:fonika_translate/fonika_translate.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'fonika_translate demo',
      home: TranslateDemo(),
    );
  }
}

class TranslateDemo extends StatefulWidget {
  const TranslateDemo({super.key});

  @override
  State<TranslateDemo> createState() => _TranslateDemoState();
}

class _TranslateDemoState extends State<TranslateDemo> {
  // ---------------------------------------------------------------------------
  // Initialize the client — replace YOUR_TOKEN with your Hugging Face token
  final FonikaTranslate fonika = FonikaTranslate(
    apiToken: 'YOUR_HF_TOKEN',
  );

  String _output = '';
  bool _listening = false;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  Future<void> _setup() async {
    // Initialize platform TTS/ASR engines
    await fonika.init();

    // Load local translations that take priority over API calls
    fonika.loadTranslations({
      'fr': {
        'app': {'title': 'Démo Traduction'},
        'greeting': 'Bonjour depuis les traductions locales !',
      },
      'en': {
        'app': {'title': 'Translation Demo'},
        'greeting': 'Hello from local translations!',
      },
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Examples

  Future<void> _translateText() async {
    final result = await fonika.translate(
      'Bonjour, comment allez-vous ?',
      fromLang: 'fr',
      toLang: 'en',
    );
    setState(() => _output =
        '[API] ${result.originalText}\n→ ${result.translatedText}');
  }

  Future<void> _translateLocalKey() async {
    // This hits local translations — no network call
    final result = await fonika.translate('greeting', toLang: 'en');
    setState(() => _output =
        '[Local: ${result.fromLocal}] ${result.originalText}\n→ ${result.translatedText}');
  }

  Future<void> _translateBatch() async {
    final result = await fonika.translateBatch(
      ['Bonjour', 'Merci', 'Au revoir'],
      fromLang: 'fr',
      toLang: 'en',
    );
    final lines = result.items
        .map((i) => '${i.originalText} → ${i.translatedText}')
        .join('\n');
    setState(() => _output = '[Batch]\n$lines');
  }

  Future<void> _speakFrench() async {
    // European language → uses platform TTS (flutter_tts)
    await fonika.speak('Bonjour le monde', 'fr');
    setState(() => _output = '[TTS] Speaking in French via platform engine');
  }

  Future<void> _speakFon() async {
    // African language → fetches audio bytes from 229Langues API
    final tts = await fonika.tts('È dó wɛ̀', 'fon');
    setState(() => _output =
        '[TTS African] Fon audio: ${tts.audioBytes?.length ?? 0} bytes (${tts.audioFormat})');
  }

  Future<void> _startListen() async {
    if (_listening) {
      await fonika.stopListening();
      setState(() => _listening = false);
      return;
    }
    setState(() {
      _listening = true;
      _output = '[ASR] Listening...';
    });
    await fonika.startListening(
      'fr',
      onResult: (text, isFinal) {
        setState(() => _output = '[ASR] $text${isFinal ? ' ✓' : '...'}');
      },
      onDone: () => setState(() => _listening = false),
    );
  }

  Future<void> _getLanguages() async {
    final result = await fonika.getLanguages();
    setState(() => _output =
        '[Languages] ${result.total} languages\nSample: ${result.languages.take(5).map((l) => l.name).join(', ')}...');
  }

  Future<void> _healthCheck() async {
    final status = await fonika.healthCheck();
    setState(() => _output =
        '[Health] ${status.status} | DB: ${status.database}\n${status.message}');
  }

  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('fonika_translate')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _btn('Translate (API)', _translateText),
                _btn('Translate (Local)', _translateLocalKey),
                _btn('Batch', _translateBatch),
                _btn('Speak FR', _speakFrench),
                _btn('Speak Fon', _speakFon),
                _btn(_listening ? 'Stop ASR' : 'Listen FR', _startListen),
                _btn('Languages', _getLanguages),
                _btn('Health', _healthCheck),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _output.isEmpty ? 'Tap a button to see results' : _output,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _btn(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(label),
    );
  }
}
