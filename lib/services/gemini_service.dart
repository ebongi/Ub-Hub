import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/foundation.dart';
import 'package:go_study/core/app_config.dart';
import 'package:go_study/services/gemini_client.dart';

class GeminiService {
  // Read API key from environment
  static final String _apiKey = AppConfig.geminiApiKey;
  static const String _modelName = 'gemini-2.5-flash-lite';

  GeminiClient _client;

  GeminiService({GeminiClient? client})
    : _client = client ?? _createNewClient();

  static GeminiClient _createNewClient({List<Content>? history}) {
    return GeminiChatSessionClient(
      GenerativeModel(
        model: _modelName,
        apiKey: _apiKey,
        systemInstruction: Content.system(
          "You are 'Gemini Academic', a world-class academic assistant and tutor. "
          "Your goal is to provide accurate, comprehensive, and helpful information to students. "
          "\n\nGUIDELINES:\n"
          "1. **Professionalism**: Always be polite, encouraging, and professional. Avoid slang or 'funny' informal answers unless specifically asked for humor.\n"
          "2. **Completeness**: When asked about a topic, provide all necessary details. If a concept is complex, break it down step-by-step.\n"
          "3. **Mathematics**: Use LaTeX for ALL mathematical expressions. "
          "Use single dollar signs for inline math (e.g., \$E=mc^2\$) and double dollar signs for block math (e.g., \$\$ \\int_0^\\infty e^{-x^2} dx \$\$).\n"
          "4. **Formatting**: Use Markdown headers, lists, and bold text to make your answers easy to read.\n"
          "5. **Context**: If the user provides images or PDFs, analyze them thoroughly before answering.",
        ),
      ).startChat(history: history),
    );
  }

  void updateHistory(List<Content> history) {
    _client = _createNewClient(history: history);
  }

  void resetChat() {
    _client = _createNewClient();
  }

  Future<String> sendMessage(
    String message, {
    List<DataPart>? attachments,
  }) async {
    try {
      final responseText = await _client.sendMessage(
        message,
        attachments: attachments,
      );
      return responseText ?? "I couldn't generate a response.";
    } catch (e) {
      if (kDebugMode) {
        print('Gemini Error: $e');
      }
      return "Sorry, I encountered an error connecting to the AI service: $e";
    }
  }

  Stream<String> streamMessage(
    String message, {
    List<DataPart>? attachments,
  }) async* {
    try {
      yield* _client.sendMessageStream(message, attachments: attachments);
    } catch (e) {
      if (kDebugMode) {
        print('Gemini Stream Error: $e');
      }
      yield "Error: Could not load stream. ($e)";
    }
  }

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

    return sendMessage(prompt);
  }

  Future<String> generateQuiz(String sourceText) async {
    final prompt =
        """
You are an expert educator. Based on the text provided below, generate a 5-question multiple-choice quiz.

TEXT:
$sourceText

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

Provide ONLY the JSON object. Do not include markdown formatting or extra text.
""";

    return sendMessage(prompt);
  }

  Future<String> summarizePdf(Uint8List pdfBytes) async {
    const prompt = """
You are an academic assistant. Please summarize the attached PDF document.
Provide:
1. A concise overview (3-4 sentences).
2. Key terms and their definitions found in the text.
3. 3-5 main takeaways or core concepts.

Format the response in professional Markdown.
""";

    try {
      final response = await _client
          .sendMessageStream(
            prompt,
            attachments: [DataPart('application/pdf', pdfBytes)],
          )
          .fold("", (p, e) => p + e);
      return response.isNotEmpty ? response : "I couldn't generate a summary.";
    } catch (e) {
      if (kDebugMode) {
        print('Gemini PDF Error: $e');
      }
      return "Sorry, I encountered an error summarizing the PDF: $e";
    }
  }
}
