import 'dart:async';

abstract class AIService {
  /// Whether calls to this service consume the user's AI credits. Cloud
  /// implementations cost real API money and must gate on credits;
  /// on-device implementations have no marginal cost and should not.
  bool get requiresCredits;

  /// Whether [sendMessage]/[streamMessage] accept non-empty [attachments].
  /// UI-only signal (e.g. hide an attach-file button) — not a semantic
  /// gate; implementations that don't support attachments still throw if
  /// called with them anyway, this just avoids surfacing a "supported"
  /// affordance for something that will always fail.
  bool get supportsAttachments;

  /// Sends a single message and returns the full response.
  Future<String> sendMessage(
    String message, {
    List<dynamic>? attachments,
    int creditCost = 1,
  });

  /// Sends a message and returns a stream of response chunks.
  Stream<String> streamMessage(
    String message, {
    List<dynamic>? attachments,
    int creditCost = 1,
  });

  /// Updates the chat history for stateful services.
  void updateHistory(List<AIChatMessage> history);

  /// Resets the chat session.
  void resetChat();

  /// Generates a study plan based on tasks and exams.
  Future<String> generateStudyPlan({
    required List<dynamic> tasks,
    required List<dynamic> exams,
  });

  /// Generates a 5-question multiple-choice quiz from a PDF document's raw
  /// bytes, at the requested difficulty.
  Future<String> generateQuiz(
    dynamic pdfSource, {
    required QuestionDifficulty difficulty,
  });

  /// Summarizes a PDF document from its raw bytes.
  Future<String> summarizePdf(dynamic pdfSource);
}

enum QuestionDifficulty { low, intermediate, advanced }

extension QuestionDifficultyLabel on QuestionDifficulty {
  String get label {
    switch (this) {
      case QuestionDifficulty.low:
        return "Low (recall & basic understanding)";
      case QuestionDifficulty.intermediate:
        return "Intermediate (applied understanding)";
      case QuestionDifficulty.advanced:
        return "Advanced (analysis, application, exam-level difficulty)";
    }
  }

  String get displayName {
    switch (this) {
      case QuestionDifficulty.low:
        return "Low";
      case QuestionDifficulty.intermediate:
        return "Intermediate";
      case QuestionDifficulty.advanced:
        return "Advanced";
    }
  }
}

class AIChatMessage {
  final String text;
  final bool isUser;
  final List<AIAttachment>? attachments;

  AIChatMessage({
    required this.text,
    required this.isUser,
    this.attachments,
  });
}

class AIAttachment {
  final String mimeType;
  final dynamic bytes;

  AIAttachment(this.mimeType, this.bytes);
}
