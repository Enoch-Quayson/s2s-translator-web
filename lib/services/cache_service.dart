import 'dart:convert';
import 'package:flutter/services.dart';

class CacheService {
  static Map<String, Map<String, String>> _cache = {};
  static bool _loaded = false;

  static Future<void> load() async {
    if (_loaded) return;
    try {
      final jsonStr = await rootBundle.loadString('assets/app_cache.json');
      final raw = jsonDecode(jsonStr) as Map<String, dynamic>;
      _cache = raw.map((key, value) =>
        MapEntry(key, (value as Map<String, dynamic>).map((k, v) => MapEntry(k, v.toString())))
      );
      _loaded = true;
      print('CacheService: loaded ${_cache.length} phrases');
    } catch (e) {
      print('CacheService: failed to load cache - $e');
    }
  }

  /// Look up a translation from cache.
  /// Returns null if not found.
  static String? get(String sourceText, String targetLanguage) {
    if (!_loaded) return null;
    // Try exact match
    final entry = _cache[sourceText];
    if (entry != null) {
      return entry[targetLanguage];
    }
    // Try case-insensitive match
    final lower = sourceText.toLowerCase().trim();
    for (final key in _cache.keys) {
      if (key.toLowerCase().trim() == lower) {
        return _cache[key]?[targetLanguage];
      }
    }
    return null;
  }

  static bool get isLoaded => _loaded;
  static int get size => _cache.length;

  /// Get all cached phrases for a language (for phrasebook)
  static List<Map<String, dynamic>> getAllPhrases(String targetLanguage) {
    return _cache.entries
      .where((e) => e.value.containsKey(targetLanguage))
      .map((e) => {
        'source_text': e.key,
        'translated_text': e.value[targetLanguage] ?? '',
        'target_language': targetLanguage,
      })
      .toList();
  }
}
