import 'package:flutter_gemma/flutter_gemma.dart';

/// Interface for Gemma operations to allow for easier testing. Mirrors
/// [GeminiClient]'s shape so [GemmaService] stays a thin, symmetrical twin
/// of [GeminiService].
abstract class GemmaClient {
  Future<String> sendMessage(String text);
  Stream<String> sendMessageStream(String text);
}

/// Gemma 3 1B ships in `.task` (MediaPipe) format, which silently ignores
/// `maxOutputTokens` (confirmed via the plugin's own runtime log during
/// Phase 0 testing) — so nothing bounds a single response's length at the
/// model layer. This is an independent, app-level backstop: once a
/// streamed response's running character count crosses this ceiling,
/// callers stop the generation rather than trust the model to terminate
/// cleanly on every prompt (a smaller model tested in Phase 0 rambled for
/// 90s with no clean stop token).
const int gemmaMaxResponseChars = 4000;

bool shouldStopForLength(int totalChars, {int limit = gemmaMaxResponseChars}) =>
    totalChars >= limit;

/// Extracts plain text from a [ModelResponse]. Phase 1 registers no tools
/// and requests no thinking mode, so only [TextResponse] should ever occur
/// in practice — but [ModelResponse] is a sealed type covering function
/// -call/thinking variants too, so this must still handle them rather than
/// crash if one ever appears.
String unwrapModelResponseText(ModelResponse response) {
  return switch (response) {
    TextResponse(token: final token) => token,
    _ => '',
  };
}

/// Stateful implementation of [GemmaClient]: wraps a single [InferenceChat]
/// whose history persists across calls, for the main chat tutor.
///
/// Takes a *loader* rather than an already-resolved [InferenceModel] so it
/// can be constructed synchronously (model load — the ~7s-cost operation
/// measured in Phase 0 — happens lazily on first actual use, not before the
/// consuming screen is even built). See [AIEngineSelector].
class GemmaChatSessionClient implements GemmaClient {
  final Future<InferenceModel> Function() _loadModel;
  final String? _systemInstruction;
  InferenceChat? _chat;

  GemmaChatSessionClient(this._loadModel, {String? systemInstruction})
    : _systemInstruction = systemInstruction;

  Future<InferenceChat> _ensureChat() async {
    final existing = _chat;
    if (existing != null) return existing;
    final model = await _loadModel();
    final chat = await model.createChat(
      systemInstruction: _systemInstruction,
    );
    _chat = chat;
    return chat;
  }

  @override
  Future<String> sendMessage(String text) async {
    final chat = await _ensureChat();
    await chat.addQueryChunk(Message.text(text: text, isUser: true));
    final response = await chat.generateChatResponse();
    return unwrapModelResponseText(response);
  }

  @override
  Stream<String> sendMessageStream(String text) async* {
    final chat = await _ensureChat();
    await chat.addQueryChunk(Message.text(text: text, isUser: true));
    var totalChars = 0;
    await for (final response in chat.generateChatResponseAsync()) {
      final chunk = unwrapModelResponseText(response);
      if (chunk.isEmpty) continue;
      totalChars += chunk.length;
      yield chunk;
      if (shouldStopForLength(totalChars)) {
        await chat.stopGeneration();
        break;
      }
    }
  }

  /// Clears the chat's history, optionally replaying [replayHistory] back
  /// into the fresh session — used for both a plain reset (no replay) and
  /// syncing an externally-managed history (replay).
  Future<void> resetChat({List<Message>? replayHistory}) async {
    final chat = await _ensureChat();
    await chat.clearHistory(replayHistory: replayHistory);
  }

  Future<void> close() async {
    final chat = _chat;
    if (chat != null) await chat.close();
  }
}

/// Stateless implementation of [GemmaClient]: each call creates a fresh,
/// throwaway [InferenceChat] with a fixed system persona and no accumulated
/// history, closed immediately after — mirrors why [GeminiOneShotClient]
/// exists (retrieval-augmented Q&A, not an ongoing conversation). Used by
/// [KnowledgeBotService]. Same lazy-loader shape as [GemmaChatSessionClient]
/// and for the same reason.
class GemmaOneShotClient implements GemmaClient {
  final Future<InferenceModel> Function() _loadModel;
  final String _systemInstruction;

  GemmaOneShotClient(this._loadModel, {required String systemInstruction})
    : _systemInstruction = systemInstruction;

  @override
  Future<String> sendMessage(String text) async {
    final model = await _loadModel();
    final chat = await model.createChat(
      systemInstruction: _systemInstruction,
    );
    try {
      await chat.addQueryChunk(Message.text(text: text, isUser: true));
      final response = await chat.generateChatResponse();
      return unwrapModelResponseText(response);
    } finally {
      await chat.close();
    }
  }

  @override
  Stream<String> sendMessageStream(String text) async* {
    final model = await _loadModel();
    final chat = await model.createChat(
      systemInstruction: _systemInstruction,
    );
    try {
      await chat.addQueryChunk(Message.text(text: text, isUser: true));
      var totalChars = 0;
      await for (final response in chat.generateChatResponseAsync()) {
        final chunk = unwrapModelResponseText(response);
        if (chunk.isEmpty) continue;
        totalChars += chunk.length;
        yield chunk;
        if (shouldStopForLength(totalChars)) {
          await chat.stopGeneration();
          break;
        }
      }
    } finally {
      await chat.close();
    }
  }
}
