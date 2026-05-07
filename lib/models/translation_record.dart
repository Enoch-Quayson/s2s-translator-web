class TranslationRecord {
  final int? id;
  final String sourceText;
  final String translatedText;
  final String sourceLang;
  final String targetLanguage;
  final String inputMode;
  final String? audioPath;
  final double? confidence;
  final int? durationMs;
  final bool isStarred;
  final DateTime createdAt;

  TranslationRecord({
    this.id,
    required this.sourceText,
    required this.translatedText,
    this.sourceLang = 'en',
    required this.targetLanguage,
    required this.inputMode,
    this.audioPath,
    this.confidence,
    this.durationMs,
    this.isStarred = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'source_text': sourceText,
    'translated_text': translatedText,
    'source_lang': sourceLang,
    'target_language': targetLanguage,
    'input_mode': inputMode,
    'audio_path': audioPath,
    'confidence': confidence,
    'duration_ms': durationMs,
    'is_starred': isStarred ? 1 : 0,
    'created_at': createdAt.toIso8601String(),
  };

  factory TranslationRecord.fromMap(Map<String, dynamic> map) => TranslationRecord(
    id: map['id'],
    sourceText: map['source_text'] ?? '',
    translatedText: map['translated_text'] ?? '',
    sourceLang: map['source_lang'] ?? 'en',
    targetLanguage: map['target_language'] ?? 'fr',
    inputMode: map['input_mode'] ?? 'text',
    audioPath: map['audio_path'],
    confidence: map['confidence']?.toDouble(),
    durationMs: map['duration_ms'],
    isStarred: (map['is_starred'] ?? 0) == 1,
    createdAt: DateTime.parse(map['created_at']),
  );

  TranslationRecord copyWith({bool? isStarred}) => TranslationRecord(
    id: id, sourceText: sourceText, translatedText: translatedText,
    sourceLang: sourceLang, targetLanguage: targetLanguage, inputMode: inputMode,
    audioPath: audioPath, confidence: confidence, durationMs: durationMs,
    isStarred: isStarred ?? this.isStarred, createdAt: createdAt,
  );
}
