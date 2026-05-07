import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/translation_record.dart';

// Web-compatible database service using SharedPreferences
class DatabaseService {
  static const _translationsKey = 'translations';
  static const _phrasebookKey = 'phrasebook';
  static const _cacheKey = 'cached_translations';
  static int _nextId = 1;

  static Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  static Future<List<Map<String, dynamic>>> _getList(String key) async {
    final prefs = await _prefs;
    final raw = prefs.getString(key);
    if (raw == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(raw));
  }

  static Future<void> _saveList(String key, List<Map<String, dynamic>> list) async {
    final prefs = await _prefs;
    await prefs.setString(key, jsonEncode(list));
  }

  // ── Translations ──────────────────────────────────────────
  static Future<int> saveTranslation(TranslationRecord r) async {
    final list = await _getList(_translationsKey);
    final id = DateTime.now().millisecondsSinceEpoch;
    final map = r.toMap();
    map['id'] = id;
    list.insert(0, map);
    // Keep only last 200
    if (list.length > 200) list.removeRange(200, list.length);
    await _saveList(_translationsKey, list);
    return id;
  }

  static Future<List<TranslationRecord>> getHistory({
    int limit = 100, int offset = 0,
    String? query, bool starsOnly = false,
  }) async {
    var list = await _getList(_translationsKey);
    if (query != null && query.isNotEmpty) {
      final q = query.toLowerCase();
      list = list.where((r) =>
        (r['source_text'] ?? '').toLowerCase().contains(q) ||
        (r['translated_text'] ?? '').toLowerCase().contains(q)
      ).toList();
    }
    if (starsOnly) list = list.where((r) => r['is_starred'] == 1).toList();
    list = list.skip(offset).take(limit).toList();
    return list.map(TranslationRecord.fromMap).toList();
  }

  static Future<void> toggleStar(int id, bool isStarred) async {
    final list = await _getList(_translationsKey);
    for (final r in list) {
      if (r['id'] == id) { r['is_starred'] = isStarred ? 1 : 0; break; }
    }
    await _saveList(_translationsKey, list);
  }

  static Future<void> deleteTranslation(int id) async {
    final list = await _getList(_translationsKey);
    list.removeWhere((r) => r['id'] == id);
    await _saveList(_translationsKey, list);
  }

  static Future<void> clearHistory() async {
    await _saveList(_translationsKey, []);
  }

  static Future<Map<String, dynamic>> getStats() async {
    final list = await _getList(_translationsKey);
    return {
      'total': list.length,
      'french': list.where((r) => r['target_language'] == 'fr').length,
      'twi': list.where((r) => r['target_language'] == 'tw').length,
      'starred': list.where((r) => r['is_starred'] == 1).length,
      'voice': list.where((r) => r['input_mode'] == 'audio').length,
      'text': list.where((r) => r['input_mode'] == 'text').length,
    };
  }

  // ── Phrasebook ────────────────────────────────────────────
  static Future<int> savePhrase(Map<String, dynamic> phrase) async {
    final list = await _getList(_phrasebookKey);
    final id = DateTime.now().millisecondsSinceEpoch;
    phrase['id'] = id;
    list.insert(0, phrase);
    await _saveList(_phrasebookKey, list);
    return id;
  }

  static Future<List<Map<String, dynamic>>> getPhrases({
    String? category, String? query,
  }) async {
    var list = await _getList(_phrasebookKey);
    if (category != null && category != 'all') {
      list = list.where((p) => p['category'] == category).toList();
    }
    if (query != null && query.isNotEmpty) {
      final q = query.toLowerCase();
      list = list.where((p) =>
        (p['source_text'] ?? '').toLowerCase().contains(q) ||
        (p['translated_text'] ?? '').toLowerCase().contains(q)
      ).toList();
    }
    return list;
  }

  static Future<void> deletePhrase(int id) async {
    final list = await _getList(_phrasebookKey);
    list.removeWhere((p) => p['id'] == id);
    await _saveList(_phrasebookKey, list);
  }

  // ── Cache ─────────────────────────────────────────────────
  static Future<Map<String, dynamic>?> getCached(String text, String lang) async {
    final list = await _getList(_cacheKey);
    try {
      return list.firstWhere((c) => c['source_text'] == text && c['target_language'] == lang);
    } catch (_) { return null; }
  }

  static Future<void> cacheTranslation(
    String sourceText, String translatedText, String lang, {String? audioPath}
  ) async {
    final list = await _getList(_cacheKey);
    list.removeWhere((c) => c['source_text'] == sourceText && c['target_language'] == lang);
    list.insert(0, {
      'id': DateTime.now().millisecondsSinceEpoch,
      'source_text': sourceText,
      'translated_text': translatedText,
      'target_language': lang,
      'audio_path': audioPath,
      'created_at': DateTime.now().toIso8601String(),
    });
    if (list.length > 500) list.removeRange(500, list.length);
    await _saveList(_cacheKey, list);
  }

  static Future<List<Map<String, dynamic>>> getAllCached() async {
    return _getList(_cacheKey);
  }
}