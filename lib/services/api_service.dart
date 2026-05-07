import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'cache_service.dart';

class ApiService {
  static const String _defaultBaseUrl = 'https://s2s-translator-api-1.onrender.com';
  static const String _hfUrl = 'https://enochquayson-s2s-translator.hf.space';
  static String? _token;

  static const Map<String, String> _langLabels = {
    'fr':  'French 🇫🇷',
    'tw':  'Asante Twi 🇬🇭',
    'ee':  'Ewe 🇬🇭',
    'hau': 'Hausa 🇬🇭',
    'fuv': 'Fulani 🇬🇭',
  };

  static String _toLangLabel(String code) => _langLabels[code] ?? 'French 🇫🇷';

  static Future<String> get baseUrl async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('api_url') ?? _defaultBaseUrl;
  }

  static Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  static Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    await CacheService.load();
  }

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'ngrok-skip-browser-warning': 'true',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  static Future<Map<String, dynamic>> register({required String name, required String email, required String password}) async {
    final url = await baseUrl;
    final res = await http.post(Uri.parse('$url/users/register'), headers: _headers, body: jsonEncode({'name': name, 'email': email, 'password': password}));
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> login({required String email, required String password}) async {
    final url = await baseUrl;
    final res = await http.post(Uri.parse('$url/users/login'), headers: {'Content-Type': 'application/json', 'ngrok-skip-browser-warning': 'true'}, body: jsonEncode({'email': email, 'password': password}));
    final data = jsonDecode(res.body);
    if (data['access_token'] != null) await setToken(data['access_token']);
    return data;
  }

  static Future<void> logout() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
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
    for (int attempt = 0; attempt < 150; attempt++) {
      await Future.delayed(const Duration(seconds: 2));
      try {
        final resultRes = await http.get(uri).timeout(const Duration(seconds: 10));
        final lines = resultRes.body.split('\n');
        String? lastEvent;
        for (final line in lines) {
          if (line.startsWith('event: ')) {
            lastEvent = line.substring(7).trim();
          } else if (line.startsWith('data: ') && lastEvent != null) {
            final dataStr = line.substring(6).trim();
            if (lastEvent == 'heartbeat' || dataStr == 'null' || dataStr.isEmpty) {
              lastEvent = null;
              continue;
            }
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

  /// Get audio URL only from HuggingFace TTS — used after cache hit
  static Future<String?> _fetchAudioOnly(String translatedText, String targetLanguage) async {
    try {
      final langLabel = _toLangLabel(targetLanguage);
      // Send the already-translated text directly for TTS
      final res = await http.post(
        Uri.parse('$_hfUrl/gradio_api/call/translate_text'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'data': [translatedText, langLabel]}),
      ).timeout(const Duration(seconds: 10));
      final data = jsonDecode(res.body);
      final eventId = data['event_id'];
      if (eventId == null) return null;
      final result = await _pollResult('translate_text', eventId);
      if (result.length > 1) {
        return _extractAudioUrl(result[1]);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>> translateText({
    required String text,
    required String targetLanguage,
  }) async {
    // ── Check cache first ──────────────────────────────────────────
    final cached = CacheService.get(text, targetLanguage);
    if (cached != null) {
      print('Cache hit: "$text" → $targetLanguage');
      // Return cached text immediately, then fetch audio in background
      final audioFuture = _fetchAudioOnly(cached, targetLanguage);
      final audioUrl = await audioFuture;
      return {
        'translated_text': cached,
        'audio_url': audioUrl,
        'from_cache': true,
      };
    }

    // ── Fall back to HuggingFace API ───────────────────────────────
    print('Cache miss: "$text" → $targetLanguage, calling API...');
    try {
      final langLabel = _toLangLabel(targetLanguage);
      final res = await http.post(
        Uri.parse('$_hfUrl/gradio_api/call/translate_text'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'data': [text, langLabel]}),
      );
      final data = jsonDecode(res.body);
      final result = await _pollResult('translate_text', data['event_id']);
      if (result.isNotEmpty) {
        return {
          'translated_text': result[0] ?? '',
          'audio_url': _extractAudioUrl(result.length > 1 ? result[1] : null),
          'from_cache': false,
        };
      }
      return {'translated_text': '', 'audio_url': null, 'from_cache': false};
    } catch (e) {
      return {'translated_text': 'Error: $e', 'audio_url': null, 'from_cache': false};
    }
  }

  static Future<Map<String, dynamic>> translateAudio({
    required Uint8List audioBytes,
    required String targetLanguage,
    String filename = 'audio.wav',
  }) async {
    try {
      final langLabel = _toLangLabel(targetLanguage);
      final uploadRequest = http.MultipartRequest('POST', Uri.parse('$_hfUrl/gradio_api/upload'));
      uploadRequest.files.add(http.MultipartFile.fromBytes('files', audioBytes, filename: filename));
      final uploadStreamRes = await uploadRequest.send();
      final uploadRes = await http.Response.fromStream(uploadStreamRes);
      final uploadData = jsonDecode(uploadRes.body);
      final filePath = uploadData is List ? uploadData[0] : uploadData['path'];

      final res = await http.post(
        Uri.parse('$_hfUrl/gradio_api/call/translate_audio'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'data': [{'path': filePath}, langLabel]}),
      );
      final data = jsonDecode(res.body);
      final result = await _pollResult('translate_audio', data['event_id']);
      if (result.isNotEmpty) {
        final transcript = result[0] ?? '';
        final cached = CacheService.get(transcript, targetLanguage);
        if (cached != null) {
          final audioUrl = await _fetchAudioOnly(cached, targetLanguage);
          return {
            'asr_transcript': transcript,
            'translated_text': cached,
            'audio_url': audioUrl,
            'from_cache': true,
          };
        }
        return {
          'asr_transcript': transcript,
          'translated_text': result.length > 1 ? result[1] ?? '' : '',
          'audio_url': _extractAudioUrl(result.length > 2 ? result[2] : null),
          'from_cache': false,
        };
      }
      return {'asr_transcript': '', 'translated_text': '', 'audio_url': null, 'from_cache': false};
    } catch (e) {
      return {'asr_transcript': '', 'translated_text': 'Error: $e', 'audio_url': null, 'from_cache': false};
    }
  }

  static Future<List<dynamic>> getHistory({int limit = 20, int offset = 0}) async {
    try {
      final url = await baseUrl;
      final res = await http.get(Uri.parse('$url/history/?limit=$limit&offset=$offset'), headers: _headers);
      return jsonDecode(res.body)['items'] ?? [];
    } catch (_) { return []; }
  }

  static Future<void> deleteHistory(String id) async {
    try { final url = await baseUrl; await http.delete(Uri.parse('$url/history/$id'), headers: _headers); } catch (_) {}
  }

  static Future<List<dynamic>> getPhrases() async {
    final url = await baseUrl;
    final res = await http.get(Uri.parse('$url/phrasebook/'), headers: _headers);
    return jsonDecode(res.body) ?? [];
  }

  static Future<bool> checkHealth() async {
    try {
      final url = await baseUrl;
      final res = await http.get(Uri.parse('$url/health/'), headers: _headers).timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (_) { return false; }
  }

  static Future<Map<String, dynamic>> getProfile() async {
    final url = await baseUrl;
    final res = await http.get(Uri.parse('$url/users/me'), headers: _headers);
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> getStats() async {
    final url = await baseUrl;
    final res = await http.get(Uri.parse('$url/users/me/stats'), headers: _headers);
    return jsonDecode(res.body);
  }
}
