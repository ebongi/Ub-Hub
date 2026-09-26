/// A deck of AI-generated study flashcards derived from a course material.
/// `courseId` / `departmentId` are copied from the source material at
/// creation so a course/department screen can list its decks with one filter.
class FlashcardDeck {
  final String id;
  final String materialId;
  final String? courseId;
  final String? departmentId;
  final String userId;
  final String title;
  final int cardCount;
  final DateTime? createdAt;

  FlashcardDeck({
    this.id = '',
    required this.materialId,
    this.courseId,
    this.departmentId,
    required this.userId,
    required this.title,
    this.cardCount = 0,
    this.createdAt,
  });

  factory FlashcardDeck.fromSupabase(Map<String, dynamic> json) {
    return FlashcardDeck(
      id: json['id'] ?? '',
      materialId: json['material_id'] ?? '',
      courseId: json['course_id'],
      departmentId: json['department_id'],
      userId: json['user_id'] ?? '',
      title: json['title'] ?? '',
      cardCount: json['card_count'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'material_id': materialId,
      'course_id': courseId,
      'department_id': departmentId,
      'user_id': userId,
      'title': title,
      'card_count': cardCount,
      if (id.isNotEmpty && !id.startsWith('temp_')) 'id': id,
    };
  }
}

/// A single question/answer card belonging to a [FlashcardDeck].
class Flashcard {
  final String id;
  final String deckId;
  final String question;
  final String answer;
  final int position;

  Flashcard({
    this.id = '',
    this.deckId = '',
    required this.question,
    required this.answer,
    this.position = 0,
  });

  factory Flashcard.fromSupabase(Map<String, dynamic> json) {
    return Flashcard(
      id: json['id'] ?? '',
      deckId: json['deck_id'] ?? '',
      question: json['question'] ?? '',
      answer: json['answer'] ?? '',
      position: json['position'] ?? 0,
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      if (deckId.isNotEmpty) 'deck_id': deckId,
      'question': question,
      'answer': answer,
      'position': position,
      if (id.isNotEmpty && !id.startsWith('temp_')) 'id': id,
    };
  }
}
