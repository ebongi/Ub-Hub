import 'dart:async';

abstract class AIService {
  /// Sends a single message and returns the full response.
  Future<String> sendMessage(
    String message, {
    List<dynamic>? attachments,
  });

  /// Sends a message and returns a stream of response chunks.
  Stream<String> streamMessage(
    String message, {
    List<dynamic>? attachments,
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

  /// Generates a 5-question multiple-choice quiz from source text.
  Future<String> generateQuiz(String sourceText);

  /// Summarizes a PDF document from its raw bytes.
  Future<String> summarizePdf(dynamic pdfSource);
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
