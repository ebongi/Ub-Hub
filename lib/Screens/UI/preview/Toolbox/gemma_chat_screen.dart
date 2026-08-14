import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart'
    show CancelToken, DownloadException, DownloadErrorMessage;
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:go_study/Screens/Shared/animations.dart';
import 'package:go_study/l10n/generated/app_localizations.dart';
import 'package:go_study/services/gemma_client.dart';
import 'package:go_study/services/gemma_model_manager.dart';
import 'package:go_study/services/gemma_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:markdown_widget/markdown_widget.dart';
import 'package:uuid/uuid.dart';

/// A friendly, deliberately simpler persona than the cloud tutor's — shorter
/// system prompts tend to hold up better on small on-device models than
/// more elaborate formatting instructions.
const String _kGemmaChatSystemPersona =
    'You are a friendly, encouraging academic tutor for university '
    'students. Give clear, accurate, step-by-step explanations. Keep '
    'answers concise and focused on the question asked.';

/// Self-contained on-device AI chat screen for the Toolbox. Owns its whole
/// lifecycle — model download/delete, the chat UI, and the underlying
/// [GemmaService] — deliberately separate from [ChatbotScreen] rather than
/// sharing state with it: this is the free, offline, no-credits, no-history
/// -sync entry point, not an alternate engine for the cloud chat tutor.
class GemmaChatScreen extends StatefulWidget {
  const GemmaChatScreen({super.key});

  @override
  State<GemmaChatScreen> createState() => _GemmaChatScreenState();
}

class _GemmaMessage {
  final String id;
  final String text;
  final bool isUser;
  final bool isError;
  final DateTime createdAt;

  _GemmaMessage({
    String? id,
    required this.text,
    required this.isUser,
    this.isError = false,
    DateTime? createdAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();
}

class _GemmaChatScreenState extends State<GemmaChatScreen> {
  final _manager = GemmaModelManager();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_GemmaMessage> _messages = [];

  GemmaService? _aiService;
  bool _isLoading = false;
  StreamSubscription? _aiSubscription;

  bool _isDownloading = false;
  int _downloadPercent = 0;
  CancelToken? _cancelToken;
  String? _downloadError;

  bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;

  @override
  void initState() {
    super.initState();
    if (_isAndroid && _manager.isModelReady) {
      _aiService = _buildService();
    }
  }

  GemmaService _buildService() {
    return GemmaService(
      client: GemmaChatSessionClient(
        _manager.getOrLoadModel,
        systemInstruction: _kGemmaChatSystemPersona,
      ),
    );
  }

  @override
  void dispose() {
    _aiSubscription?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onDownloadButtonTap() async {
    final confirmed = await _showDownloadInfoDialog();
    if (confirmed) _startDownload();
  }

  /// Shown once, before the first download attempt (not on retry) — makes
  /// sure the user understands the storage/RAM/performance cost and the
  /// smaller model's accuracy trade-off before committing to a ~530MB
  /// download, rather than surfacing that only after the fact.
  Future<bool> _showDownloadInfoDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: Color(0xFF4285F4)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.gemmaChatInfoDialogTitle,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoDialogRow(
                icon: Icons.sd_storage_rounded,
                title: l10n.gemmaChatInfoStorageTitle,
                body: l10n.gemmaChatInfoStorageBody,
              ),
              _InfoDialogRow(
                icon: Icons.memory_rounded,
                title: l10n.gemmaChatInfoRamTitle,
                body: l10n.gemmaChatInfoRamBody,
              ),
              _InfoDialogRow(
                icon: Icons.speed_rounded,
                title: l10n.gemmaChatInfoPerformanceTitle,
                body: l10n.gemmaChatInfoPerformanceBody,
              ),
              _InfoDialogRow(
                icon: Icons.psychology_alt_rounded,
                title: l10n.gemmaChatInfoAccuracyTitle,
                body: l10n.gemmaChatInfoAccuracyBody,
              ),
              _InfoDialogRow(
                icon: Icons.phone_android_rounded,
                title: l10n.gemmaChatInfoDeviceTitle,
                body: l10n.gemmaChatInfoDeviceBody,
                isLast: true,
              ),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              l10n.cancel,
              style: GoogleFonts.outfit(
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l10n.gemmaChatInfoDialogConfirm,
              style: GoogleFonts.outfit(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _downloadPercent = 0;
      _downloadError = null;
      _cancelToken = CancelToken();
    });

    try {
      await _manager.downloadModel(
        onProgress: (percent) {
          if (mounted) setState(() => _downloadPercent = percent);
        },
        cancelToken: _cancelToken,
      );
      if (!mounted) return;
      setState(() {
        _isDownloading = false;
        _aiService = _buildService();
      });
    } catch (e) {
      if (!mounted) return;
      if (CancelToken.isCancel(e)) {
        setState(() => _isDownloading = false);
        return;
      }
      final message = e is DownloadException
          ? e.error.toUserMessage()
          : e.toString();
      setState(() {
        _isDownloading = false;
        _downloadError = message;
      });
    }
  }

  void _cancelDownload() {
    _cancelToken?.cancel();
  }

  Future<void> _confirmRemoveModel() async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          l10n.gemmaChatRemoveModelTitle,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Text(
          l10n.gemmaChatRemoveModelBody,
          style: GoogleFonts.outfit(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              l10n.cancel,
              style: GoogleFonts.outfit(
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l10n.gemmaChatRemoveButton,
              style: GoogleFonts.outfit(
                color: Colors.redAccent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _manager.deleteModel();
      if (!mounted) return;
      setState(() {
        _aiService = null;
        _messages.clear();
      });
    }
  }

  void _newChat() {
    _aiSubscription?.cancel();
    _aiService?.resetChat();
    setState(() {
      _messages.clear();
      _controller.clear();
      _isLoading = false;
    });
  }

  void _stopResponse() {
    _aiSubscription?.cancel();
    setState(() => _isLoading = false);
  }

  Future<void> _sendMessage() async {
    final service = _aiService;
    if (service == null) return;
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final l10n = AppLocalizations.of(context)!;
    final userMessage = _GemmaMessage(text: text, isUser: true);
    final placeholder = _GemmaMessage(text: '', isUser: false);
    _controller.clear();
    setState(() {
      _messages.add(userMessage);
      _messages.add(placeholder);
      _isLoading = true;
    });
    _scrollToBottom();

    var fullResponse = '';
    var lastUiUpdate = DateTime.fromMillisecondsSinceEpoch(0);
    const uiUpdateInterval = Duration(milliseconds: 80);

    _aiSubscription = service.streamMessage(text).listen(
      (chunk) {
        if (!mounted) return;
        fullResponse += chunk;
        final now = DateTime.now();
        if (now.difference(lastUiUpdate) < uiUpdateInterval) return;
        lastUiUpdate = now;
        setState(() {
          final index = _messages.indexWhere((m) => m.id == placeholder.id);
          if (index != -1) {
            _messages[index] = _GemmaMessage(
              id: placeholder.id,
              text: fullResponse,
              isUser: false,
              createdAt: placeholder.createdAt,
            );
          }
        });
        _scrollToBottom();
      },
      onError: (e) {
        if (!mounted) return;
        setState(() {
          final index = _messages.indexWhere((m) => m.id == placeholder.id);
          final errorMessage = _GemmaMessage(
            id: placeholder.id,
            text: l10n.sorryEncounteredError(e.toString()),
            isUser: false,
            isError: true,
            createdAt: placeholder.createdAt,
          );
          if (index != -1) {
            _messages[index] = errorMessage;
          } else {
            _messages.add(errorMessage);
          }
          _isLoading = false;
        });
      },
      onDone: () {
        if (!mounted) return;
        setState(() {
          final index = _messages.indexWhere((m) => m.id == placeholder.id);
          if (index != -1) {
            _messages[index] = _GemmaMessage(
              id: placeholder.id,
              text: fullResponse,
              isUser: false,
              createdAt: placeholder.createdAt,
            );
          }
          _isLoading = false;
        });
        _aiSubscription = null;
      },
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          l10n.gemmaChatTitle,
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
        actions: _aiService != null
            ? [
                IconButton(
                  tooltip: l10n.newChatButton,
                  icon: const Icon(Icons.add_comment_outlined),
                  onPressed: _newChat,
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'remove') _confirmRemoveModel();
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'remove',
                      child: Text(l10n.gemmaChatRemoveMenuLabel),
                    ),
                  ],
                ),
              ]
            : null,
      ),
      body: _buildBody(theme, l10n),
    );
  }

  Widget _buildBody(ThemeData theme, AppLocalizations l10n) {
    if (!_isAndroid) {
      return _buildUnavailableState(theme, l10n);
    }
    if (_aiService == null) {
      return _buildDownloadState(theme, l10n);
    }
    return Column(
      children: [
        Expanded(
          child: _messages.isEmpty
              ? _buildEmptyState(theme, l10n)
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    return FadeInSlide(
                      key: ValueKey(msg.id),
                      delay: 0,
                      child: _GemmaMessageBubble(message: msg),
                    );
                  },
                ),
        ),
        _buildInputArea(theme, l10n),
      ],
    );
  }

  Widget _buildUnavailableState(ThemeData theme, AppLocalizations l10n) {
    final isDark = theme.brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.phonelink_off_rounded,
              size: 56,
              color: isDark ? Colors.white38 : Colors.black26,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.gemmaChatUnavailableTitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.gemmaChatUnavailableBody,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadState(ThemeData theme, AppLocalizations l10n) {
    final isDark = theme.brightness == Brightness.dark;
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFF4285F4), Color(0xFF9B72F3)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: const Icon(
                  Icons.download_for_offline_rounded,
                  size: 64,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.gemmaChatDownloadTitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.gemmaChatDownloadBody,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
              const SizedBox(height: 32),
              if (_isDownloading) ...[
                LinearProgressIndicator(value: _downloadPercent / 100),
                const SizedBox(height: 12),
                Text(
                  l10n.gemmaChatDownloadProgressPercent(_downloadPercent),
                  style: GoogleFonts.outfit(),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _cancelDownload,
                  child: Text(
                    l10n.gemmaChatDownloadCancelButton,
                    style: GoogleFonts.outfit(color: Colors.grey),
                  ),
                ),
              ] else ...[
                if (_downloadError != null) ...[
                  Text(
                    l10n.gemmaChatDownloadFailedBody(_downloadError!),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      color: Colors.red.shade400,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                ScaleButton(
                  onTap: _downloadError != null
                      ? _startDownload
                      : _onDownloadButtonTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4285F4), Color(0xFF9B72F3)],
                      ),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Text(
                      _downloadError != null
                          ? l10n.gemmaChatRetryButton
                          : l10n.gemmaChatDownloadButton,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, AppLocalizations l10n) {
    final isDark = theme.brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF4285F4), Color(0xFF9B72F3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: 64,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.gemmaChatEmptyStateTitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface.withOpacity(0.85),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.gemmaChatEmptyStateBody,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(ThemeData theme, AppLocalizations l10n) {
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
                          l10n.thinkingLabel,
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
                          onPressed: _stopResponse,
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
                            l10n.stopButton,
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
                            hintText: l10n.gemmaChatInputHint,
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
}

class _InfoDialogRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final bool isLast;

  const _InfoDialogRow({
    required this.icon,
    required this.title,
    required this.body,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    height: 1.4,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GemmaMessageBubble extends StatelessWidget {
  final _GemmaMessage message;

  const _GemmaMessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isUser = message.isUser;
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
            if (!isUser)
              Padding(
                padding: const EdgeInsets.only(left: 2.0, right: 4.0, bottom: 2),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: 20,
                  color: Colors.blue.shade400,
                ),
              ),
            Flexible(
              child: Column(
                crossAxisAlignment: isUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width *
                          (isUser ? 0.75 : 0.94),
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
                          : (message.isError
                                ? Colors.red.withOpacity(0.05)
                                : Colors.transparent),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(24),
                        topRight: const Radius.circular(24),
                        bottomLeft: Radius.circular(isUser ? 24 : 0),
                        bottomRight: Radius.circular(isUser ? 0 : 24),
                      ),
                      border: !isUser && message.isError
                          ? Border.all(
                              color: Colors.red.withOpacity(0.2),
                              width: 1,
                            )
                          : null,
                    ),
                    child: isUser
                        ? Text(
                            message.text,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 18,
                              height: 1.4,
                            ),
                          )
                        : MarkdownBlock(
                            data: message.text,
                            config: MarkdownConfig(
                              configs: [
                                PConfig(
                                  textStyle: GoogleFonts.outfit(
                                    color: message.isError
                                        ? Colors.red.shade400
                                        : onSurface,
                                    fontSize: 18,
                                    height: 1.6,
                                  ),
                                ),
                              ],
                            ),
                            generator: MarkdownGenerator(
                              generators: [_gemmaLatexGenerator],
                              inlineSyntaxList: [_GemmaLatexSyntax()],
                            ),
                          ),
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      DateFormat('HH:mm').format(message.createdAt),
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
}

final _gemmaLatexGenerator = SpanNodeGeneratorWithTag(
  tag: 'latex',
  generator: (e, config, visitor) =>
      _GemmaLatexNode(e.attributes['content'] ?? '', config),
);

class _GemmaLatexNode extends SpanNode {
  final String content;
  final MarkdownConfig config;

  _GemmaLatexNode(this.content, this.config);

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

/// Same math-vs-currency heuristic as the cloud chat screen's LatexSyntax
/// (see chatbot_screen.dart) — duplicated rather than imported, since this
/// screen is deliberately self-contained.
class _GemmaLatexSyntax extends md.InlineSyntax {
  _GemmaLatexSyntax() : super(r'(\$\$?)([\s\S]+?)\1');

  static const _mathWords = {
    'sin', 'cos', 'tan', 'sec', 'csc', 'cot',
    'log', 'ln', 'exp', 'max', 'min', 'det',
    'lim', 'sup', 'inf', 'mod', 'gcd', 'lcm', 'arg',
  };

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final content = match.group(2) ?? '';
    if (!_looksLikeMath(content)) return false;
    parser.addNode(
      md.Element.withTag('latex')..attributes['content'] = content,
    );
    return true;
  }

  static bool _looksLikeMath(String content) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return false;
    if (trimmed.contains('\n\n')) return false;
    if (trimmed.contains('\\')) return true;
    if (RegExp(r'[=^_+/<>]').hasMatch(trimmed)) return true;

    final plainWordCount = RegExp(r'[A-Za-z]{2,}')
        .allMatches(trimmed)
        .map((m) => m.group(0)!.toLowerCase())
        .where((w) => !_mathWords.contains(w))
        .length;
    return plainWordCount < 2;
  }
}
