import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../services/database_service.dart';
import '../services/export_service.dart';
import '../services/translation_service.dart';

class PhrasebookScreen extends StatefulWidget {
  const PhrasebookScreen({super.key});
  @override
  State<PhrasebookScreen> createState() => _PhrasebookScreenState();
}

class _PhrasebookScreenState extends State<PhrasebookScreen> {
  List<Map<String, dynamic>> _phrases = [];
  bool _loading = true;
  String _category = 'all';
  String _search = '';
  Language _selectedLang = langFrench; // selected language for audio
  final _searchCtrl = TextEditingController();
  final _player = AudioPlayer();
  String? _playingKey;
  bool _isLoadingAudio = false;
  String? _loadingKey;

  final _builtIn = [
    {'en': 'Hello, how are you?', 'fr': 'Bonjour, comment allez-vous?', 'tw': 'Maakye, wo ho te sɛn?', 'cat': 'greetings'},
    {'en': 'Thank you very much', 'fr': 'Merci beaucoup', 'tw': 'Meda wo ase paa', 'cat': 'greetings'},
    {'en': 'Good morning', 'fr': 'Bonjour', 'tw': 'Maakye', 'cat': 'greetings'},
    {'en': 'Good night', 'fr': 'Bonne nuit', 'tw': 'Da yie', 'cat': 'greetings'},
    {'en': 'See you later', 'fr': 'À bientôt', 'tw': 'Yɛbɛhyia bio', 'cat': 'greetings'},
    {'en': 'Please call a doctor', 'fr': 'Appelez un médecin s\'il vous plaît', 'tw': 'Mesrɛ wo, frɛ ɔdokita', 'cat': 'medical'},
    {'en': 'I am in pain', 'fr': 'J\'ai mal', 'tw': 'Me ho yɛ me ya', 'cat': 'medical'},
    {'en': 'I need medicine', 'fr': 'J\'ai besoin de médicaments', 'tw': 'Mehia ɔhare', 'cat': 'medical'},
    {'en': 'Where is the hospital?', 'fr': 'Où est l\'hôpital?', 'tw': 'Ɔyaresabea no wɔ he?', 'cat': 'medical'},
    {'en': 'I need help', 'fr': 'J\'ai besoin d\'aide', 'tw': 'Mehia boa', 'cat': 'emergency'},
    {'en': 'Call the police', 'fr': 'Appelez la police', 'tw': 'Frɛ apolisi', 'cat': 'emergency'},
    {'en': 'There is a fire', 'fr': 'Il y a un incendie', 'tw': 'Ogya rekum', 'cat': 'emergency'},
    {'en': 'How much does it cost?', 'fr': 'Combien ça coûte?', 'tw': 'Sɛn na wɔtɔn no?', 'cat': 'business'},
    {'en': 'I want to buy this', 'fr': 'Je veux acheter ceci', 'tw': 'Mepɛ sɛ metɔ yi', 'cat': 'business'},
    {'en': 'Where is the airport?', 'fr': 'Où est l\'aéroport?', 'tw': 'Wiemhyen dan no wɔ he?', 'cat': 'travel'},
    {'en': 'I need a taxi', 'fr': 'J\'ai besoin d\'un taxi', 'tw': 'Mehia taksi', 'cat': 'travel'},
    {'en': 'I would like to eat', 'fr': 'Je voudrais manger', 'tw': 'Mepɛ sɛ mididi', 'cat': 'food'},
    {'en': 'The food is delicious', 'fr': 'La nourriture est délicieuse', 'tw': 'Aduane no yɛ dɛ', 'cat': 'food'},
    {'en': 'Water please', 'fr': 'De l\'eau s\'il vous plaît', 'tw': 'Nsuo, mesrɛ wo', 'cat': 'food'},
  ];

  @override
  void initState() {
    super.initState();
    _load();
    _player.playerStateStream.listen((state) {
      if (!state.playing && mounted) setState(() => _playingKey = null);
    });
  }

  @override
  void dispose() { _searchCtrl.dispose(); _player.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final phrases = await DatabaseService.getPhrases(
      category: _category == 'all' ? null : _category,
      query: _search.isEmpty ? null : _search,
    );
    setState(() { _phrases = phrases; _loading = false; });
  }

  Future<void> _playPhrase(String text, String targetLang, String key) async {
    if (_playingKey == key) {
      await _player.stop();
      setState(() => _playingKey = null);
      return;
    }
    await _player.stop();
    setState(() { _loadingKey = key; _isLoadingAudio = true; _playingKey = null; });
    try {
      final cached = await DatabaseService.getCached(text, targetLang);
      String? audioUrl = cached?['audio_path'];
      if (audioUrl == null) {
        if (!TranslationService.isOnline) {
          _showSnack('No internet. Audio not available offline.');
          setState(() { _loadingKey = null; _isLoadingAudio = false; });
          return;
        }
        final result = await TranslationService.translateText(text: text, targetLanguage: targetLang);
        audioUrl = result['audio_url'];
        if (audioUrl != null) {
          await DatabaseService.cacheTranslation(text, result['translated_text'] ?? '', targetLang, audioPath: audioUrl);
        }
      }
      if (audioUrl == null) {
        _showSnack('Audio not available for this phrase');
        setState(() { _loadingKey = null; _isLoadingAudio = false; });
        return;
      }
      await _player.setUrl(audioUrl);
      await _player.play();
      setState(() { _playingKey = key; _loadingKey = null; _isLoadingAudio = false; });
    } catch (e) {
      _showSnack('Could not play audio');
      setState(() { _loadingKey = null; _isLoadingAudio = false; });
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg), behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _showAddPhraseDialog() {
    final textCtrl = TextEditingController();
    Language selectedLang = _selectedLang;
    bool isTranslating = false;
    String? translatedText;
    String? audioUrl;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final bgColor = isDark ? AppColors.cardDark : AppColors.cardLight;
          final txColor = isDark ? AppColors.txDark : AppColors.txLight;
          final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

          Future<void> translate() async {
            final text = textCtrl.text.trim();
            if (text.isEmpty) return;
            setModalState(() { isTranslating = true; translatedText = null; audioUrl = null; });
            final result = await TranslationService.translateText(text: text, targetLanguage: selectedLang.apiCode);
            setModalState(() { isTranslating = false; translatedText = result['translated_text']; audioUrl = result['audio_url']; });
          }

          Future<void> save() async {
            final text = textCtrl.text.trim();
            if (text.isEmpty || translatedText == null) return;
            await DatabaseService.savePhrase({
              'source_text': text,
              'translated_text': translatedText,
              'target_language': selectedLang.apiCode,
              'category': 'saved',
              'audio_path': audioUrl,
              'created_at': DateTime.now().toIso8601String(),
            });
            if (audioUrl != null) {
              await DatabaseService.cacheTranslation(text, translatedText!, selectedLang.apiCode, audioPath: audioUrl);
            }
            Navigator.pop(context);
            _load();
            _showSnack('Phrase saved!');
          }

          return Container(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            decoration: BoxDecoration(color: bgColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: borderColor, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                Text('Add Phrase', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: txColor, fontFamily: 'Outfit')),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(color: isDark ? AppColors.card2Dark : AppColors.card2Light, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor)),
                  child: TextField(
                    controller: textCtrl,
                    style: TextStyle(fontSize: 14, color: txColor, fontFamily: 'Outfit'),
                    decoration: InputDecoration(border: InputBorder.none, hintText: 'Enter English phrase...', hintStyle: TextStyle(color: isDark ? AppColors.tx3Dark : AppColors.tx3Light, fontSize: 14), isDense: true, contentPadding: const EdgeInsets.symmetric(vertical: 12)),
                    maxLines: 2,
                    onChanged: (_) => setModalState(() { translatedText = null; audioUrl = null; }),
                  ),
                ),
                const SizedBox(height: 12),
                Text('Translate to:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? AppColors.tx2Dark : AppColors.tx2Light, fontFamily: 'Outfit')),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 6, children: allLanguages.map((lang) {
                  final isSelected = selectedLang.code == lang.code;
                  return GestureDetector(
                    onTap: () => setModalState(() { selectedLang = lang; translatedText = null; audioUrl = null; }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? lang.color.withOpacity(0.15) : (isDark ? AppColors.card2Dark : AppColors.card2Light),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isSelected ? lang.color : borderColor),
                      ),
                      child: Text('${lang.flag} ${lang.name}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isSelected ? lang.color : (isDark ? AppColors.tx2Dark : AppColors.tx2Light), fontFamily: 'Outfit')),
                    ),
                  );
                }).toList()),
                const SizedBox(height: 16),
                if (translatedText != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: selectedLang.color.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: selectedLang.color.withOpacity(0.2))),
                    child: Row(children: [
                      Text(selectedLang.flag, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 10),
                      Expanded(child: Text(translatedText!, style: TextStyle(fontSize: 14, color: selectedLang.color, fontStyle: FontStyle.italic, fontFamily: 'Outfit'))),
                      if (audioUrl != null)
                        GestureDetector(
                          onTap: () async { try { await _player.stop(); await _player.setUrl(audioUrl!); await _player.play(); } catch (_) {} },
                          child: Container(width: 36, height: 36, decoration: BoxDecoration(gradient: LinearGradient(colors: [selectedLang.color, selectedLang.color.withOpacity(0.7)]), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.volume_up_rounded, color: Colors.white, size: 18)),
                        ),
                    ]),
                  ),
                  const SizedBox(height: 12),
                ],
                Row(children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: isTranslating ? null : translate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.primary.withOpacity(0.3))),
                        child: Center(child: isTranslating
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2))
                            : const Text('Translate', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary, fontFamily: 'Outfit'))),
                      ),
                    ),
                  ),
                  if (translatedText != null) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: save,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.primary, AppColors.secondary]), borderRadius: BorderRadius.circular(12)),
                          child: const Center(child: Text('Save', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Outfit'))),
                        ),
                      ),
                    ),
                  ],
                ]),
                const SizedBox(height: 8),
              ]),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final txColor = isDark ? AppColors.txDark : AppColors.txLight;
    final bgColor = isDark ? AppColors.bgDark : AppColors.bgLight;

    final builtIn = _builtIn.where((p) {
      final matchCat = _category == 'all' || _category == 'saved' || p['cat'] == _category;
      final matchSearch = _search.isEmpty || p['en']!.toLowerCase().contains(_search.toLowerCase());
      return matchCat && matchSearch;
    }).toList();

    return Scaffold(
      backgroundColor: bgColor,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddPhraseDialog,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Phrase', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600)),
      ),
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 56, 20, 8),
          child: Row(children: [
            Text('Phrasebook', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: txColor, fontFamily: 'Outfit')),
            const Spacer(),
            if (_phrases.isNotEmpty)
              GestureDetector(
                onTap: () => ExportService.exportPhrases(_phrases),
                child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: const Row(children: [Icon(Icons.download_rounded, size: 14, color: AppColors.primary), SizedBox(width: 4), Text('Export', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary))])),
              ),
          ]),
        )),

        // Search
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(color: isDark ? AppColors.cardDark : AppColors.cardLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
            child: Row(children: [
              Icon(Icons.search_rounded, size: 18, color: isDark ? AppColors.tx3Dark : AppColors.tx3Light),
              const SizedBox(width: 8),
              Expanded(child: TextField(
                controller: _searchCtrl,
                style: TextStyle(fontSize: 14, color: txColor, fontFamily: 'Outfit'),
                decoration: InputDecoration(border: InputBorder.none, hintText: 'Search phrases...', hintStyle: TextStyle(color: isDark ? AppColors.tx3Dark : AppColors.tx3Light, fontSize: 14), isDense: true, contentPadding: const EdgeInsets.symmetric(vertical: 12)),
                onChanged: (v) { setState(() => _search = v); _load(); },
              )),
              if (_search.isNotEmpty) GestureDetector(onTap: () { _searchCtrl.clear(); setState(() => _search = ''); _load(); }, child: Icon(Icons.close_rounded, size: 16, color: isDark ? AppColors.tx3Dark : AppColors.tx3Light)),
            ]),
          ),
        )),

        // Audio Language Selector
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('🔊 Play audio in:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? AppColors.tx2Dark : AppColors.tx2Light, fontFamily: 'Outfit')),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: allLanguages.map((lang) {
                final isSelected = _selectedLang.code == lang.code;
                return GestureDetector(
                  onTap: () {
                    setState(() { _selectedLang = lang; _playingKey = null; });
                    _player.stop();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? lang.color.withOpacity(0.15) : (isDark ? AppColors.cardDark : AppColors.cardLight),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isSelected ? lang.color : (isDark ? AppColors.borderDark : AppColors.borderLight)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(lang.flag, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text(lang.name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isSelected ? lang.color : (isDark ? AppColors.tx2Dark : AppColors.tx2Light), fontFamily: 'Outfit')),
                      if (isSelected) ...[const SizedBox(width: 4), Icon(Icons.volume_up_rounded, size: 12, color: lang.color)],
                    ]),
                  ),
                );
              }).toList()),
            ),
          ]),
        )),

        // Categories
        SliverToBoxAdapter(child: SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _catChip('all', '🗂️ All', isDark),
              ...phraseCategories.map((c) => _catChip(c['id'] as String, '${c['icon']} ${c['label']}', isDark)),
            ],
          ),
        )),

        // Status bar
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: TranslationService.isOnline ? AppColors.successLight : AppColors.warningLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: TranslationService.isOnline ? AppColors.success.withOpacity(0.3) : AppColors.warning.withOpacity(0.3)),
            ),
            child: Row(children: [
              Icon(TranslationService.isOnline ? Icons.volume_up_rounded : Icons.offline_bolt_rounded, size: 14, color: TranslationService.isOnline ? AppColors.success : AppColors.warning),
              const SizedBox(width: 8),
              Expanded(child: Text(
                TranslationService.isOnline
                    ? 'Tap 🔊 to hear in ${_selectedLang.name} | Tap + to add phrases'
                    : 'Offline: only cached phrases have audio',
                style: TextStyle(fontSize: 11, color: TranslationService.isOnline ? AppColors.success : AppColors.warning, fontFamily: 'Outfit', fontWeight: FontWeight.w600),
              )),
            ]),
          ),
        )),

        // Built-in phrases
        if (_category != 'saved' && builtIn.isNotEmpty) ...[
          SliverToBoxAdapter(child: SectionTitle('Common Phrases')),
          SliverList(delegate: SliverChildBuilderDelegate(
            (context, i) => _builtInCard(builtIn[i], isDark, txColor),
            childCount: builtIn.length,
          )),
        ],

        // Saved phrases
        if (_phrases.isNotEmpty) ...[
          SliverToBoxAdapter(child: SectionTitle('My Phrases')),
          SliverList(delegate: SliverChildBuilderDelegate(
            (context, i) => _savedCard(_phrases[i], isDark, txColor),
            childCount: _phrases.length,
          )),
        ],

        if (_phrases.isEmpty && builtIn.isEmpty)
          SliverFillRemaining(child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(width: 80, height: 80, decoration: BoxDecoration(color: AppColors.secondary.withOpacity(0.1), borderRadius: BorderRadius.circular(20)), child: const Icon(Icons.bookmark_rounded, size: 40, color: AppColors.secondary)),
            const SizedBox(height: 16),
            Text('No phrases found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: txColor, fontFamily: 'Outfit')),
            const SizedBox(height: 8),
            Text('Tap + to add your own phrases', style: TextStyle(fontSize: 13, color: isDark ? AppColors.tx3Dark : AppColors.tx3Light, fontFamily: 'Outfit')),
          ]))),

        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ]),
    );
  }

  Widget _builtInCard(Map<String, dynamic> p, bool isDark, Color txColor) {
    // Get translation for selected language (fallback to English if not available)
    String translation;
    if (_selectedLang.apiCode == 'fr') {
      translation = p['fr'] ?? p['en']!;
    } else if (_selectedLang.apiCode == 'tw') {
      translation = p['tw'] ?? p['en']!;
    } else {
      translation = p['en']!; // For other languages, will translate on demand
    }
    final audioKey = 'builtin_${_selectedLang.apiCode}_${p['en']}';

    return GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 3, height: 14, decoration: BoxDecoration(color: AppColors.english, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Expanded(child: Text(p['en']!, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: txColor, fontFamily: 'Outfit'))),
        CopyButton(text: '${p['en']}\n$translation'),
      ]),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: _selectedLang.color.withOpacity(0.06), borderRadius: BorderRadius.circular(10), border: Border.all(color: _selectedLang.color.withOpacity(0.15))),
        child: Row(children: [
          Text(_selectedLang.flag, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(child: Text(translation, style: TextStyle(fontSize: 13, color: _selectedLang.color, fontStyle: FontStyle.italic, fontFamily: 'Outfit'))),
          _audioButton(p['en']!, _selectedLang.apiCode, audioKey),
        ]),
      ),
    ]));
  }

  Widget _savedCard(Map<String, dynamic> phrase, bool isDark, Color txColor) {
    final lang = allLanguages.firstWhere((l) => l.apiCode == phrase['target_language'], orElse: () => langFrench);
    final audioKey = 'saved_${phrase['id']}';
    return Dismissible(
      key: Key(phrase['id'].toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(color: AppColors.errorLight, borderRadius: BorderRadius.circular(16)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_rounded, color: AppColors.error),
      ),
      onDismissed: (_) async { await DatabaseService.deletePhrase(phrase['id']); _load(); },
      child: GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('${langEnglish.flag} → ${lang.flag} ${lang.name}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: lang.color)),
          const Spacer(),
          CopyButton(text: '${phrase['source_text']}\n${phrase['translated_text']}'),
        ]),
        const SizedBox(height: 10),
        Text(phrase['source_text'], style: TextStyle(fontSize: 14, color: txColor, fontWeight: FontWeight.w600, fontFamily: 'Outfit')),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: lang.color.withOpacity(0.06), borderRadius: BorderRadius.circular(10), border: Border.all(color: lang.color.withOpacity(0.15))),
          child: Row(children: [
            Text(lang.flag, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 10),
            Expanded(child: Text(phrase['translated_text'], style: TextStyle(fontSize: 13, color: lang.color, fontStyle: FontStyle.italic, fontFamily: 'Outfit'))),
            _audioButton(phrase['source_text'], phrase['target_language'], audioKey),
          ]),
        ),
      ])),
    );
  }

  Widget _audioButton(String text, String targetLang, String key) {
    final isThisPlaying = _playingKey == key;
    final isThisLoading = _loadingKey == key;
    return GestureDetector(
      onTap: () => _playPhrase(text, targetLang, key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 36, height: 36,
        decoration: BoxDecoration(
          gradient: isThisPlaying
              ? const LinearGradient(colors: [AppColors.error, Color(0xFFFF6B6B)])
              : const LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: (isThisPlaying ? AppColors.error : AppColors.primary).withOpacity(0.35), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Center(
          child: isThisLoading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Icon(isThisPlaying ? Icons.stop_rounded : Icons.volume_up_rounded, color: Colors.white, size: 18),
        ),
      ),
    );
  }

  Widget _catChip(String id, String label, bool isDark) {
    final active = _category == id;
    return GestureDetector(
      onTap: () { setState(() => _category = id); _load(); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 8, top: 4, bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : (isDark ? AppColors.cardDark : AppColors.cardLight),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? AppColors.primary : (isDark ? AppColors.borderDark : AppColors.borderLight)),
        ),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: active ? Colors.white : (isDark ? AppColors.tx2Dark : AppColors.tx2Light), fontFamily: 'Outfit')),
      ),
    );
  }
}
