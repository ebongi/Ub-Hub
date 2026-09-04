import 'package:google_generative_ai/google_generative_ai.dart' show DataPart;
import 'package:flutter/foundation.dart';
import 'package:go_study/services/gemini_client.dart';
import 'package:go_study/services/database.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:go_study/services/ai_service.dart';

const String _kGeminiSystemInstruction =
    "You are 'Gemini Academic', a world-class academic assistant and tutor. "
    "Your goal is to provide accurate, comprehensive, and helpful information to students. "
    "\n\nGUIDELINES:\n"
    "1. **Professionalism**: Always be polite, encouraging, and professional.\n"
    "2. **Completeness**: Break down complex concepts step-by-step.\n"
    "3. **Mathematics**: Use LaTeX for all math expressions (\$inline\$ and \$\$block\$\$).\n"
    "4. **Formatting**: Use Markdown headers and lists.";

class GeminiService implements AIService {
  static const String _modelName = 'gemini-2.5-flash-lite';

  @override
  bool get requiresCredits => true;

  @override
  bool get supportsAttachments => true;

  GeminiClient _client;

  GeminiService({GeminiClient? client})
    : _client = client ?? _createNewClient();

  static GeminiClient _createNewClient({List<AIChatMessage>? history}) {
    return GeminiProxyChatClient(
      model: _modelName,
      systemInstruction: _kGeminiSystemInstruction,
      initialHistory: history,
    );
  }

  @override
  void updateHistory(List<AIChatMessage> history) {
    _client = _createNewClient(history: history);
  }

  @override
  void resetChat() {
    _client = _createNewClient();
  }

  @override
  Future<String> sendMessage(
    String message, {
    List<dynamic>? attachments,
    int creditCost = 1,
  }) async {
    try {
      // Check and consume AI Credit
      final authClient = Supabase.instance.client.auth;
      final uid = authClient.currentUser?.id;
      if (uid != null) {
        try {
          await DatabaseService(uid: uid).useAICredit(amount: creditCost);
        } catch (e) {
          if (e.toString().contains("Insufficient")) {
            return "OUT_OF_CREDITS";
          }
          rethrow;
        }
      }

      final responseText = await _client.sendMessage(
        message,
        attachments: attachments?.whereType<DataPart>().toList(),
      );
      return responseText ??
          "I'm sorry, I couldn't generate a response. Please try again.";
    } catch (e) {
      debugPrint('Gemini Error: $e');
      return "I encountered an error connecting to the AI service. Details: ${e.toString().split('\n').first}";
    }
  }

  @override
  Stream<String> streamMessage(
    String message, {
    List<dynamic>? attachments,
    int creditCost = 1,
  }) async* {
    try {
      // Check and consume AI Credit before starting stream
      final authClient = Supabase.instance.client.auth;
      final uid = authClient.currentUser?.id;
      if (uid != null) {
        try {
          await DatabaseService(uid: uid).useAICredit(amount: creditCost);
        } catch (e) {
          if (e.toString().contains("Insufficient")) {
            yield "OUT_OF_CREDITS";
            return;
          }
          rethrow;
        }
      }

      yield* _client.sendMessageStream(
        message,
        attachments: attachments?.whereType<DataPart>().toList(),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Gemini Stream Error: $e');
      }
      yield "Error: Could not load stream. ($e)";
    }
  }

  @override
  Future<String> generateStudyPlan({
    required List<dynamic> tasks,
    required List<dynamic> exams,
  }) async {
    final taskContext = tasks.isEmpty
        ? "No specific tasks listed."
        : tasks
              .map(
                (t) =>
                    "- ${t.title} (${t.priority} priority, deadline: ${t.deadline})",
              )
              .join("\n");

    final examContext = exams.isEmpty
        ? "No upcoming exams listed."
        : exams
              .map((e) => "- ${e.name} (${e.category}, on ${e.startTime})")
              .join("\n");

    final prompt =
        """
You are an expert academic advisor. Based on the following student data, create a highly efficient, balanced, and motivating daily study plan.

TASKS:
$taskContext

UPCOMING EXAMS:
$examContext

Please provide:
1. A prioritized list of what to focus on first.
2. A suggested hourly schedule for today.
3. Quick tips for staying focused.

Format your response in professional Markdown.
""";

    return sendMessage(prompt, creditCost: 5);
  }

  @override
  Future<String> generateQuiz(
    dynamic pdfSource, {
    required QuestionDifficulty difficulty,
  }) async {
    const responseSpec = """

RESPONSE FORMAT:
Your response must be a valid JSON object with the following structure:
{
  "questions": [
    {
      "question": "The question text",
      "options": ["A", "B", "C", "D"],
      "answer": "The correct option text exactly as it appears in options"
    }
  ]
}

Provide ONLY the JSON object. Do not include markdown code fences or extra text.""";

    if (pdfSource is String) {
      final prompt =
          """
You are an expert educator preparing students for an exam. Based on the study material below, generate 5 multiple-choice questions that could plausibly appear on an exam covering this material, at a ${difficulty.label} difficulty level.

STUDY MATERIAL:
$pdfSource
$responseSpec
""";
      return sendMessage(prompt, creditCost: 3);
    }

    final Uint8List pdfBytes = pdfSource as Uint8List;
    final prompt =
        """
You are an expert educator preparing students for an exam. Based on the attached PDF document, generate 5 multiple-choice questions that could plausibly appear on an exam covering this material, at a ${difficulty.label} difficulty level.
$responseSpec
""";

    return sendMessage(
      prompt,
      attachments: [DataPart('application/pdf', pdfBytes)],
      creditCost: 3,
    );
  }

  @override
  Future<String> generateFlashcards(
    dynamic source, {
    int count = 15,
  }) async {
    const responseSpec = """

RESPONSE FORMAT:
Your response must be a single valid JSON object with this exact structure:
{
  "title": "A short title for this deck",
  "cards": [
    {
      "question": "The front of the card - a concise question or term",
      "answer": "The back of the card - the answer or definition, 1-3 sentences"
    }
  ]
}

Provide ONLY the JSON object. Do not include markdown code fences or any extra text.""";

    // Preferred path: the material's text was extracted on-device and is
    // passed inline — far smaller and more reliable than a base64 PDF.
    if (source is String) {
      final prompt =
          """
You are an expert educator creating study flashcards. Based on the study material below, generate $count flashcards covering the most important concepts, definitions, and facts a student should memorize.

STUDY MATERIAL:
$source
$responseSpec
""";
      return sendMessage(prompt, creditCost: 3);
    }

    // Fallback: raw PDF bytes (scanned / image-only material). Only the
    // cloud model can read these.
    final Uint8List pdfBytes = source as Uint8List;
    final prompt =
        """
You are an expert educator creating study flashcards. Based on the attached PDF document, generate $count flashcards covering the most important concepts, definitions, and facts a student should memorize from this material.
$responseSpec
""";

    return sendMessage(
      prompt,
      attachments: [DataPart('application/pdf', pdfBytes)],
      creditCost: 3,
    );
  }

  @override
  Future<String> summarizePdf(dynamic pdfSource) async {
    final bool isText = pdfSource is String;
    final prompt = isText
        ? """
You are an academic assistant. Please summarize the study material below.
Provide:
1. A concise overview (3-4 sentences).
2. Key terms and their definitions found in the text.
3. 3-5 main takeaways or core concepts.

Format the response in professional Markdown.

STUDY MATERIAL:
$pdfSource
"""
        : """
You are an academic assistant. Please summarize the attached PDF document.
Provide:
1. A concise overview (3-4 sentences).
2. Key terms and their definitions found in the text.
3. 3-5 main takeaways or core concepts.

Format the response in professional Markdown.
""";

    try {
      // Check and consume AI Credit before making the billable call
      final authClient = Supabase.instance.client.auth;
      final uid = authClient.currentUser?.id;
      if (uid != null) {
        try {
          await DatabaseService(uid: uid).useAICredit(amount: 3);
        } catch (e) {
          if (e.toString().contains("Insufficient")) {
            return "OUT_OF_CREDITS";
          }
          rethrow;
        }
      }

      final response = await _client
          .sendMessageStream(
            prompt,
            attachments: isText
                ? null
                : [DataPart('application/pdf', pdfSource as Uint8List)],
          )
          .fold("", (p, e) => p + e);

      if (response.isNotEmpty) return response;
      return "I couldn't generate a summary.";
    } catch (e) {
      if (kDebugMode) {
        print('Gemini PDF Error: $e');
      }
      return "Sorry, I encountered an error summarizing the PDF: $e";
    }
  }
}
