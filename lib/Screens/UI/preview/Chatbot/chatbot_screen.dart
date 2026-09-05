import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_study/Screens/Shared/animations.dart';
import 'package:go_study/Screens/Shared/ai_usage_gate.dart';
import 'package:go_study/Screens/Shared/constanst.dart';
import 'package:go_study/Screens/Shared/premium_dialog.dart';
import 'package:go_study/Screens/UI/preview/Chatbot/widgets/assistant_background.dart';
import 'package:go_study/Screens/UI/preview/Chatbot/widgets/assistant_header.dart';
import 'package:go_study/Screens/UI/preview/Chatbot/widgets/assistant_input_bar.dart';
import 'package:go_study/Screens/UI/preview/Chatbot/widgets/assistant_message_bubble.dart';
import 'package:go_study/Screens/UI/preview/Chatbot/widgets/assistant_suggestion_chips.dart';
import 'package:go_study/Screens/UI/preview/Chatbot/widgets/assistant_welcome_card.dart';
import 'package:go_study/Screens/UI/preview/Chatbot/widgets/message_quota_pill.dart';
import 'package:go_study/l10n/generated/app_localizations.dart';
import 'package:go_study/services/profile.dart';
import 'package:go_study/services/ai_service.dart';
import 'package:go_study/services/ai_sync_service.dart';
import 'package:go_study/services/gemini_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class ChatbotScreen extends StatefulWidget {
  final AIService? aiService;
  final AISyncService? syncService;

  /// Called by the header's collapse chevron. On the AI Assistant tab this
  /// returns to the previously-selected tab (and brings the bottom nav bar
  /// back); null when the screen is hosted without a collapse affordance.
  final VoidCallback? onCollapse;

  const ChatbotScreen({
    super.key,
    this.aiService,
    this.syncService,
    this.onCollapse,
  });

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  late final AIService _aiService;
  late final AISyncService _syncService;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatSession> _sessions = [];
  int? _currentSessionIndex;
  bool _isLoading = false;
  StreamSubscription? _aiSubscription;
  List<PlatformFile> _selectedFiles = [];

  /// While a response streams, its growing text lives here instead of in a
  /// `setState` — only the one streaming bubble listens, so per-chunk updates
  /// don't rebuild the header, the input field, or the other bubbles (each of
  /// which would otherwise re-parse its markdown every ~80ms). [_streamingId]
  /// is the id of the placeholder message currently being filled.
  final ValueNotifier<String> _streamingText = ValueNotifier<String>('');
  String? _streamingId;

  /// The true accumulator for the in-flight response — updated on every
  /// chunk, unlike [_streamingText] which is throttled to ~80ms for render
  /// cost. Stopping mid-stream must finalize from this, not from
  /// [_streamingText], or the tail since the last throttled flush is lost.
  String _fullResponseBuffer = '';

  List<ChatMessage> get _messages => _currentSessionIndex != null
      ? _sessions[_currentSessionIndex!].messages
      : [];

  Future<void> _pickFiles() async {
    try {
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
    } catch (e) {
      _showErrorSnackBar("Failed to pick files: $e");
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
    _aiService = widget.aiService ?? GeminiService();
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
      if (mounted) {
        _showErrorSnackBar(AppLocalizations.of(context)!.failedToLoadChatHistory);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  void dispose() {
    _aiSubscription?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    _streamingText.dispose();
    super.dispose();
  }

  void _stopAIResponse() {
    _aiSubscription?.cancel();
    _aiSubscription = null;
    if (_streamingId != null) {
      _finalizeStreamingMessage(text: _fullResponseBuffer, isError: false);
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  /// Bakes the streamed text back into the placeholder [ChatMessage] in a
  /// single `setState`, ends the loading state, clears the streaming notifier,
  /// and syncs the final message. Idempotent — a second call (e.g. onDone
  /// racing a stop) is a no-op.
  void _finalizeStreamingMessage({required String text, required bool isError}) {
    if (!mounted) return;
    final id = _streamingId;
    if (id == null) {
      setState(() => _isLoading = false);
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    final index = _messages.indexWhere((m) => m.id == id);
    ChatMessage? finalMessage;
    setState(() {
      if (index != -1) {
        finalMessage = ChatMessage(
          id: id,
          text: text,
          isUser: false,
          isError: isError,
          thinking: l10n.aiThinkingPlaceholder,
          createdAt: _messages[index].createdAt,
        );
        _messages[index] = finalMessage!;
      }
      _isLoading = false;
      _streamingId = null;
    });
    _streamingText.value = '';
    if (finalMessage != null && _currentSessionIndex != null) {
      _syncService
          .saveMessage(_sessions[_currentSessionIndex!].id, finalMessage!)
          .catchError((e) => debugPrint("Sync Error: $e"));
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty && _selectedFiles.isEmpty) return;

    final l10n = AppLocalizations.of(context)!;
    final userModel = Provider.of<UserModel>(context, listen: false);

    // Convert UserModel to UserProfile for the gate (or update gate to accept UserModel)
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

    if (_currentSessionIndex == null) {
      final newSession = ChatSession(
        title: text.isEmpty
            ? l10n.newFileAnalysisTitle
            : (text.length > 30 ? "${text.substring(0, 30)}..." : text),
        messages: [],
      );
      setState(() {
        _sessions.add(newSession);
        _currentSessionIndex = _sessions.length - 1;
      });
      try {
        await _syncService.saveSession(newSession);
      } catch (e) {
        _showErrorSnackBar("Failed to sync new session: $e");
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
    _streamingText.value = '';
    setState(() {
      _selectedFiles = [];
      _messages.add(userMessage);
      _messages.add(aiResponsePlaceholder);
      _isLoading = true;
      _streamingId = aiResponsePlaceholder.id;
    });

    final currentSession = _sessions[_currentSessionIndex!];
    _syncService
        .saveMessage(currentSession.id, userMessage)
        .catchError((e) => _showErrorSnackBar(l10n.messageSyncFailed));

    _scrollToBottom();

    try {
      _fullResponseBuffer = "";
      // markdown_widget re-parses the ENTIRE accumulated text from scratch on
      // every rebuild (no memoization) and rebuilds every Math.tex with it.
      // Push the growing text through [_streamingText] (only the streaming
      // bubble listens) and throttle to a fixed cadence so that cost is paid
      // a bounded number of times per response, never once per token.
      var lastUiUpdate = DateTime.fromMillisecondsSinceEpoch(0);
      const uiUpdateInterval = Duration(milliseconds: 80);

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

              if (chunk.startsWith("Error:") || chunk == "OUT_OF_CREDITS") {
                if (chunk == "OUT_OF_CREDITS") {
                  _showErrorSnackBar(l10n.outOfAiCreditsMessage);
                  AIUsageGate.checkAndShow(context, profile);
                } else {
                  _showErrorSnackBar(chunk.replaceFirst("Error:", "").trim());
                }
                _aiSubscription?.cancel();
                _aiSubscription = null;
                _finalizeStreamingMessage(text: chunk, isError: true);
                return;
              }

              _fullResponseBuffer += chunk;
              final now = DateTime.now();
              if (now.difference(lastUiUpdate) < uiUpdateInterval) return;
              lastUiUpdate = now;
              _streamingText.value = _fullResponseBuffer;
              _scrollToBottom();
            },
            onError: (e) {
              if (!mounted) return;
              _showErrorSnackBar("AI Error: $e");
              _aiSubscription = null;
              _finalizeStreamingMessage(
                text: l10n.sorryEncounteredError(e.toString()),
                isError: true,
              );
            },
            onDone: () {
              if (!mounted) return;
              _aiSubscription = null;
              _finalizeStreamingMessage(text: _fullResponseBuffer, isError: false);
            },
          );
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar("Critical Error: $e");
      final errorMessage = ChatMessage(
        text: l10n.sorryEncounteredCriticalError(e.toString()),
        isUser: false,
        isError: true,
      );
      setState(() {
        _messages.last = errorMessage;
        _isLoading = false;
        _streamingId = null;
      });
      _streamingText.value = '';
      _syncService
          .saveMessage(currentSession.id, errorMessage)
          .catchError((k) => debugPrint("Sync Error: $k"));
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
    _aiSubscription?.cancel();
    _aiSubscription = null;
    _aiService.resetChat();
    _streamingText.value = '';
    setState(() {
      _currentSessionIndex = null;
      _controller.clear();
      _selectedFiles = [];
      _isLoading = false;
      _streamingId = null;
    });
  }

  void _loadSession(int index) {
    setState(() {
      _currentSessionIndex = index;
    });
    _syncAIHistory();
    Navigator.pop(context);
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
    final l10n = AppLocalizations.of(context)!;
    final session = _sessions[index];
    final confirm = await showPremiumGeneralDialog<bool>(
      context: context,
      barrierLabel: l10n.deleteChatDialogTitle,
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
            PremiumDialogHeader(
              title: l10n.deleteChatDialogTitle,
              subtitle: l10n.deleteChatDialogSubtitle,
              icon: Icons.delete_outline_rounded,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                children: [
                  Text(
                    l10n.deleteChatConfirmBody,
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
                            l10n.cancel,
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
                          label: l10n.deleteNowButton,
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
      try {
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
      } catch (e) {
        _showErrorSnackBar("Failed to delete chat: $e");
      }
    }
  }

  Future<void> _confirmClearAll() async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showPremiumGeneralDialog<bool>(
      context: context,
      barrierLabel: l10n.clearAllChatsDialogTitle,
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
            PremiumDialogHeader(
              title: l10n.clearAllChatsDialogTitle,
              subtitle: l10n.clearAllChatsDialogSubtitle,
              icon: Icons.auto_awesome_rounded,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                children: [
                  Text(
                    l10n.clearAllChatsConfirmBody,
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
                            l10n.cancel,
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
                          label: l10n.clearAllButton,
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
      try {
        await _syncService.clearAllSessions();
        setState(() {
          _sessions.clear();
          _currentSessionIndex = null;
        });
        if (mounted && (_scaffoldKey.currentState?.isDrawerOpen ?? false)) {
          Navigator.pop(context);
        }
      } catch (e) {
        _showErrorSnackBar("Failed to clear chats: $e");
      }
    }
  }

  void _onMenuSelected(String value) {
    switch (value) {
      case 'new':
        _createNewChat();
        break;
      case 'history':
        _scaffoldKey.currentState?.openDrawer();
        break;
      case 'clear':
        _confirmClearAll();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userModel = Provider.of<UserModel>(context);
    final l10n = AppLocalizations.of(context)!;
    final unlimited =
        userModel.role == UserRole.admin || userModel.hasUnlimitedAI;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: _buildDrawer(theme, l10n),
      body: AssistantBackground(
        child: SafeArea(
          child: Column(
            children: [
              AssistantHeader(
                title: l10n.aiAssistantTitle,
                status: l10n.assistantStatusActive,
                onRestart: _createNewChat,
                onCollapse: widget.onCollapse,
                onMenuSelected: _onMenuSelected,
                menuItems: [
                  PopupMenuItem(
                    value: 'new',
                    child: Text(l10n.newChatButton),
                  ),
                  PopupMenuItem(
                    value: 'history',
                    child: Text(l10n.assistantChatHistoryLabel),
                  ),
                  PopupMenuItem(
                    value: 'clear',
                    child: Text(l10n.clearAllChatsListTile),
                  ),
                ],
              ),
              Expanded(
                child: _messages.isEmpty
                    ? _buildEmptyState(l10n, userModel.aiCredits, unlimited)
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        itemCount: _messages.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return RepaintBoundary(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  AssistantWelcomeCard(
                                    text: l10n.assistantWelcomeGreeting,
                                  ),
                                  MessageQuotaPill(
                                    count: userModel.aiCredits,
                                    unlimited: unlimited,
                                  ),
                                  const SizedBox(height: 8),
                                ],
                              ),
                            );
                          }

                          final msg = _messages[index - 1];
                          final isStreaming = msg.id == _streamingId;

                          final Widget child = isStreaming
                              ? ValueListenableBuilder<String>(
                                  valueListenable: _streamingText,
                                  builder: (context, streamed, _) {
                                    if (streamed.isEmpty) {
                                      return const AssistantTypingIndicator();
                                    }
                                    return AssistantMessageBubble(
                                      key: ValueKey('bubble-${msg.id}'),
                                      text: streamed,
                                      isUser: false,
                                      createdAt: msg.createdAt,
                                      isError: msg.isError,
                                    );
                                  },
                                )
                              : AssistantMessageBubble(
                                  key: ValueKey('bubble-${msg.id}'),
                                  text: msg.text,
                                  isUser: msg.isUser,
                                  createdAt: msg.createdAt,
                                  isError: msg.isError,
                                  thinking: msg.thinking,
                                  showThinking: msg.showThinking,
                                  onThinkingToggled: (v) => msg.showThinking = v,
                                  attachments: msg.attachments != null
                                      ? _AttachmentStrip(
                                          attachments: msg.attachments!,
                                        )
                                      : null,
                                );

                          return RepaintBoundary(
                            child: FadeInSlide(
                              key: ValueKey('fade-${msg.id}'),
                              delay: 0,
                              child: child,
                            ),
                          );
                        },
                      ),
              ),
              if (_messages.length < 3)
                AssistantSuggestionChips(
                  suggestions: [
                    l10n.quickStarterFlashcards,
                    l10n.quickStarterExplainConcept,
                    l10n.quickStarterLearningSession,
                  ],
                  onTap: (text) {
                    _controller.text = text;
                    _sendMessage();
                  },
                ),
              AssistantInputBar(
                controller: _controller,
                hintText: l10n.assistantStudyHint,
                onSend: _sendMessage,
                isLoading: _isLoading,
                onStop: _stopAIResponse,
                onAttach: _pickFiles,
                counterText: unlimited ? null : '${userModel.aiCredits}',
                filePreview: _selectedFiles.isEmpty
                    ? null
                    : _buildFilePreview(theme),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n, int aiCredits, bool unlimited) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AssistantWelcomeCard(text: l10n.assistantWelcomeGreeting),
          MessageQuotaPill(count: aiCredits, unlimited: unlimited),
        ],
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

  Widget _buildDrawer(ThemeData theme, AppLocalizations l10n) {
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
                    l10n.aiAssistantTitle,
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
                      l10n.newChatButton,
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
                      l10n.noRecentChats,
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
              l10n.clearAllChatsListTile,
              style: GoogleFonts.outfit(
                color: Colors.red.shade400,
                fontSize: 14,
              ),
            ),
            onTap: _confirmClearAll,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _AttachmentStrip extends StatelessWidget {
  const _AttachmentStrip({required this.attachments});

  final List<ChatAttachment> attachments;

  @override
  Widget build(BuildContext context) {
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
    };
  }
}
