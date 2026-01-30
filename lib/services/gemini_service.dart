import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/foundation.dart';
import 'package:neo/core/app_config.dart';
import 'package:neo/services/gemini_client.dart';

class GeminiService {
  // Read API key from environment
  static final String _apiKey = AppConfig.geminiApiKey;
  static const String _modelName = 'gemini-2.5-flash-lite';

  final GeminiClient _client;

  GeminiService({GeminiClient? client})
    : _client =
          client ??
          GeminiChatSessionClient(
            GenerativeModel(model: _modelName, apiKey: _apiKey).startChat(),
          );

  Future<String> sendMessage(String message) async {
    try {
      final responseText = await _client.sendMessage(message);
      return responseText ?? "I couldn't generate a response.";
    } catch (e) {
      if (kDebugMode) {
        print('Gemini Error: $e');
      }
      return "Sorry, I encountered an error connecting to the AI service: $e";
    }
  }

  Stream<String> streamMessage(String message) async* {
    try {
      yield* _client.sendMessageStream(message);
    } catch (e) {
      if (kDebugMode) {
        print('Gemini Stream Error: $e');
      }
      yield "Error: Could not load stream. ($e)";
    }
  }
}
