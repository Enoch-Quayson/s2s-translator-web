import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'database_service.dart';

class TranslationService {
  static const String _hfUrl = 'https://enochquayson-s2s-translator.hf.space';
  static bool _isOnline = false;
  static bool get isOnline => _isOnline;

  static Future<bool> checkConnectivity() async {
    try {
      final result = await Connectivity().checkConnectivity();
      if (result.contains(ConnectivityResult.none)) { _isOnline = false; return false; }
      final res = await http.get(Uri.parse('$_hfUrl/')).timeout(const Duration(seconds: 5));
      _isOnline = res.statusCode < 500;
    } catch (_) { _isOnline = false; }
    return _isOnline;
  }

  static String? _extractAudioUrl(dynamic rawAudio) {
    if (rawAudio == null) return null;
    if (rawAudio is Map && rawAudio['url'] != null) return rawAudio['url'];
    if (rawAudio is String && rawAudio.startsWith('http')) return rawAudio;
    if (rawAudio is String && rawAudio.isNotEmpty) return '$_hfUrl/gradio_api/file=$rawAudio';
    return null;
  }

  static Future<List<dynamic>> _pollResult(String endpoint, String eventId) async {
    final uri = Uri.parse('$_hfUrl/gradio_api/call/$endpoint/$eventId');
    for (int i = 0; i < 150; i++) {
      await Future.delayed(const Duration(seconds: 2));
      try {
        final res = await http.get(uri).timeout(const Duration(seconds: 10));
        final lines = res.body.split('\n');
        String? lastEvent;
        for (final line in lines) {
          if (line.startsWith('event: ')) { lastEvent = line.substring(7).trim(); }
          else if (line.startsWith('data: ') && lastEvent != null) {
            final dataStr = line.substring(6).trim();
            if (lastEvent == 'heartbeat' || dataStr == 'null' || dataStr.isEmpty) { lastEvent = null; continue; }
            try {
              final result = jsonDecode(dataStr);
              if (result is List && result.isNotEmpty) return result;
            } catch (_) {}
            lastEvent = null;
          }
        }
      } catch (_) {}
    }
    return [];
  }

  static Future<Map<String, dynamic>> translateText({
    required String text,
    required String targetLanguage,
    bool useCache = true,
  }) async {
    if (useCache) {
      final cached = await DatabaseService.getCached(text, targetLanguage);
      if (cached != null) {
        return {'translated_text': cached['translated_text'], 'audio_url': cached['audio_path'], 'from_cache': true};
      }
    }

    if (!_isOnline) return {'translated_text': 'No internet connection. Cache not available for this text.', 'audio_url': null, 'error': true};

    final stopwatch = Stopwatch()..start();
    try {
      final res = await http.post(
        Uri.parse('$_hfUrl/gradio_api/call/translate_text'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'data': [text, targetLanguage]}),
      );
      final data = jsonDecode(res.body);
      final result = await _pollResult('translate_text', data['event_id']);
      stopwatch.stop();
      if (result.isNotEmpty) {
        final translated = result[0] ?? '';
        final audioUrl = _extractAudioUrl(result.length > 1 ? result[1] : null);
        await DatabaseService.cacheTranslation(text, translated, targetLanguage, audioPath: audioUrl);
        return {'translated_text': translated, 'audio_url': audioUrl, 'duration_ms': stopwatch.elapsedMilliseconds};
      }
      return {'translated_text': '', 'audio_url': null};
    } catch (e) {
      return {'translated_text': 'Error: $e', 'audio_url': null, 'error': true};
    }
  }

  static Future<Map<String, dynamic>> translateAudio({
    required Uint8List audioBytes,
    required String targetLanguage,
    String filename = 'audio.wav',
  }) async {
    if (!_isOnline) return {'asr_transcript': '', 'translated_text': 'No internet connection', 'audio_url': null, 'error': true};

    final stopwatch = Stopwatch()..start();
    try {
      final uploadReq = http.MultipartRequest('POST', Uri.parse('$_hfUrl/gradio_api/upload'));
      uploadReq.files.add(http.MultipartFile.fromBytes('files', audioBytes, filename: filename));
      final uploadRes = await http.Response.fromStream(await uploadReq.send());
      final uploadData = jsonDecode(uploadRes.body);
      final filePath = uploadData is List ? uploadData[0] : uploadData['path'];

      final res = await http.post(
        Uri.parse('$_hfUrl/gradio_api/call/translate_audio'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'data': [{'path': filePath}, targetLanguage]}),
      );
      final data = jsonDecode(res.body);
      final result = await _pollResult('translate_audio', data['event_id']);
      stopwatch.stop();
      if (result.isNotEmpty) {
        return {
          'asr_transcript': result[0] ?? '',
          'translated_text': result.length > 1 ? result[1] ?? '' : '',
          'audio_url': _extractAudioUrl(result.length > 2 ? result[2] : null),
          'duration_ms': stopwatch.elapsedMilliseconds,
        };
      }
      return {'asr_transcript': '', 'translated_text': '', 'audio_url': null};
    } catch (e) {
      return {'asr_transcript': '', 'translated_text': 'Error: $e', 'audio_url': null, 'error': true};
    }
  }
}