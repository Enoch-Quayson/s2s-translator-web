import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import '../models/translation_record.dart';

// Web-compatible export service using browser download
class ExportService {
  static Future<void> exportToCSV(List<TranslationRecord> records) async {
    final rows = [
      ['Date', 'Source', 'Translation', 'Language', 'Mode', 'Duration(ms)'],
      ...records.map((r) => [
        r.createdAt.toIso8601String(), r.sourceText, r.translatedText,
        r.targetLanguage, r.inputMode, r.durationMs?.toString() ?? '',
      ]),
    ];
    final csv = rows.map((row) => row.map(_escape).join(',')).join('\n');
    _downloadFile(csv, 's2s_history_${DateTime.now().millisecondsSinceEpoch}.csv', 'text/csv');
  }

  static Future<void> exportPhrases(List<Map<String, dynamic>> phrases) async {
    final rows = [
      ['English', 'Translation', 'Language', 'Category', 'Date'],
      ...phrases.map((p) => [
        p['source_text'] ?? '', p['translated_text'] ?? '',
        p['target_language'] ?? '', p['category'] ?? '', p['created_at'] ?? '',
      ]),
    ];
    final csv = rows.map((row) => row.map(_escape).join(',')).join('\n');
    _downloadFile(csv, 's2s_phrasebook_${DateTime.now().millisecondsSinceEpoch}.csv', 'text/csv');
  }

  static String _escape(dynamic value) {
    final s = value.toString();
    if (s.contains(',') || s.contains('"') || s.contains('\n')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }

  static void _downloadFile(String content, String filename, String mimeType) {
    final bytes = utf8.encode(content);
    final blob = html.Blob([bytes], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..click();
    html.Url.revokeObjectUrl(url);
  }
}