import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_study/services/database.dart';
import 'package:go_study/services/bot_knowledge.dart';
import 'package:go_study/services/knowledge_bot_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_study/Screens/Shared/animations.dart';
import 'package:go_study/Screens/Shared/constanst.dart';
import 'package:go_study/Screens/Shared/ai_usage_gate.dart';
import 'package:go_study/services/profile.dart';
import 'package:provider/provider.dart';
import 'package:go_study/Screens/UI/preview/Toolbox/knowledge_manager_screen.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class KnowledgeBotChatScreen extends StatefulWidget {
  const KnowledgeBotChatScreen({super.key});

  @override
  State<KnowledgeBotChatScreen> createState() => _KnowledgeBotChatScreenState();
}

class _KnowledgeBotChatScreenState extends State<KnowledgeBotChatScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  late final DatabaseService _dbService;
  final _botService = KnowledgeBotService();
  final _currentUser = Supabase.instance.client.auth.currentUser;
  List<BotKnowledge> _knowledgeBase = [];

  @override
  void initState() {
    super.initState();
    _dbService = DatabaseService(uid: _currentUser?.id);
    _loadKnowledge();
    _messages.add({
      'id': 'welcome',
      'text': "Welcome to the University of Buea Support Center! I am your UB Support Bot. How can I help you with university-related inquiries today?",
      'isBot': true,
    });
  }

  void _loadKnowledge() {
    _dbService.getBotKnowledge(_currentUser!.id).listen((data) {
      if (mounted) setState(() => _knowledgeBase = data);
    });
  }

  void _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isLoading) return;

    final userModel = Provider.of<UserModel>(context, listen: false);
    final profile = UserProfile(
      id: userModel.uid ?? '',
      name: userModel.name,
      aiCredits: userModel.aiCredits,
      subscriptionTier: userModel.subscriptionTier,
      subscriptionExpiry: userModel.subscriptionExpiry,
      role: userModel.role,
    );

    final canProceed = await AIUsageGate.checkAndShow(context, profile);
    if (!canProceed) return;

    final userMsgId = "user_${DateTime.now().millisecondsSinceEpoch}";
    final botMsgId = "bot_${DateTime.now().millisecondsSinceEpoch}";

    setState(() {
      _messages.add({
        'id': userMsgId,
        'text': text,
        'isBot': false,
      });
      _isLoading = true;
      _inputController.clear();
    });

    _scrollToBottom();

    try {
      // Create a unique placeholder for the bot response
      setState(() {
        _messages.add({
          'id': botMsgId,
          'text': "",
          'isBot': true,
        });
      });
      
      String fullResponse = "";
      bool firstChunk = true;

      // Start the stream
      final stream = _botService.streamQuestion(text, _knowledgeBase);
      
      await for (final chunk in stream) {
        if (chunk == "OUT_OF_CREDITS") {
          fullResponse = "OUT_OF_CREDITS";
          break;
        }
        fullResponse += chunk;
        if (mounted) {
          // Find the message by ID to be safe, as the list might have changed
          final index = _messages.indexWhere((m) => m['id'] == botMsgId);
          if (index != -1) {
            setState(() {
              _messages[index]['text'] = fullResponse;
              if (firstChunk) {
                _isLoading = false;
                firstChunk = false;
              }
            });
            _scrollToBottom();
          }
        }
      }
      
      if (fullResponse == "OUT_OF_CREDITS") {
        setState(() {
          _messages.removeWhere((m) => m['id'] == botMsgId);
          _isLoading = false;
        });
        if (mounted) AIUsageGate.checkAndShow(context, profile);
        return;
      }
      
      if (fullResponse.isEmpty) {
        throw Exception("Empty response from AI");
      }
    } catch (e) {
      debugPrint("Streaming Error: $e");
      if (mounted) {
        final index = _messages.indexWhere((m) => m['id'] == botMsgId);
        if (index != -1 && _messages[index]['text'].toString().isEmpty) {
          setState(() {
            _messages[index]['text'] = "I'm sorry, I'm having trouble connecting right now. Please check your internet or try again later.";
            _isLoading = false;
          });
        }
        _showError("Connection interrupted.");
      }
    }

    _scrollToBottom();
  }


  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "UB Support Bot",
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
            Text(
              "University of Buea Assistant",
              style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_suggest_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const KnowledgeManagerScreen()),
            ),
            tooltip: "Manage Knowledge",
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.black : Colors.grey[50],
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return _buildMessageBubble(
                    msg['text'],
                    msg['isBot'],
                    isDark,
                    msg['id'] ?? index.toString(),
                  );
                },
              ),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: LinearProgressIndicator(minHeight: 2),
              ),
            _buildInputArea(theme, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isBot, bool isDark, String key) {
    final theme = Theme.of(context);
    return FadeInSlide(
      key: ValueKey(key),
      delay: 50,
      duration: const Duration(milliseconds: 200),
      child: Align(
        alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isBot
                ? (isDark ? const Color(0xFF1E293B) : Colors.white)
                : theme.primaryColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(24),
              topRight: const Radius.circular(24),
              bottomLeft: Radius.circular(isBot ? 0 : 24),
              bottomRight: Radius.circular(isBot ? 24 : 0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
          ),
          child: isBot
              ? MarkdownBody(
                  data: text,
                  styleSheet: MarkdownStyleSheet(
                    p: GoogleFonts.outfit(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 15,
                    ),
                  ),
                )
              : Text(
                  text,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildInputArea(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: "Ask based on your data...",
                hintStyle: GoogleFonts.outfit(fontSize: 14),
                filled: true,
                fillColor: isDark ? Colors.white10 : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: theme.primaryColor,
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}
