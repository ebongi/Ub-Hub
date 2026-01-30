import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/foundation.dart';

class GeminiService {
  // TODO: Replace with your actual API key
  static const String _apiKey = 'AIzaSyBd6SdJGAnXpHKnuJl4lSPF_54alfy9WhQ';
  static const String _modelName = 'gemini-2.5-flash';

  late final GenerativeModel _model;
  late final ChatSession _chat;

  GeminiService() {
    _model = GenerativeModel(model: _modelName, apiKey: _apiKey);
    _chat = _model.startChat();
  }

  Future<String> sendMessage(String message) async {
    try {
      final response = await _chat.sendMessage(Content.text(message));
      return response.text ?? "I couldn't generate a response.";
    } catch (e) {
      if (kDebugMode) {
        print('Gemini Error: $e');
      }
      return "Sorry, I encountered an error connecting to the AI service. Please check your API key / internet connection.";
    }
  }

  Stream<String> streamMessage(String message) async* {
    try {
      final response = _chat.sendMessageStream(Content.text(message));
      await for (final chunk in response) {
        if (chunk.text != null) {
          yield chunk.text!;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Gemini Stream Error: $e');
      }
      yield "Error: Could not stream response.";
    }
  }
}
