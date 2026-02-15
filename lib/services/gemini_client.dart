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
