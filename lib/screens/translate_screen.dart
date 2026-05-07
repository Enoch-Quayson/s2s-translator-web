import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:record/record.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../services/api_service.dart';

class TranslateScreen extends StatefulWidget {
  final Language targetLang;
  const TranslateScreen({super.key, required this.targetLang});
  @override
  State<TranslateScreen> createState() => _TranslateScreenState();
}

class _TranslateScreenState extends State<TranslateScreen> {
  int _inputMode = 0;
  bool _isRecording = false;
  bool _isTranslating = false;
  bool _isPlaying = false;
  final _textController = TextEditingController();
  final _audioRecorder = AudioRecorder();
  String _sourceText = '';
  String _translatedText = '';
  double _confidence = 0;
  String? _audioUrl;
  String? _pickedFileName;
  late Language _targetLang;

  @override
  void initState() {
    super.initState();
    _targetLang = widget.targetLang;
  }

  void _showLanguagePicker() {
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
            final isSelected = _targetLang.apiCode == lang.apiCode;
            return GestureDetector(
              onTap: () { setState(() { _targetLang = lang; _clear(); }); Navigator.pop(context); },
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

  void _playAudio() {
    if (_audioUrl == null) return;
    try {
      js.context.callMethod('eval', ['''
        (function() {
          var audio = window._s2sAudio;
          if (audio) { audio.pause(); }
          audio = new Audio("$_audioUrl");
          window._s2sAudio = audio;
          audio.play();
        })();
      ''']);
      setState(() => _isPlaying = true);
    } catch (e) { _showError('Could not play audio: $e'); }
  }

  void _stopAudio() {
    try {
      js.context.callMethod('eval', ['if(window._s2sAudio){window._s2sAudio.pause();}']);
      setState(() => _isPlaying = false);
    } catch (_) {}
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        await _audioRecorder.start(const RecordConfig(encoder: AudioEncoder.wav), path: 'recorded_audio.wav');
        setState(() => _isRecording = true);
      } else { _showError('Microphone permission denied'); }
    } catch (e) { _showError('Could not start recording: $e'); }
  }

  Future<void> _stopRecordingAndTranslate() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() { _isRecording = false; _isTranslating = true; });
      if (path == null) { setState(() => _isTranslating = false); _showError('Recording failed'); return; }
      final response = await http.get(Uri.parse(path));
      final audioBytes = response.bodyBytes;
      if (audioBytes.isEmpty) { setState(() => _isTranslating = false); _showError('No audio data captured'); return; }
      final result = await ApiService.translateAudio(audioBytes: audioBytes, targetLanguage: _targetLang.apiCode, filename: 'recording.wav');
      setState(() { _sourceText = result['asr_transcript'] ?? ''; _translatedText = result['translated_text'] ?? ''; _audioUrl = result['audio_url']; _isTranslating = false; });
    } catch (e) {
      setState(() { _isRecording = false; _isTranslating = false; });
      _showError('Translation failed: $e');
    }
  }

  Future<void> _translateText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    setState(() { _isTranslating = true; _sourceText = text; });
    try {
      final result = await ApiService.translateText(text: text, targetLanguage: _targetLang.apiCode);
      setState(() { _translatedText = result['translated_text'] ?? ''; _confidence = (result['confidence'] ?? 0.0).toDouble(); _audioUrl = result['audio_url']; _isTranslating = false; });
    } catch (e) { setState(() => _isTranslating = false); _showError('Translation failed: $e'); }
  }

  Future<void> _pickAndTranslateFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['mp3', 'wav', 'm4a', 'aac'], withData: true);
    if (result == null) return;
    setState(() { _isTranslating = true; _pickedFileName = result.files.single.name; });
    try {
      final bytes = result.files.single.bytes;
      if (bytes == null) { setState(() => _isTranslating = false); _showError('Could not read file'); return; }
      final res = await ApiService.translateAudio(audioBytes: bytes, targetLanguage: _targetLang.apiCode, filename: result.files.single.name);
      setState(() { _sourceText = res['asr_transcript'] ?? _pickedFileName ?? ''; _translatedText = res['translated_text'] ?? ''; _audioUrl = res['audio_url']; _isTranslating = false; });
    } catch (e) { setState(() => _isTranslating = false); _showError('Translation failed: $e'); }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.error));
  }

  void _clear() {
    _stopAudio();
    setState(() { _textController.clear(); _sourceText = ''; _translatedText = ''; _confidence = 0; _audioUrl = null; _pickedFileName = null; _isPlaying = false; });
  }

  @override
  void dispose() { _audioRecorder.dispose(); _stopAudio(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;
    final txColor = isDark ? AppColors.txDark : AppColors.txLight;
    final tx2Color = isDark ? AppColors.tx2Dark : AppColors.tx2Light;
    final tx3Color = isDark ? AppColors.tx3Dark : AppColors.tx3Light;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final card2Color = isDark ? AppColors.card2Dark : AppColors.card2Light;

    return ListView(children: [
      // Header with language selector
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Row(children: [
          Text('Translate', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: txColor, letterSpacing: -0.3)),
          const Spacer(),
          // Language direction indicator
          LangBadge(lang: langEnglish),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: Icon(Icons.arrow_forward_rounded, size: 14, color: tx3Color)),
          // Target language dropdown button
          GestureDetector(
            onTap: _showLanguagePicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _targetLang.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _targetLang.color.withOpacity(0.4)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(_targetLang.flag, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(_targetLang.name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _targetLang.color, fontFamily: 'Outfit')),
                const SizedBox(width: 2),
                Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: _targetLang.color),
              ]),
            ),
          ),
        ]),
      ),

      InputModeTabs(selected: _inputMode, onChanged: (i) => setState(() => _inputMode = i)),
      if (_inputMode == 0) _micSection(accent, txColor, tx2Color, borderColor),
      if (_inputMode == 1) _textSection(accent, txColor, tx3Color, borderColor),
      if (_inputMode == 2) _fileSection(accent, tx2Color, tx3Color, card2Color, borderColor),
      if (_sourceText.isNotEmpty || _translatedText.isNotEmpty) ...[
        const SectionTitle('Translation'),
        _outputCard(txColor, tx3Color, borderColor),
      ],
      if (_audioUrl != null) ...[
        const SectionTitle('Audio'),
        _audioCard(accent, tx3Color, borderColor),
      ],
      const SizedBox(height: 16),
    ]);
  }

  Widget _micSection(Color accent, Color txColor, Color tx2Color, Color borderColor) {
    return AppCard(child: Column(children: [
      Row(children: [
        Text('${langEnglish.flag} English', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: txColor)),
        Text(' → ', style: TextStyle(fontSize: 12, color: tx2Color)),
        Text('${_targetLang.flag} ${_targetLang.name}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _targetLang.color)),
      ]),
      const SizedBox(height: 16),
      GestureDetector(
        onTap: _isTranslating ? null : (_isRecording ? _stopRecordingAndTranslate : _startRecording),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 72, height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isTranslating ? Colors.grey : _isRecording ? AppColors.error : accent,
            boxShadow: [BoxShadow(color: (_isRecording ? AppColors.error : accent).withOpacity(0.35), blurRadius: _isRecording ? 20 : 10, spreadRadius: _isRecording ? 4 : 0)],
          ),
          child: _isTranslating
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Icon(_isRecording ? Icons.stop_rounded : Icons.mic_rounded, color: Colors.white, size: 28),
        ),
      ),
      const SizedBox(height: 12),
      Text(_isTranslating ? 'Translating...' : _isRecording ? 'Recording... tap to stop' : 'Tap to start recording', style: TextStyle(fontSize: 12, color: tx2Color)),
      if (_isRecording) ...[const SizedBox(height: 8), LinearProgressIndicator(backgroundColor: Colors.grey.withOpacity(0.2), valueColor: AlwaysStoppedAnimation(AppColors.error))],
    ]));
  }

  Widget _textSection(Color accent, Color txColor, Color tx3Color, Color borderColor) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(children: [
        Container(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('${langEnglish.flag} English', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: txColor)),
            const Spacer(),
            if (_textController.text.isNotEmpty) GestureDetector(onTap: _clear, child: Icon(Icons.close_rounded, size: 16, color: txColor)),
          ]),
          const SizedBox(height: 8),
          TextField(
            controller: _textController, maxLines: 4,
            onChanged: (_) => setState(() {}),
            style: TextStyle(fontSize: 14, color: txColor, fontFamily: 'Outfit'),
            decoration: InputDecoration(border: InputBorder.none, hintText: 'Enter English text to translate...', hintStyle: TextStyle(color: tx3Color, fontSize: 14), isDense: true),
          ),
        ])),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(border: Border(top: BorderSide(color: borderColor))),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isTranslating ? null : _translateText,
              style: ElevatedButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(vertical: 10), elevation: 0),
              child: _isTranslating
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.translate_rounded, size: 16),
                      const SizedBox(width: 6),
                      Text('Translate to ${_targetLang.name}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ]),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _fileSection(Color accent, Color tx2Color, Color tx3Color, Color card2Color, Color borderColor) {
    return AppCard(child: Column(children: [
      GestureDetector(
        onTap: _isTranslating ? null : _pickAndTranslateFile,
        child: Container(
          width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: borderColor), color: card2Color),
          child: Column(children: [
            Icon(Icons.upload_file_rounded, size: 28, color: tx3Color),
            const SizedBox(height: 8),
            Text(_pickedFileName ?? 'Drop a file or tap to browse', style: TextStyle(fontSize: 13, color: tx2Color, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            Text('.mp3 .wav .m4a .aac', style: TextStyle(fontSize: 11, color: tx3Color, fontFamily: 'DM Mono')),
          ]),
        ),
      ),
      if (_isTranslating) ...[const SizedBox(height: 12), LinearProgressIndicator(backgroundColor: Colors.grey.withOpacity(0.2), valueColor: AlwaysStoppedAnimation(accent))],
    ]));
  }

  Widget _outputCard(Color txColor, Color tx3Color, Color borderColor) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(children: [
        Container(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${langEnglish.flag} English Transcript', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: txColor)),
          const SizedBox(height: 8),
          Text(_sourceText.isEmpty ? 'English text will appear here...' : _sourceText, style: TextStyle(fontSize: 13, color: _sourceText.isEmpty ? tx3Color : txColor)),
        ])),
        Container(height: 1, color: borderColor),
        Container(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('${_targetLang.flag} ${_targetLang.name} Translation', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _targetLang.color)),
            const Spacer(),
            if (_confidence > 0) ConfidenceBar(confidence: _confidence),
          ]),
          const SizedBox(height: 8),
          Text(
            _translatedText.isEmpty ? '${_targetLang.name} translation will appear here...' : _translatedText,
            style: TextStyle(fontSize: 13, color: _translatedText.isEmpty ? tx3Color : _targetLang.color, fontStyle: _translatedText.isEmpty ? FontStyle.normal : FontStyle.italic),
          ),
        ])),
      ]),
    );
  }

  Widget _audioCard(Color accent, Color tx3Color, Color borderColor) {
    return AppCard(child: Row(children: [
      IconButton(
        onPressed: _audioUrl != null ? (_isPlaying ? _stopAudio : _playAudio) : null,
        icon: Icon(_isPlaying ? Icons.pause_circle_rounded : Icons.play_circle_rounded, color: _audioUrl != null ? accent : tx3Color, size: 36),
      ),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        LinearProgressIndicator(value: _isPlaying ? null : 0, backgroundColor: borderColor, valueColor: AlwaysStoppedAnimation(accent), minHeight: 3),
        const SizedBox(height: 4),
        Text(_isPlaying ? 'Playing...' : 'Tap play to listen', style: TextStyle(fontSize: 10, color: tx3Color, fontFamily: 'DM Mono')),
      ])),
    ]));
  }
}