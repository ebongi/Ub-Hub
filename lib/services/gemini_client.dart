import 'package:google_generative_ai/google_generative_ai.dart';

/// Interface for Gemini operations to allow for easier testing.
abstract class GeminiClient {
  Future<String?> sendMessage(String text);
  Stream<String> sendMessageStream(String text);
}

/// Production implementation of [GeminiClient] using [ChatSession].
class GeminiChatSessionClient implements GeminiClient {
  final ChatSession _session;

  GeminiChatSessionClient(this._session);

  @override
  Future<String?> sendMessage(String text) async {
    final response = await _session.sendMessage(Content.text(text));
    return response.text;
  }

  @override
  Stream<String> sendMessageStream(String text) async* {
    final response = _session.sendMessageStream(Content.text(text));
    await for (final chunk in response) {
      if (chunk.text != null) {
        yield chunk.text!;
      }
    }
  }
}
