import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  final Language targetLang;
  final ValueChanged<Language> onTargetLangChanged;
  final VoidCallback onTranslateTap;

  const HomeScreen({
    super.key,
    required this.targetLang,
    required this.onTargetLangChanged,
    required this.onTranslateTap,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _stats;
  List<dynamic> _recent = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final stats = await ApiService.getStats();
      final history = await ApiService.getHistory(limit: 5);
      if (mounted) setState(() { _stats = stats; _recent = history; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showLanguagePicker(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: isDark ? AppColors.borderDark : AppColors.borderLight, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Text('Select Target Language', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? AppColors.txDark : AppColors.txLight, fontFamily: 'Outfit')),
          const SizedBox(height: 16),
          ...allLanguages.map((lang) {
            final isSelected = widget.targetLang.apiCode == lang.apiCode;
            return GestureDetector(
              onTap: () { widget.onTargetLangChanged(lang); Navigator.pop(context); },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected ? lang.color.withOpacity(0.12) : (isDark ? AppColors.card2Dark : AppColors.card2Light),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isSelected ? lang.color : (isDark ? AppColors.borderDark : AppColors.borderLight)),
                ),
                child: Row(children: [
                  Text(lang.flag, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 12),
                  Expanded(child: Text(lang.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isSelected ? lang.color : (isDark ? AppColors.txDark : AppColors.txLight), fontFamily: 'Outfit'))),
                  if (isSelected) Icon(Icons.check_circle_rounded, color: lang.color, size: 20),
                ]),
              ),
            );
          }),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;
    final txColor = isDark ? AppColors.txDark : AppColors.txLight;
    final tx2Color = isDark ? AppColors.tx2Dark : AppColors.tx2Light;
    final tx3Color = isDark ? AppColors.tx3Dark : AppColors.tx3Light;
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final card2Color = isDark ? AppColors.card2Dark : AppColors.card2Light;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return RefreshIndicator(
      onRefresh: _load,
      color: accent,
      child: ListView(children: [
        // Greeting
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Welcome back 👋', style: TextStyle(fontSize: 12, color: tx3Color)),
            const SizedBox(height: 4),
            RichText(text: TextSpan(
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: txColor, letterSpacing: -0.5, fontFamily: 'Outfit'),
              children: [
                const TextSpan(text: 'Translate to '),
                TextSpan(text: widget.targetLang.name, style: TextStyle(color: widget.targetLang.color)),
              ],
            )),
          ]),
        ),

        // Language Strip with Dropdown
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor)),
            child: Row(children: [
              // English side
              Row(children: [
                Text(langEnglish.flag, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('English', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: txColor)),
                  Text('Source', style: TextStyle(fontSize: 10, color: tx3Color, fontFamily: 'DM Mono')),
                ]),
              ]),
              Expanded(child: Column(children: [
                Icon(Icons.arrow_forward_rounded, size: 14, color: tx3Color),
                Container(height: 1, color: borderColor, margin: const EdgeInsets.symmetric(horizontal: 8)),
              ])),
              // Target language dropdown
              GestureDetector(
                onTap: () => _showLanguagePicker(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: widget.targetLang.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: widget.targetLang.color.withOpacity(0.4)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(widget.targetLang.flag, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 6),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(widget.targetLang.name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: widget.targetLang.color, fontFamily: 'Outfit')),
                      Text('tap to change', style: TextStyle(fontSize: 9, color: widget.targetLang.color.withOpacity(0.7), fontFamily: 'DM Mono')),
                    ]),
                    const SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: widget.targetLang.color),
                  ]),
                ),
              ),
            ]),
          ),
        ),

        // Translate CTA button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: GestureDetector(
            onTap: widget.onTranslateTap,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [accent, AppColors.secondary]),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: accent.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.translate_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text('Start Translating to ${widget.targetLang.name}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Outfit')),
              ]),
            ),
          ),
        ),

        // Stats
        const SectionTitle('Overview'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            _statBox(_loading ? '—' : '${_stats?['total_translations'] ?? 0}', 'Translations', accent, cardColor, borderColor, tx2Color),
            const SizedBox(width: 8),
            _statBox(_loading ? '—' : '${_stats?['accuracy_rate'] ?? 0}%', 'Accuracy', AppColors.success, cardColor, borderColor, tx2Color),
            const SizedBox(width: 8),
            _statBox(_loading ? '—' : '${_stats?['total_audio_seconds'] ?? 0}s', 'Audio', AppColors.warning, cardColor, borderColor, tx2Color),
          ]),
        ),

        // Quick Actions
        const SectionTitle('Input Modes'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 1.6,
            children: [
              _actionCard('🎙️', 'Microphone', 'Record speech for real-time translation', widget.onTranslateTap, cardColor, borderColor, txColor, tx2Color),
              _actionCard('✅', 'Type Text', 'Enter text to translate manually', widget.onTranslateTap, cardColor, borderColor, txColor, tx2Color),
              _actionCard('📄', 'Upload File', 'Audio, text, or document files', widget.onTranslateTap, cardColor, borderColor, txColor, tx2Color),
              _actionCard('🤝', 'Conversation', 'Two-speaker live dialogue mode', widget.onTranslateTap, cardColor, borderColor, txColor, tx2Color),
            ],
          ),
        ),

        // Recent
        const SectionTitle('Recent'),
        if (_loading)
          Padding(padding: const EdgeInsets.all(24), child: Center(child: CircularProgressIndicator(color: accent)))
        else if (_recent.isEmpty)
          Padding(padding: const EdgeInsets.all(24), child: Center(child: Text('No translations yet', style: TextStyle(color: tx3Color, fontSize: 13))))
        else
          ..._recent.map((item) => _recentItem(item, txColor, tx2Color, tx3Color, card2Color, borderColor)),

        const SizedBox(height: 16),
      ]),
    );
  }

  Widget _statBox(String value, String label, Color color, Color cardColor, Color borderColor, Color tx2Color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(10), border: Border.all(color: borderColor)),
        child: Column(children: [
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color, fontFamily: 'DM Mono', letterSpacing: -0.5)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, color: tx2Color, fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }

  Widget _actionCard(String icon, String title, String desc, VoidCallback onTap, Color cardColor, Color borderColor, Color txColor, Color tx2Color) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(10), border: Border.all(color: borderColor)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 6),
          Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: txColor)),
          const SizedBox(height: 2),
          Text(desc, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, color: tx2Color, height: 1.3)),
        ]),
      ),
    );
  }

  Widget _recentItem(Map<String, dynamic> item, Color txColor, Color tx2Color, Color tx3Color, Color card2Color, Color borderColor) {
    final inputType = item['input_type'] ?? 'text';
    final icon = inputType == 'audio' ? '🎙️' : inputType == 'file' ? '📄' : '✅';
    final time = item['created_at'] != null
        ? TimeOfDay.fromDateTime(DateTime.parse(item['created_at'])).format(context)
        : '';
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          Container(width: 28, height: 28, decoration: BoxDecoration(color: card2Color, borderRadius: BorderRadius.circular(7), border: Border.all(color: borderColor)), child: Center(child: Text(icon, style: const TextStyle(fontSize: 13)))),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item['source_text'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: txColor)),
            const SizedBox(height: 1),
            Text(item['translated_text'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: tx2Color, fontStyle: FontStyle.italic)),
          ])),
          const SizedBox(width: 8),
          Text(time, style: TextStyle(fontSize: 10, color: tx3Color, fontFamily: 'DM Mono')),
        ]),
      ),
    );
  }
}
