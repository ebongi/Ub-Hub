import 'package:go_study/services/gemini_service.dart';
import 'package:go_study/services/bot_knowledge.dart';
import 'package:go_study/services/ai_service.dart';

class KnowledgeBotService {
  final GeminiService _geminiService = GeminiService();

  Future<String> askQuestion(String question, List<BotKnowledge> knowledge) async {
    if (knowledge.isEmpty) {
      return "Hello! I am the University of Buea Customer Support Bot. I don't have any specific UB information loaded yet. Please add some university details to my knowledge base so I can help you!";
    }

    // Smart Retrieval: Only send the most relevant snippets to save tokens
    final relevantKnowledge = _getRelevantSnippets(question, knowledge);
    final context = relevantKnowledge
        .map((k) => "### ${k.title}\n${k.content}")
        .join("\n\n");

    final prompt = """
You are the official 'UB Support Bot', a dedicated customer service assistant for the University of Buea. 
Your goal is to provide helpful, professional, and accurate information to students, staff, and visitors about the university.

IMPORTANT: You must answer questions based ONLY on the provided CONTEXT below.

CONTEXT:
$context

USER QUESTION:
$question

GUIDELINES:
1. Persona: Be professional, welcoming, and helpful, as if you are a real staff member at the UB registry or student affairs.
2. Accuracy: Use ONLY the information in the CONTEXT above. 
3. Missing Info: If the answer is not in the context, politely say: "I'm sorry, I don't have that specific information about the University of Buea in my database yet. You may want to check the official UB website or visit the relevant department."
4. Do not mention that you are an AI or that you have a "context". Just answer as the UB Support Bot.
5. Format: Use clear, polite language. Use bullet points if necessary.
""";

    return _geminiService.sendMessage(prompt);
  }

  Stream<String> streamQuestion(String question, List<BotKnowledge> knowledge) async* {
    if (knowledge.isEmpty) {
      yield "Hello! I am the University of Buea Support Bot. Please add some knowledge snippets first!";
      return;
    }

    final relevantKnowledge = _getRelevantSnippets(question, knowledge);
    final context = relevantKnowledge
        .map((k) => "### ${k.title}\n${k.content}")
        .join("\n\n");

    final prompt = """
You are the official 'UB Support Bot', a dedicated customer service assistant for the University of Buea. 
Your goal is to provide helpful, professional, and accurate information to students, staff, and visitors.

IMPORTANT: Answer based ONLY on the provided CONTEXT.

CONTEXT:
$context

USER QUESTION:
$question

GUIDELINES:
1. Persona: Professional, welcoming staff member.
2. Accuracy: Use ONLY the provided CONTEXT.
3. Missing Info: If not in context, say: "I'm sorry, I don't have that specific information about UB yet."
4. Be direct and polite.
""";

    yield* _geminiService.streamMessage(prompt);
  }

  /// Simple keyword-based relevance ranking to find the best context
  List<BotKnowledge> _getRelevantSnippets(String query, List<BotKnowledge> allKnowledge) {
    if (allKnowledge.length <= 5) return allKnowledge;

    final queryWords = query.toLowerCase().split(RegExp(r'\W+')).where((w) => w.length > 3).toSet();
    
    // Sort knowledge by how many query words they contain
    final scoredKnowledge = allKnowledge.map((k) {
      final content = (k.title + " " + k.content).toLowerCase();
      int score = 0;
      for (final word in queryWords) {
        if (content.contains(word)) score++;
      }
      return _ScoredKnowledge(k, score);
    }).toList();

    scoredKnowledge.sort((a, b) => b.score.compareTo(a.score));

    // Return top 5 most relevant snippets
    return scoredKnowledge.take(5).map((sk) => sk.knowledge).toList();
  }
}

class _ScoredKnowledge {
  final BotKnowledge knowledge;
  final int score;
  _ScoredKnowledge(this.knowledge, this.score);
}
