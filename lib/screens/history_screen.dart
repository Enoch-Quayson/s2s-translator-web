import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../services/database_service.dart';
import '../services/export_service.dart';
import '../models/translation_record.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  List<TranslationRecord> _records = [];
  bool _loading = true;
  bool _starsOnly = false;
  String _search = '';
  final _searchCtrl = TextEditingController();
  late TabController _tabCtrl;

  @override
  void initState() { super.initState(); _tabCtrl = TabController(length: 2, vsync: this); _load(); }

  @override
  void dispose() { _tabCtrl.dispose(); _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final records = await DatabaseService.getHistory(query: _search.isEmpty ? null : _search, starsOnly: _starsOnly);
    setState(() { _records = records; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final txColor = isDark ? AppColors.txDark : AppColors.txLight;
    final bgColor = isDark ? AppColors.bgDark : AppColors.bgLight;

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 8),
            child: Row(children: [
              Text('History', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: txColor, fontFamily: 'Outfit')),
              const Spacer(),
              if (_records.isNotEmpty) ...[
                GestureDetector(
                  onTap: () => ExportService.exportToCSV(_records),
                  child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: const Row(children: [Icon(Icons.download_rounded, size: 14, color: AppColors.primary), SizedBox(width: 4), Text('Export', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary))])),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () async { await DatabaseService.clearHistory(); _load(); },
                  child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: AppColors.errorLight, borderRadius: BorderRadius.circular(8)), child: const Text('Clear', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.error))),
                ),
              ],
            ]),
          )),
          // Search bar
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
                  decoration: InputDecoration(border: InputBorder.none, hintText: 'Search translations...', hintStyle: TextStyle(color: isDark ? AppColors.tx3Dark : AppColors.tx3Light, fontSize: 14), isDense: true, contentPadding: const EdgeInsets.symmetric(vertical: 12)),
                  onChanged: (v) { setState(() => _search = v); _load(); },
                )),
                if (_search.isNotEmpty) GestureDetector(onTap: () { _searchCtrl.clear(); setState(() => _search = ''); _load(); }, child: Icon(Icons.close_rounded, size: 16, color: isDark ? AppColors.tx3Dark : AppColors.tx3Light)),
              ]),
            ),
          )),
          // Filter chips
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(children: [
              _filterChip('All', !_starsOnly, () { setState(() => _starsOnly = false); _load(); }, isDark),
              const SizedBox(width: 8),
              _filterChip('⭐ Starred', _starsOnly, () { setState(() => _starsOnly = true); _load(); }, isDark),
            ]),
          )),
          if (_loading)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppColors.primary)))
          else if (_records.isEmpty)
            SliverFillRemaining(child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(width: 80, height: 80, decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(20)), child: const Icon(Icons.history_rounded, size: 40, color: AppColors.primary)),
              const SizedBox(height: 16),
              Text(_search.isNotEmpty ? 'No results found' : 'No translations yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: txColor, fontFamily: 'Outfit')),
            ])))
          else
            SliverList(delegate: SliverChildBuilderDelegate((context, i) {
              final r = _records[i];
              final lang = allLanguages.firstWhere((l) => l.apiCode == r.targetLanguage, orElse: () => langFrench);
              final modeIcon = r.inputMode == 'text' ? Icons.text_fields_rounded : r.inputMode == 'audio' ? Icons.mic_rounded : Icons.audio_file_rounded;
              return Dismissible(
                key: Key(r.id.toString()),
                direction: DismissDirection.endToStart,
                background: Container(margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), decoration: BoxDecoration(color: AppColors.errorLight, borderRadius: BorderRadius.circular(16)), alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete_rounded, color: AppColors.error)),
                onDismissed: (_) async { await DatabaseService.deleteTranslation(r.id!); _load(); },
                child: GlassCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(padding: const EdgeInsets.all(5), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(7)), child: Icon(modeIcon, size: 13, color: AppColors.primary)),
                      const SizedBox(width: 8),
                      Text('EN → ${lang.name}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: lang.color)),
                      if (r.durationMs != null) ...[const SizedBox(width: 8), Text('${(r.durationMs! / 1000).toStringAsFixed(1)}s', style: TextStyle(fontSize: 11, color: isDark ? AppColors.tx3Dark : AppColors.tx3Light, fontFamily: 'Outfit'))],
                      const Spacer(),
                      GestureDetector(
                        onTap: () async { await DatabaseService.toggleStar(r.id!, !r.isStarred); _load(); },
                        child: Icon(r.isStarred ? Icons.star_rounded : Icons.star_border_rounded, size: 18, color: r.isStarred ? AppColors.warning : (isDark ? AppColors.tx3Dark : AppColors.tx3Light)),
                      ),
                      const SizedBox(width: 8),
                      Text(DateFormat('MMM d, h:mm a').format(r.createdAt), style: TextStyle(fontSize: 10, color: isDark ? AppColors.tx3Dark : AppColors.tx3Light, fontFamily: 'Outfit')),
                    ]),
                    const SizedBox(height: 10),
                    Text(r.sourceText, style: TextStyle(fontSize: 14, color: txColor, fontFamily: 'Outfit'), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 5),
                    Text(r.translatedText, style: TextStyle(fontSize: 13, color: lang.color, fontStyle: FontStyle.italic, fontFamily: 'Outfit'), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ]),
                ),
              );
            }, childCount: _records.length)),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool active, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
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
