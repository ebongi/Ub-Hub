import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:go_study/core/app_config.dart';
import 'package:go_study/services/ai_service.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class DeepSeekService implements AIService {
  String get _apiKey => AppConfig.deepseekApiKey;
  static const String _baseUrl = 'https://api.deepseek.com/chat/completions';
  static const String _modelName = 'deepseek-chat';

  static const String _systemPrompt =
      "You are 'DeepSeek Academic', a world-class academic assistant and tutor. "
      "Your goal is to provide accurate, comprehensive, and helpful information to students. "
      "\n\nGUIDELINES:\n"
      "1. **Professionalism**: Always be polite, encouraging, and professional.\n"
      "2. **Completeness**: Break down complex concepts step-by-step.\n"
      "3. **Mathematics**: Use LaTeX for ALL mathematical expressions. "
      "Use single dollar signs for inline math (e.g., \$E=mc^2\$) and double dollar signs for block math (e.g., \$\$ \\int_0^\\infty e^{-x^2} dx \$\$).\n"
      "4. **Formatting**: Use Markdown headers, lists, and bold text.";

  DeepSeekService() {
    _history.add({"role": "system", "content": _systemPrompt});
  }

  final List<Map<String, String>> _history = [];

  @override
  void updateHistory(List<AIChatMessage> history) {
    _history.clear();
    _history.add({"role": "system", "content": _systemPrompt});
    for (var msg in history) {
      _history.add({
        "role": msg.isUser ? "user" : "assistant",
        "content":
            msg.text, // Simplified for now, processing attachments on send
      });
    }
  }

  @override
  void resetChat() {
    _history.clear();
    _history.add({"role": "system", "content": _systemPrompt});
  }

  @override
  Future<String> sendMessage(
    String message, {
    List<dynamic>? attachments,
  }) async {
    if (_apiKey.isEmpty) {
      return "Error: DeepSeek API Key is not configured in .env file.";
    }
    final userContent = await _processContent(message, attachments);
    _history.add({"role": "user", "content": userContent});

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          "model": _modelName,
          "messages": _history,
          "stream": false,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;
        _history.add({"role": "assistant", "content": content});
        return content;
      } else {
        return "Error from DeepSeek (${response.statusCode}): ${response.body}";
      }
    } catch (e) {
      return "Error connecting to DeepSeek: $e";
    }
  }

  @override
  Stream<String> streamMessage(
    String message, {
    List<dynamic>? attachments,
  }) async* {
    if (_apiKey.isEmpty) {
      yield "Error: DeepSeek API Key is not configured.";
      return;
    }
    final userContent = await _processContent(message, attachments);
    _history.add({"role": "user", "content": userContent});

    final request = http.Request('POST', Uri.parse(_baseUrl));
    request.headers.addAll({
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_apiKey',
    });
    request.body = jsonEncode({
      "model": _modelName,
      "messages": _history,
      "stream": true,
    });

    try {
      final response = await http.Client().send(request);

      if (response.statusCode != 200) {
        final errorBody = await response.stream.bytesToString();
        yield "Error: ${response.statusCode} - $errorBody";
        return;
      }

      String fullContent = "";

      await for (final chunk
          in response.stream
              .transform(utf8.decoder)
              .transform(const LineSplitter())) {
        if (chunk.startsWith('data: ')) {
          final dataStr = chunk.substring(6).trim();
          if (dataStr == '[DONE]') break;

          try {
            final json = jsonDecode(dataStr);
            final delta = json['choices'][0]['delta']['content'] ?? "";
            fullContent += delta;
            yield delta;
          } catch (_) {}
        }
      }

      _history.add({"role": "assistant", "content": fullContent});
    } catch (e) {
      yield "Streaming error: $e";
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
Create a balanced and motivating study plan.
TASKS: $taskContext
EXAMS: $examContext
Provide:
1. Prioritized focus list.
2. Hourly schedule.
3. Focused study tips.
""";
    return sendMessage(prompt);
  }

  @override
  Future<String> generateQuiz(String sourceText) async {
    final prompt =
        """
Generate a 5-question multiple-choice quiz from this text:
$sourceText
Format ONLY as JSON:
{"questions": [{"question": "...", "options": ["A", "B", "C", "D"], "answer": "correct_option"}]}
""";
    return sendMessage(prompt);
  }

  @override
  Future<String> summarizePdf(dynamic pdfSource) async {
    String text = "";
    if (pdfSource is Uint8List) {
      text = await _extractTextFromPdf(pdfSource);
    } else {
      return "Invalid PDF source type.";
    }

    final prompt =
        """
Summarize this academic document:
$text
Provide:
1. Concise overview.
2. Key terms.
3. 3-5 takeaways.
""";
    return sendMessage(prompt);
  }

  Future<String> summarizeText(String text) async {
    final prompt =
        """
Summarize this text:
$text
""";
    return sendMessage(prompt);
  }

  Future<String> _processContent(
    String message,
    List<dynamic>? attachments,
  ) async {
    if (attachments == null || attachments.isEmpty) return message;

    String extraText = "";
    for (var attachment in attachments) {
      if (attachment is Uint8List) {
        // Assume PDF for now as that's the current usage
        extraText +=
            "\n\n[Extracted from PDF]:\n${await _extractTextFromPdf(attachment)}";
      }
    }
    return "$message\n$extraText";
  }

  Future<String> _extractTextFromPdf(Uint8List bytes) async {
    try {
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      final String text = PdfTextExtractor(document).extractText();
      document.dispose();
      return text;
    } catch (e) {
      return "Error extracting text: $e";
    }
  }
}
