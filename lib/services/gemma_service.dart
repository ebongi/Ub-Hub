import 'dart:async';

import 'package:flutter_gemma/flutter_gemma.dart' show Message;
import 'package:go_study/services/ai_service.dart';
import 'package:go_study/services/gemma_client.dart';

/// On-device implementation of [AIService], backed by `flutter_gemma`.
/// Text-only in Phase 1 (chat tutor + UB Support Bot); the study-plan/quiz
/// /summarize methods are out of scope until later phases (Phase 2/3),
/// which need PDF text extraction + OCR + chunking this class doesn't do.
class GemmaService implements AIService {
  final GemmaClient _client;

  GemmaService({required GemmaClient client}) : _client = client;

  @override
  bool get requiresCredits => false;

  @override
  bool get supportsAttachments => false;

  @override
  Future<String> sendMessage(
    String message, {
    List<dynamic>? attachments,
    int creditCost = 1,
  }) {
    _rejectAttachments(attachments);
    return _client.sendMessage(message);
  }

  @override
  Stream<String> streamMessage(
    String message, {
    List<dynamic>? attachments,
    int creditCost = 1,
  }) {
    _rejectAttachments(attachments);
    return _client.sendMessageStream(message);
  }

  void _rejectAttachments(List<dynamic>? attachments) {
    if (attachments != null && attachments.isNotEmpty) {
      throw UnsupportedError(
        'GemmaService is text-only in Phase 1 — attachments are not '
        'supported on-device.',
      );
    }
  }

  @override
  void updateHistory(List<AIChatMessage> history) {
    final client = _client;
    if (client is GemmaChatSessionClient) {
      final replay = history
          .map((msg) => Message.text(text: msg.text, isUser: msg.isUser))
          .toList();
      unawaited(client.resetChat(replayHistory: replay));
    }
  }

  @override
  void resetChat() {
    final client = _client;
    if (client is GemmaChatSessionClient) {
      unawaited(client.resetChat());
    }
  }

  @override
  Future<String> generateStudyPlan({
    required List<dynamic> tasks,
    required List<dynamic> exams,
  }) {
    throw UnimplementedError(
      'GemmaService does not support generateStudyPlan in Phase 1 '
      '(Phase 2 scope).',
    );
  }

  @override
  Future<String> generateQuiz(
    dynamic pdfSource, {
    required QuestionDifficulty difficulty,
  }) {
    throw UnimplementedError(
      'GemmaService does not support generateQuiz in Phase 1 '
      '(Phase 3 scope).',
    );
  }

  @override
  Future<String> summarizePdf(dynamic pdfSource) {
    throw UnimplementedError(
      'GemmaService does not support summarizePdf in Phase 1 '
      '(Phase 3 scope).',
    );
  }
}
