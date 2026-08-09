import 'package:google_generative_ai/google_generative_ai.dart';

/// Interface for Gemini operations to allow for easier testing.
abstract class GeminiClient {
  Future<String?> sendMessage(String text, {List<DataPart>? attachments});
  Stream<String> sendMessageStream(String text, {List<DataPart>? attachments});
}

/// Production implementation of [GeminiClient] using [ChatSession].
class GeminiChatSessionClient implements GeminiClient {
  final ChatSession _session;

  GeminiChatSessionClient(this._session);

  @override
  Future<String?> sendMessage(
    String text, {
    List<DataPart>? attachments,
  }) async {
    final content = attachments == null
        ? Content.text(text)
        : Content.multi([TextPart(text), ...attachments]);
    final response = await _session.sendMessage(content);
    return response.text;
  }

  @override
  Stream<String> sendMessageStream(
    String text, {
    List<DataPart>? attachments,
  }) async* {
    final content = attachments == null
        ? Content.text(text)
        : Content.multi([TextPart(text), ...attachments]);
    final response = _session.sendMessageStream(content);
    await for (final chunk in response) {
      if (chunk.text != null) {
        yield chunk.text!;
      }
    }
  }
}

/// Stateless implementation of [GeminiClient]: each call is an independent
/// request via [GenerativeModel.generateContent]/[generateContentStream],
/// with no chat history accumulated or replayed across calls. Use this for
/// features where each request is a self-contained question (e.g.
/// retrieval-augmented Q&A) rather than an ongoing multi-turn conversation —
/// a [GeminiChatSessionClient] resends the entire growing history on every
/// call, which makes both latency and cost scale with conversation length.
class GeminiOneShotClient implements GeminiClient {
  final GenerativeModel _model;

  GeminiOneShotClient(this._model);

  @override
  Future<String?> sendMessage(
    String text, {
    List<DataPart>? attachments,
  }) async {
    final content = attachments == null
        ? Content.text(text)
        : Content.multi([TextPart(text), ...attachments]);
    final response = await _model.generateContent([content]);
    return response.text;
  }

  @override
  Stream<String> sendMessageStream(
    String text, {
    List<DataPart>? attachments,
  }) async* {
    final content = attachments == null
        ? Content.text(text)
        : Content.multi([TextPart(text), ...attachments]);
    final response = _model.generateContentStream([content]);
    await for (final chunk in response) {
      if (chunk.text != null) {
        yield chunk.text!;
      }
    }
  }
}
