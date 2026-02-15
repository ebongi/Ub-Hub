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
            GenerativeModel(
              model: _modelName,
              apiKey: _apiKey,
              systemInstruction: Content.system(
                r"You are a helpful academic assistant. "
                r"Whenever you provide mathematical expressions, formulas, or equations, "
                r"you MUST use LaTeX format. "
                r"Use single dollar signs for inline math (e.g., $E=mc^2$) "
                r"and double dollar signs for block math (e.g., $$ \int_0^\infty e^{-x^2} dx = \frac{\sqrt{\pi}}{2} $$). "
                r"Ensure all exponents, subscripts, and special characters like integrals, "
                r"summations, and Greek letters are correctly formatted in LaTeX.",
              ),
            ).startChat(),
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
