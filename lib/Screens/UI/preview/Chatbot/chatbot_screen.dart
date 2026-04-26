import 'dart:async';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:go_study/Screens/Shared/animations.dart';
import 'package:go_study/Screens/Shared/constanst.dart';
// import 'package:go_study/services/gemini_service.dart'; // No longer used
import 'package:go_study/Screens/Shared/premium_dialog.dart';
import 'package:go_study/services/ai_service.dart';
import 'package:go_study/services/ai_sync_service.dart';
import 'package:go_study/services/deepseek_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:markdown_widget/markdown_widget.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

// import 'package:google_generative_ai/google_generative_ai.dart'
//    show DataPart, Content, TextPart;

class ChatbotScreen extends StatefulWidget {
  final AIService? aiService;
  final AISyncService? syncService;

  const ChatbotScreen({super.key, this.aiService, this.syncService});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  late final AIService _aiService;
  late final AISyncService _syncService;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatSession> _sessions = [];
  int? _currentSessionIndex;
  bool _isLoading = false;
  StreamSubscription? _aiSubscription;
  List<PlatformFile> _selectedFiles = [];

  List<ChatMessage> get _messages => _currentSessionIndex != null
      ? _sessions[_currentSessionIndex!].messages
      : [];

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      allowMultiple: true,
      withData: true,
    );

    if (result != null) {
      setState(() {
        _selectedFiles.addAll(result.files);
      });
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  @override
  void initState() {
    super.initState();
    _aiService = widget.aiService ?? DeepSeekService();
    _syncService = widget.syncService ?? AISyncService();
    _loadSessionsFromBackend();
  }

  Future<void> _loadSessionsFromBackend() async {
    try {
      final sessions = await _syncService.loadSessions();
      if (mounted) {
        setState(() {
          _sessions.clear();
          _sessions.addAll(sessions);
          if (_sessions.isNotEmpty) {
            _currentSessionIndex = 0;
          }
        });
      }
    } catch (e) {
      debugPrint("Error loading sessions: $e");
      // Optional: show a snackbar or subtle error indicator
    }
  }

  @override
  void dispose() {
    _aiSubscription?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _stopAIResponse() {
    _aiSubscription?.cancel();
    setState(() {
      _isLoading = false;
    });
    // Add logic to save truncated message if needed
    if (_messages.isNotEmpty && !_messages.last.isUser) {
      final currentSession = _sessions[_currentSessionIndex!];
      _syncService
          .saveMessage(currentSession.id, _messages.last)
          .catchError((e) => debugPrint("Sync Error (Stop): $e"));
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // Cloud Sync: Session (Don't let it block the UI/AI flow)
    if (_currentSessionIndex == null) {
      final newSession = ChatSession(
        title: text.length > 30 ? "${text.substring(0, 30)}..." : text,
        messages: [],
      );
      setState(() {
        _sessions.add(newSession);
        _currentSessionIndex = _sessions.length - 1;
      });
      try {
        await _syncService.saveSession(newSession);
      } catch (e) {
        debugPrint("Sync Error (Session): $e");
      }
    }

    final attachmentModels = _selectedFiles.map((file) {
      return ChatAttachment(
        name: file.name,
        mimeType: file.extension == 'pdf'
            ? 'application/pdf'
            : 'image/${file.extension}',
        bytes: file.bytes!,
      );
    }).toList();

    final userMessage = ChatMessage(
      text: text,
      isUser: true,
      attachments: attachmentModels.isNotEmpty ? attachmentModels : null,
    );

    final aiResponsePlaceholder = ChatMessage(text: "", isUser: false);
    _controller.clear();
    setState(() {
      _selectedFiles = [];
      _messages.add(userMessage);
      _messages.add(aiResponsePlaceholder); // Placeholder for AI response
      _isLoading = true;
    });

    // Cloud Sync: User Message
    final currentSession = _sessions[_currentSessionIndex!];
    _syncService
        .saveMessage(currentSession.id, userMessage)
        .catchError((e) => debugPrint("Sync Error (User Msg): $e"));

    _scrollToBottom();

    // Streaming Logic
    try {
      String fullResponse = "";
      bool hasError = false;

      _aiSubscription = _aiService
          .streamMessage(
            text,
            attachments: userMessage.attachments
                ?.map((e) => AIAttachment(e.mimeType, e.bytes))
                .toList(),
          )
          .listen(
            (chunk) {
              if (!mounted) return;

              if (chunk.startsWith("Error:")) {
                fullResponse = chunk;
                hasError = true;
                _stopAIResponse();
                return;
              }

              fullResponse += chunk;
              setState(() {
                final index = _messages.indexWhere(
                  (m) => m.id == aiResponsePlaceholder.id,
                );
                if (index != -1) {
                  _messages[index] = ChatMessage(
                    id: aiResponsePlaceholder.id,
                    text: fullResponse,
                    isUser: false,
                    isError: hasError,
                    thinking:
                        "I'm analyzing your request and processing the information to provide a comprehensive answer...",
                    createdAt: aiResponsePlaceholder.createdAt,
                  );
                }
              });
              _scrollToBottom();
            },
            onError: (e) {
              if (!mounted) return;
              setState(() {
                final index = _messages.indexOf(aiResponsePlaceholder);
                final errorMessage = ChatMessage(
                  id: index != -1 ? aiResponsePlaceholder.id : null,
                  text: "Sorry, I encountered an error: $e",
                  isUser: false,
                  isError: true,
                  createdAt: index != -1
                      ? aiResponsePlaceholder.createdAt
                      : null,
                );
                if (index != -1) {
                  _messages[index] = errorMessage;
                } else {
                  _messages.add(errorMessage);
                }
                _isLoading = false;
                _syncService
                    .saveMessage(currentSession.id, errorMessage)
                    .catchError(
                      (k) => debugPrint("Sync Error (Error Msg): $k"),
                    );
              });
            },
            onDone: () {
              if (!mounted) return;
              final index = _messages.indexWhere(
                (m) => m.id == aiResponsePlaceholder.id,
              );
              if (index != -1) {
                final finalMessage = ChatMessage(
                  id: aiResponsePlaceholder.id,
                  text: fullResponse,
                  isUser: false,
                  isError: hasError,
                  thinking:
                      "I'm analyzing your request and processing the information to provide a comprehensive answer...",
                  createdAt: aiResponsePlaceholder.createdAt,
                );
                setState(() {
                  _messages[index] = finalMessage;
                  _isLoading = false;
                });
                // Cloud Sync: AI Response
                _syncService
                    .saveMessage(currentSession.id, finalMessage)
                    .catchError((e) => debugPrint("Sync Error (AI Msg): $e"));
              } else {
                setState(() {
                  _isLoading = false;
                });
              }
              _aiSubscription = null;
            },
          );
    } catch (e) {
      if (!mounted) return;
      final errorMessage = ChatMessage(
        text: "Sorry, I encountered a critical error: $e",
        isUser: false,
        isError: true,
      );
      setState(() {
        _messages.last = errorMessage;
        _isLoading = false;
      });
      _syncService
          .saveMessage(currentSession.id, errorMessage)
          .catchError((k) => debugPrint("Sync Error (Error Msg): $k"));
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final position = _scrollController.position;
        if (position.maxScrollExtent - position.pixels < 200 ||
            (_messages.isNotEmpty && _messages.last.isUser)) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
          );
        }
      }
    });
  }

  void _createNewChat() {
    _aiService.resetChat();
    setState(() {
      _currentSessionIndex = null;
      _controller.clear();
    });
  }

  void _loadSession(int index) {
    setState(() {
      _currentSessionIndex = index;
    });
    _syncAIHistory();
    Navigator.pop(context); // Close drawer
  }

  void _syncAIHistory() {
    if (_currentSessionIndex == null) return;
    final session = _sessions[_currentSessionIndex!];
    final history = session.messages.map((msg) {
      return AIChatMessage(
        text: msg.text,
        isUser: msg.isUser,
        attachments: msg.attachments
            ?.map((e) => AIAttachment(e.mimeType, e.bytes))
            .toList(),
      );
    }).toList();
    _aiService.updateHistory(history);
  }

  Future<void> _deleteSession(int index) async {
    final session = _sessions[index];
    final confirm = await showPremiumGeneralDialog<bool>(
      context: context,
      barrierLabel: "Delete Chat",
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF0F172A)
            : Colors.white,
        surfaceTintColor: Colors.transparent,
        contentPadding: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PremiumDialogHeader(
              title: "Delete Chat",
              subtitle: "This action cannot be undone",
              icon: Icons.delete_outline_rounded,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                children: [
                  Text(
                    "Are you sure you want to delete this conversation? All messages will be permanently removed.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(
                            "Cancel",
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: PremiumSubmitButton(
                          label: "Delete Now",
                          isLoading: false,
                          onPressed: () => Navigator.pop(context, true),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      await _syncService.deleteSession(session.id);
      setState(() {
        _sessions.removeAt(index);
        if (_currentSessionIndex == index) {
          _currentSessionIndex = null;
        } else if (_currentSessionIndex != null &&
            _currentSessionIndex! > index) {
          _currentSessionIndex = _currentSessionIndex! - 1;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userModel = Provider.of<UserModel>(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        leadingWidth: 48,
        leading: Builder(
          builder: (context) => Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        ),
        title: Text(
          "AI Assistant",
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurface,
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor.withOpacity(0.7),
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              backgroundImage: userModel.avatarUrl != null
                  ? CachedNetworkImageProvider(userModel.avatarUrl!)
                  : null,
              child: userModel.avatarUrl == null
                  ? Icon(
                      Icons.person_outline_rounded,
                      size: 20,
                      color: theme.colorScheme.primary,
                    )
                  : null,
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(theme),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState(theme)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      // Show typing indicator only if it's the last message, it's NOT user, and text is empty (waiting for first chunk)
                      if (!msg.isUser && msg.text.isEmpty && _isLoading) {
                        return const _TypingIndicator();
                      }

                      return FadeInSlide(
                        key: ValueKey(msg.id),
                        // Reduced delay for faster chat feel
                        delay: 0,
                        child: _MessageBubble(
                          message: msg,
                          isStreaming:
                              _isLoading && index == _messages.length - 1,
                        ),
                      );
                    },
                  ),
          ),
          _buildInputArea(theme),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return SingleChildScrollView(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF4285F4), Color(0xFF9B72F3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: 80,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "How can I help you today?",
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.w400,
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 48),
            _buildQuickStarters(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStarters(ThemeData theme) {
    final starters = [
      "📈 Help me with calculus",
      "📝 Write a study plan",
      "💡 Project ideas",
      "📚 Summarize notes",
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: starters.map((text) {
        return ScaleButton(
          onTap: () {
            _controller.text = text.substring(2); // Remove emoji
            _sendMessage();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              text,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInputArea(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final pillColor = isDark ? const Color(0xFF1E1F20) : Colors.grey[100];
    final textColor = theme.colorScheme.onSurface;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor.withOpacity(0.8),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.05),
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isLoading)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: pillColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.08)
                            : Colors.black.withOpacity(0.05),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF4285F4),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Thinking",
                          style: GoogleFonts.outfit(
                            color: textColor.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 1,
                          height: 12,
                          color: textColor.withOpacity(0.1),
                        ),
                        const SizedBox(width: 4),
                        TextButton.icon(
                          onPressed: _stopAIResponse,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: Icon(
                            Icons.stop_circle_rounded,
                            size: 16,
                            color: Colors.red.shade400,
                          ),
                          label: Text(
                            "Stop",
                            style: GoogleFonts.outfit(
                              color: Colors.red.shade400,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_selectedFiles.isNotEmpty) _buildFilePreview(theme),
              Container(
                padding: EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  MediaQuery.of(context).orientation == Orientation.landscape
                      ? 8
                      : 24,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: pillColor,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.08)
                          : Colors.black.withOpacity(0.05),
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.add_circle_outline_rounded,
                          color: textColor.withOpacity(0.6),
                        ),
                        onPressed: _pickFiles,
                      ),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          textCapitalization: TextCapitalization.sentences,
                          keyboardType: TextInputType.multiline,
                          maxLines: 10,
                          minLines: 1,
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            color: textColor,
                          ),
                          decoration: InputDecoration(
                            hintText: "Ask AI",
                            hintStyle: GoogleFonts.outfit(
                              color: textColor.withOpacity(0.4),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 8,
                            ),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.send,
                          color: theme.colorScheme.primary,
                          size: 26,
                        ),
                        onPressed: _sendMessage,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilePreview(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedFiles.length,
        itemBuilder: (context, index) {
          final file = _selectedFiles[index];
          final isImage = [
            'jpg',
            'jpeg',
            'png',
          ].contains(file.extension?.toLowerCase());

          return Container(
            margin: const EdgeInsets.only(right: 8),
            width: 70,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                Center(
                  child: isImage
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            file.bytes!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(
                          Icons.picture_as_pdf_rounded,
                          color: Colors.red,
                          size: 30,
                        ),
                ),
                Positioned(
                  top: 2,
                  right: 2,
                  child: GestureDetector(
                    onTap: () => _removeFile(index),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDrawer(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Drawer(
      backgroundColor: theme.scaffoldBackgroundColor,
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.03)
                  : Colors.black.withOpacity(0.03),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFF4285F4), Color(0xFF9B72F3)],
                    ).createShader(bounds),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "AI Assistant",
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ScaleButton(
              onTap: () {
                _createNewChat();
                Navigator.pop(context);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, color: theme.colorScheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      "New Chat",
                      style: GoogleFonts.outfit(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: _sessions.isEmpty
                ? Center(
                    child: Text(
                      "No recent chats",
                      style: GoogleFonts.outfit(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                        fontSize: 14,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _sessions.length,
                    itemBuilder: (context, index) {
                      final session = _sessions[index];
                      final isSelected = _currentSessionIndex == index;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: InkWell(
                          onTap: () => _loadSession(index),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.colorScheme.primary.withOpacity(0.08)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 18,
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurface.withOpacity(
                                          0.5,
                                        ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    session.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      color: isSelected
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.onSurface,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.delete_outline_rounded,
                                    size: 18,
                                    color: isSelected
                                        ? theme.colorScheme.primary.withOpacity(
                                            0.6,
                                          )
                                        : theme.colorScheme.onSurface
                                              .withOpacity(0.3),
                                  ),
                                  onPressed: () => _deleteSession(index),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const Divider(),
          ListTile(
            leading: Icon(
              Icons.delete_outline_rounded,
              color: Colors.red.shade400,
            ),
            title: Text(
              "Clear all chats",
              style: GoogleFonts.outfit(
                color: Colors.red.shade400,
                fontSize: 14,
              ),
            ),
            onTap: () async {
              final confirm = await showPremiumGeneralDialog<bool>(
                context: context,
                barrierLabel: "Clear All Chats",
                child: AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                  backgroundColor:
                      Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF0F172A)
                      : Colors.white,
                  surfaceTintColor: Colors.transparent,
                  contentPadding: EdgeInsets.zero,
                  clipBehavior: Clip.antiAlias,
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const PremiumDialogHeader(
                        title: "Clear All Chats",
                        subtitle: "Start with a clean slate",
                        icon: Icons.auto_awesome_rounded,
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                        child: Column(
                          children: [
                            Text(
                              "Are you sure you want to delete all conversations? This action will permanently remove your entire chat history.",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                color:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white70
                                    : Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: Text(
                                      "Cancel",
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: PremiumSubmitButton(
                                    label: "Clear All",
                                    isLoading: false,
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );

              if (confirm == true) {
                await _syncService.clearAllSessions();
                setState(() {
                  _sessions.clear();
                  _currentSessionIndex = null;
                });
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final bool isError;
  final String? thinking;
  bool showThinking;
  final List<ChatAttachment>? attachments;
  final DateTime createdAt;

  ChatMessage({
    String? id,
    required this.text,
    required this.isUser,
    this.isError = false,
    this.thinking,
    this.showThinking = false,
    this.attachments,
    DateTime? createdAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      text: json['text'],
      isUser: json['is_user'],
      isError: json['is_error'] ?? false,
      thinking: json['thinking'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson(String sessionId, String userId) {
    return {
      'id': id,
      'session_id': sessionId,
      'user_id': userId,
      'text': text,
      'is_user': isUser,
      'is_error': isError,
      'thinking': thinking,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class ChatSession {
  final String id;
  final String title;
  final List<ChatMessage> messages;
  final DateTime createdAt;

  ChatSession({
    String? id,
    required this.title,
    required this.messages,
    DateTime? createdAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  factory ChatSession.fromJson(
    Map<String, dynamic> json,
    List<ChatMessage> messages,
  ) {
    return ChatSession(
      id: json['id'],
      title: json['title'],
      messages: messages,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson(String userId) {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class ChatAttachment {
  final String name;
  final String mimeType;
  final Uint8List bytes;

  ChatAttachment({
    required this.name,
    required this.mimeType,
    required this.bytes,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'mime_type': mimeType,
      // We usually don't save bytes to the message log to avoid massive DB rows.
      // In a real app, you'd upload these to storage and save the URL.
    };
  }
}

class _MessageBubble extends StatefulWidget {
  final ChatMessage message;
  final bool isStreaming;

  const _MessageBubble({required this.message, required this.isStreaming});

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble> {
  late bool _showThinking;

  @override
  void initState() {
    super.initState();
    _showThinking = widget.message.showThinking;
  }

  @override
  void didUpdateWidget(_MessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.message.id != oldWidget.message.id) {
      _showThinking = widget.message.showThinking;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isUser = widget.message.isUser;
    final onSurface = theme.colorScheme.onSurface;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          mainAxisAlignment: isUser
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isUser) ...[
              Padding(
                padding: const EdgeInsets.only(
                  left: 2.0,
                  right: 4.0,
                  bottom: 2,
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: 20,
                  color: Colors.blue.shade400,
                ),
              ),
            ],
            Flexible(
              child: Column(
                crossAxisAlignment: isUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    constraints: BoxConstraints(
                      maxWidth:
                          MediaQuery.of(context).size.width *
                          (isUser ? 0.75 : 0.85),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: isUser ? 20 : 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isUser
                          ? (isDark
                                ? const Color(0xFF2F2F2F)
                                : theme.colorScheme.primary)
                          : (widget.message.isError
                                ? Colors.red.withOpacity(0.05)
                                : Colors.transparent),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(24),
                        topRight: const Radius.circular(24),
                        bottomLeft: Radius.circular(isUser ? 24 : 0),
                        bottomRight: Radius.circular(isUser ? 0 : 24),
                      ),
                      border: !isUser && widget.message.isError
                          ? Border.all(
                              color: Colors.red.withOpacity(0.2),
                              width: 1,
                            )
                          : null,
                    ),
                    child: isUser
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (widget.message.attachments != null)
                                _buildAttachmentDisplay(
                                  widget.message.attachments!,
                                  true,
                                ),
                              Text(
                                widget.message.text,
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 18,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (widget.message.thinking != null) ...[
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _showThinking = !_showThinking;
                                      widget.message.showThinking =
                                          _showThinking;
                                    });
                                  },
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.auto_awesome_outlined,
                                        size: 20,
                                        color: Color(0xFF4285F4),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Show Thinking",
                                        style: GoogleFonts.outfit(
                                          color: onSurface.withOpacity(0.8),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                      Icon(
                                        _showThinking
                                            ? Icons.keyboard_arrow_up
                                            : Icons.keyboard_arrow_down,
                                        size: 20,
                                        color: onSurface.withOpacity(0.4),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_showThinking)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      top: 8,
                                      bottom: 16,
                                    ),
                                    child: Text(
                                      widget.message.thinking!,
                                      style: GoogleFonts.outfit(
                                        color: onSurface.withOpacity(0.5),
                                        fontSize: 14,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 12),
                              ],
                              if (widget.message.attachments != null)
                                _buildAttachmentDisplay(
                                  widget.message.attachments!,
                                  false,
                                ),
                              MarkdownBlock(
                                data: widget.message.text,
                                config: MarkdownConfig(
                                  configs: [
                                    PConfig(
                                      textStyle: GoogleFonts.outfit(
                                        color: widget.message.isError
                                            ? Colors.red.shade400
                                            : onSurface,
                                        fontSize: 18,
                                        height: 1.6,
                                      ),
                                    ),
                                    TableConfig(
                                      wrapper: (child) => SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: child,
                                      ),
                                    ),
                                    PreConfig(
                                      wrapper: (child, code, language) =>
                                          _CodeBlockWrapper(
                                            code: code,
                                            language: language,
                                            child: child,
                                          ),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? Colors.white.withOpacity(0.05)
                                            : Colors.black.withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: onSurface.withOpacity(0.1),
                                        ),
                                      ),
                                      padding: const EdgeInsets.all(16),
                                    ),
                                  ],
                                ),
                                generator: MarkdownGenerator(
                                  generators: [latexGenerator],
                                  inlineSyntaxList: [LatexSyntax()],
                                ),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      DateFormat('HH:mm').format(widget.message.createdAt),
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: isDark ? Colors.white30 : Colors.grey[400],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentDisplay(
    List<ChatAttachment> attachments,
    bool isUser,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: attachments.map((file) {
        final isImage = file.mimeType.startsWith('image/');

        return Container(
          width: 150,
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isImage)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: Image.memory(
                    file.bytes,
                    height: 100,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Container(
                  height: 100,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                  child: const Icon(
                    Icons.picture_as_pdf_rounded,
                    color: Colors.red,
                    size: 40,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  file.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final delay = index * 0.2;
                final value = Curves.easeInOut.transform(
                  ((_controller.value + delay) % 1.0),
                );
                return Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.primary.withOpacity(
                      0.3 + (value * 0.7),
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }
}

/// A LaTeX generator for [MarkdownWidget]
final latexGenerator = SpanNodeGeneratorWithTag(
  tag: 'latex',
  generator: (e, config, visitor) =>
      LatexNode(e.attributes['content'] ?? '', config),
);

class LatexNode extends SpanNode {
  final String content;
  final MarkdownConfig config;

  LatexNode(this.content, this.config);

  @override
  InlineSpan build() {
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Material(
        color: Colors.transparent,
        child: Math.tex(
          content,
          mathStyle: MathStyle.text,
          textStyle: config.p.textStyle,
          onErrorFallback: (err) => Text(
            content,
            style: config.p.textStyle.copyWith(color: Colors.red),
          ),
        ),
      ),
    );
  }
}

class LatexSyntax extends md.InlineSyntax {
  LatexSyntax() : super(r'(\$\$?)([\s\S]+?)\1');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final content = match.group(2) ?? '';
    parser.addNode(
      md.Element.withTag('latex')..attributes['content'] = content,
    );
    return true;
  }
}

class _CodeBlockWrapper extends StatelessWidget {
  final Widget child;
  final String code;
  final String language;

  const _CodeBlockWrapper({
    required this.child,
    required this.code,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                language.toUpperCase(),
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: code));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Code copied to clipboard"),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Icon(
                      Icons.copy_rounded,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "Copy",
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: child),
      ],
    );
  }
}
