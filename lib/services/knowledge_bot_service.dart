import 'package:go_study/services/gemini_client.dart';
import 'package:go_study/services/gemini_service.dart';

const String _kSystemPersona = """
You are the official 'UB Support Bot', a dedicated customer service assistant for the University of Buea.
Your goal is to provide helpful, professional, and accurate information to students, staff, and visitors about the university.

IMPORTANT: You must answer questions based ONLY on the CONTEXT provided in each message.

GUIDELINES:
1. Persona: Be professional, welcoming, and helpful, as if you are a real staff member at the UB registry or student affairs.
2. Accuracy: Use ONLY the information in the CONTEXT you're given.
3. Missing Info: If the answer is not in the context, politely say: "I'm sorry, I don't have that specific information about the University of Buea in my database yet. You may want to check the official UB website or visit the relevant department."
4. Do not mention that you are an AI or that you have a "context". Just answer as the UB Support Bot.
5. Format: Use clear, polite language. Use bullet points if necessary.
""";

/// Answers questions from a single shared knowledge document (see
/// DatabaseService.getSharedBotKnowledge) — every user's Support Bot reads
/// the exact same text, so there is no per-user relevance ranking to do;
/// the whole document is passed as context on every question.
class KnowledgeBotService {
  // Stateless per-question client: each question is an independent
  // retrieval-augmented lookup, not a multi-turn conversation, so there's
  // no reason to accumulate/replay chat history across questions. The
  // persona lives in systemInstruction (sent once per call, not re-embedded
  // in every message body).
  final GeminiService _geminiService;

  KnowledgeBotService({GeminiService? geminiService})
    : _geminiService =
          geminiService ??
          GeminiService(client: GeminiProxyOneShotClient(_kSystemPersona));

  Stream<String> streamQuestion(String question, String knowledge) async* {
    if (knowledge.trim().isEmpty) {
      yield "Hello! I am the University of Buea Support Bot. The knowledge base hasn't been set up yet — please check back soon!";
      return;
    }

    final prompt =
        """
CONTEXT:
$knowledge

USER QUESTION:
$question
""";

    yield* _geminiService.streamMessage(prompt);
  }
}
