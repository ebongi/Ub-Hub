enum LanguageTrack {
  frForEn('FR_FOR_EN'),
  enForFr('EN_FOR_FR');

  final String jsonValue;
  const LanguageTrack(this.jsonValue);

  static LanguageTrack? fromCourseCode(String code) {
    switch (code.toUpperCase()) {
      case 'FRE100':
        return LanguageTrack.frForEn;
      case 'ENG100':
        return LanguageTrack.enForFr;
      default:
        return null;
    }
  }

  static LanguageTrack fromJson(String value) {
    return LanguageTrack.values.firstWhere((t) => t.jsonValue == value);
  }
}

enum ExerciseType {
  wordBank('WORD_BANK'),
  matching('MATCHING'),
  cloze('CLOZE');

  final String jsonValue;
  const ExerciseType(this.jsonValue);

  static ExerciseType fromJson(String value) {
    return ExerciseType.values.firstWhere((t) => t.jsonValue == value);
  }
}

class ExercisePair {
  final String source;
  final String target;

  const ExercisePair({required this.source, required this.target});

  factory ExercisePair.fromJson(Map<String, dynamic> json) {
    return ExercisePair(
      source: json['source'] as String,
      target: json['target'] as String,
    );
  }
}

class LanguageExercise {
  static const List<String> levels = ['A1', 'A2', 'B1', 'B2'];

  final String id;
  final LanguageTrack track;
  final String level;
  final String category;
  final String partOfSpeech;
  final ExerciseType exerciseType;
  final String prompt;
  final String sourceText;
  final String targetAnswer;
  final List<String>? wordBank;
  final List<String>? options;
  final List<ExercisePair>? pairs;
  final String explanation;

  const LanguageExercise({
    required this.id,
    required this.track,
    required this.level,
    required this.category,
    required this.partOfSpeech,
    required this.exerciseType,
    required this.prompt,
    required this.sourceText,
    required this.targetAnswer,
    this.wordBank,
    this.options,
    this.pairs,
    required this.explanation,
  });

  factory LanguageExercise.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? const {};
    final metadata = json['metadata'] as Map<String, dynamic>? ?? const {};

    return LanguageExercise(
      id: json['id'] as String,
      track: LanguageTrack.fromJson(json['track'] as String),
      level: json['level'] as String,
      category: json['category'] as String,
      partOfSpeech: json['partOfSpeech'] as String,
      exerciseType: ExerciseType.fromJson(json['exerciseType'] as String),
      prompt: json['prompt'] as String,
      sourceText: json['sourceText'] as String,
      targetAnswer: json['targetAnswer'] as String,
      wordBank: (data['wordBank'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      options: (data['options'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      pairs: (data['pairs'] as List<dynamic>?)
          ?.map((e) => ExercisePair.fromJson(e as Map<String, dynamic>))
          .toList(),
      explanation: metadata['explanation'] as String? ?? '',
    );
  }

  /// The correct word-bank chip sequence: `targetAnswer` tokenized on spaces
  /// with trailing punctuation stripped from each token. Word-bank chips
  /// never carry sentence punctuation, so this is how a chip sequence is
  /// compared against the answer.
  List<String> get wordBankAnswerTokens => targetAnswer
      .split(' ')
      .map((t) => t.replaceAll(RegExp(r'[.,;?!]+$'), ''))
      .toList();
}
