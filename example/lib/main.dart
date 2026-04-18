import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:fonika_translate/fonika_translate.dart';

late final FonikaTranslate fonika;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  fonika = FonikaTranslate(
    apiToken: dotenv.env['HF_TOKEN'],
    maxRetries: 3,
    deviceCacheTtl: const Duration(days: 7),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // FonikaProvider rend le client disponible dans tout l'arbre de widgets
    return FonikaProvider(
      client: fonika,
      child: MaterialApp(
        title: 'fonika_translate 0.1.0',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B6CA8)),
          useMaterial3: true,
        ),
        home: const _InitWrapper(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Wrapper d'initialisation — affiche un loader pendant fonika.init()
class _InitWrapper extends StatefulWidget {
  const _InitWrapper();

  @override
  State<_InitWrapper> createState() => _InitWrapperState();
}

class _InitWrapperState extends State<_InitWrapper> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await fonika.init();

    // Traductions locales — priorité absolue sur tout (cache + API)
    fonika.loadTranslations({
      'fr': {
        'app': {'title': 'Démo fonika_translate'},
        'greeting': 'Bonjour depuis les traductions locales !',
        'farewell': 'Au revoir !',
      },
      'en': {
        'app': {'title': 'fonika_translate Demo'},
        'greeting': 'Hello from local translations!',
        'farewell': 'Goodbye!',
      },
    });

    if (mounted) setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return const DemoHome();
  }
}

// ---------------------------------------------------------------------------
// App principale avec 3 onglets
class DemoHome extends StatelessWidget {
  const DemoHome({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('fonika_translate'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.translate), text: 'Traduction'),
              Tab(icon: Icon(Icons.record_voice_over), text: 'Voix'),
              Tab(icon: Icon(Icons.storage), text: 'Cache'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _TranslationTab(),
            _VoiceTab(),
            _CacheTab(),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// ONGLET 1 — Traduction
// ===========================================================================
class _TranslationTab extends StatefulWidget {
  const _TranslationTab();

  @override
  State<_TranslationTab> createState() => _TranslationTabState();
}

class _TranslationTabState extends State<_TranslationTab> {
  final _controller = TextEditingController(text: 'Bonjour, comment allez-vous ?');
  String _result = '';
  String _source = '';
  bool _fromLocal = false;
  bool _loading = false;

  Future<void> _translate() async {
    setState(() { _loading = true; _result = ''; });
    final r = await FonikaProvider.of(context).translate(
      _controller.text,
      fromLang: 'auto',
      toLang: 'en',
    );
    setState(() {
      _loading = false;
      _result = r.translatedText;
      _source = r.fromLocal ? 'local' : 'API';
      _fromLocal = r.fromLocal;
    });
  }

  Future<void> _translateLocalKey() async {
    setState(() { _loading = true; _result = ''; });
    // "greeting" est dans les traductions locales → zéro appel réseau
    final r = await FonikaProvider.of(context).translate('greeting', toLang: 'fr');
    setState(() {
      _loading = false;
      _result = r.translatedText;
      _source = 'local';
      _fromLocal = true;
    });
  }

  Future<void> _translateBatch() async {
    setState(() { _loading = true; _result = ''; });
    final r = await FonikaProvider.of(context).translateBatch(
      ['greeting', 'Merci beaucoup', 'farewell'],
      toLang: 'en',
    );
    setState(() {
      _loading = false;
      _result = r.items
          .map((i) => '${i.originalText}\n  → ${i.translatedText}')
          .join('\n\n');
      _source = 'batch (local + API)';
      _fromLocal = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- Widget FonikaTranslatedText en action ---
          _section('Widget FonikaTranslatedText'),
          const Text('Ces textes sont traduits automatiquement par le widget :',
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),
          _translatedCard('app.title', 'fr'),
          _translatedCard('greeting', 'en'),
          _translatedCard('Bonjour le monde', 'en'),

          const SizedBox(height: 24),

          // --- Traduction manuelle ---
          _section('Traduction manuelle'),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'Texte à traduire',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: _loading ? null : _translate,
                icon: const Icon(Icons.cloud),
                label: const Text('Traduire (auto)'),
              ),
              ElevatedButton.icon(
                onPressed: _loading ? null : _translateLocalKey,
                icon: const Icon(Icons.offline_bolt),
                label: const Text('Clé locale'),
              ),
              ElevatedButton.icon(
                onPressed: _loading ? null : _translateBatch,
                icon: const Icon(Icons.list),
                label: const Text('Batch'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_loading) const LinearProgressIndicator(),
          if (_result.isNotEmpty)
            _resultCard(
              title: 'Source : $_source${_fromLocal ? ' 🟢 offline' : ' 🌐 API'}',
              body: _result,
              color: _fromLocal ? Colors.green.shade50 : Colors.blue.shade50,
            ),
        ],
      ),
    );
  }

  Widget _translatedCard(String key, String toLang) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        dense: true,
        leading: const Icon(Icons.translate, size: 18),
        title: FonikaTranslatedText(
          key,
          toLang: toLang,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text('"$key" → $toLang',
            style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ),
    );
  }
}

// ===========================================================================
// ONGLET 2 — Voix
// ===========================================================================
class _VoiceTab extends StatefulWidget {
  const _VoiceTab();

  @override
  State<_VoiceTab> createState() => _VoiceTabState();
}

class _VoiceTabState extends State<_VoiceTab> {
  String _sttResult = 'Appuie sur le micro pour parler...';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- TTS via widgets ---
          _section('TTS — Widget FonikaSpeakButton'),
          const Text(
            'Appuie sur l\'icône pour entendre la synthèse vocale.\n'
            '🌍 Langues africaines → API  |  🌐 Autres → plateforme',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 12),
          ..._ttsItems.map((item) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: FonikaSpeakButton(
                text: item['text']!,
                language: item['lang']!,
                iconSize: 28,
              ),
              title: Text(item['text']!,
                  style: const TextStyle(fontWeight: FontWeight.w500)),
              subtitle: Text(
                '${item['label']} — ${item['engine']}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          )),

          const SizedBox(height: 24),

          // --- ASR via widget ---
          _section('ASR — Widget FonikaListenButton'),
          const Text(
            'Appuie sur le micro et parle en français.\nUtilise la reconnaissance vocale de la plateforme.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              FonikaListenButton(
                language: 'fr',
                iconSize: 36,
                onResult: (text) =>
                    setState(() => _sttResult = '✓ "$text"'),
                onPartialResult: (text) =>
                    setState(() => _sttResult = '... $text'),
                onError: (e) =>
                    setState(() => _sttResult = 'Erreur: $e'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(_sttResult,
                    style: const TextStyle(fontSize: 15)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static const _ttsItems = [
    {'text': 'Bonjour le monde', 'lang': 'fr', 'label': 'Français', 'engine': 'flutter_tts'},
    {'text': 'Hello world', 'lang': 'en', 'label': 'English', 'engine': 'flutter_tts'},
    {'text': 'Hola mundo', 'lang': 'es', 'label': 'Español', 'engine': 'flutter_tts'},
    {'text': 'È dó wɛ̀', 'lang': 'fon', 'label': 'Fon 🌍', 'engine': '229Langues API'},
    {'text': 'Ẹ káàárọ̀', 'lang': 'yoruba', 'label': 'Yoruba 🌍', 'engine': '229Langues API'},
  ];
}

// ===========================================================================
// ONGLET 3 — Cache & infos
// ===========================================================================
class _CacheTab extends StatefulWidget {
  const _CacheTab();

  @override
  State<_CacheTab> createState() => _CacheTabState();
}

class _CacheTabState extends State<_CacheTab> {
  int _deviceCacheCount = 0;
  String _healthStatus = '—';
  String _log = '';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _refreshCount();
  }

  Future<void> _refreshCount() async {
    final count = await FonikaProvider.of(context).getDeviceCacheCount();
    if (mounted) setState(() => _deviceCacheCount = count);
  }

  Future<void> _testCacheHit() async {
    setState(() { _loading = true; _log = ''; });
    final client = FonikaProvider.of(context);

    final sw1 = Stopwatch()..start();
    final r1 = await client.translate('Bonjour', fromLang: 'fr', toLang: 'en');
    sw1.stop();

    final sw2 = Stopwatch()..start();
    final r2 = await client.translate('Bonjour', fromLang: 'fr', toLang: 'en');
    sw2.stop();

    await _refreshCount();
    setState(() {
      _loading = false;
      _log =
          'Requête 1 : ${sw1.elapsedMilliseconds}ms — ${r1.fromLocal ? "local" : "API"}\n'
          'Requête 2 : ${sw2.elapsedMilliseconds}ms — ${r2.fromLocal ? "local" : "cache device ✅"}';
    });
  }

  Future<void> _clearDeviceCache() async {
    await FonikaProvider.of(context).clearDeviceCache();
    await _refreshCount();
    setState(() => _log = 'Cache device vidé.');
  }

  Future<void> _evictExpired() async {
    final removed = await FonikaProvider.of(context).evictExpiredDeviceCache();
    await _refreshCount();
    setState(() => _log = '$removed entrée(s) expirée(s) supprimée(s).');
  }

  Future<void> _checkHealth() async {
    setState(() { _loading = true; });
    final s = await FonikaProvider.of(context).healthCheck();
    setState(() {
      _loading = false;
      _healthStatus = '${s.status} | DB: ${s.database}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _section('Cache device (SharedPreferences)'),
          _infoTile(Icons.cached, 'Entrées en cache', '$_deviceCacheCount'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: _loading ? null : _testCacheHit,
                icon: const Icon(Icons.speed),
                label: const Text('Tester le cache hit'),
              ),
              OutlinedButton.icon(
                onPressed: _loading ? null : _evictExpired,
                icon: const Icon(Icons.auto_delete),
                label: const Text('Purger expirés'),
              ),
              OutlinedButton.icon(
                onPressed: _loading ? null : _clearDeviceCache,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Vider tout'),
                style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red),
              ),
            ],
          ),
          if (_loading) ...[
            const SizedBox(height: 8),
            const LinearProgressIndicator(),
          ],
          if (_log.isNotEmpty) ...[
            const SizedBox(height: 12),
            _resultCard(title: 'Résultat', body: _log,
                color: Colors.orange.shade50),
          ],

          const SizedBox(height: 24),
          _section('Retry automatique'),
          const Text(
            'Le client est configuré avec maxRetries: 3.\n'
            'En cas d\'erreur 5xx ou cold start HuggingFace,\n'
            'la requête est relancée avec backoff : 1s → 2s → 4s.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 8),
          _infoTile(Icons.refresh, 'Max retries', '3'),
          _infoTile(Icons.timelapse, 'Backoff', '1s → 2s → 4s'),
          _infoTile(Icons.wifi_off, 'Codes retryables', '5xx, 429'),

          const SizedBox(height: 24),
          _section('Santé de l\'API'),
          _infoTile(Icons.monitor_heart, 'Status', _healthStatus),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _loading ? null : _checkHealth,
            icon: const Icon(Icons.monitor_heart),
            label: const Text('Vérifier l\'API'),
          ),
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return ListTile(
      dense: true,
      leading: Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
      title: Text(label),
      trailing: Text(value,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary)),
    );
  }
}

// ===========================================================================
// Helpers communs
// ===========================================================================
Widget _section(String title) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );

Widget _resultCard(
    {required String title, required String body, required Color color}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.black12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(body, style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
      ],
    ),
  );
}
