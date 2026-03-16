import 'package:flutter/material.dart';
import 'package:go_study/services/message_provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_study/Screens/Shared/animations.dart';
import 'package:go_study/Screens/Shared/constanst.dart';
import 'package:go_study/services/chat_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_study/Screens/Shared/premium_dialog.dart';

class ChatScreen extends StatefulWidget {
  final ChatService? chatService;
  final String? currentUserId;
  final String roomId;
  final String title;
  final String? subtitle;

  const ChatScreen({
    super.key,
    this.chatService,
    this.currentUserId,
    this.roomId = 'global',
    this.title = 'Global Chat',
    this.subtitle,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final ChatService _chatService;
  late final String? _currentUserId;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  /// The message the user is currently replying to (null = no active reply).
  ChatMessageModel? _replyingTo;

  @override
  void initState() {
    super.initState();
    _chatService = widget.chatService ?? ChatService();
    _currentUserId = widget.currentUserId ?? _getSupabaseId();

    // Mark chat as open in global provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<MessageProvider>(context, listen: false).setChatOpen(true);
      }
    });
  }

  String? _getSupabaseId() {
    try {
      return sb.Supabase.instance.client.auth.currentUser?.id;
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    // Mark chat as closed in global provider
    // Using context.read or a delayed callback because context might be invalid here
    // but MessageProvider is global so we can find it if we have context.
    // However, it's safer to use the return from Navigator.push in the calling screen
    // (like I did in DmScreen). For ChatScreen, it might be called from Home.
    // So I'll try to set it to false here if I can safely access provider.
    try {
      Provider.of<MessageProvider>(context, listen: false).setChatOpen(false);
    } catch (_) {}
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final userModel = Provider.of<UserModel>(context, listen: false);
    final senderName = userModel.name ?? 'Anonymous';
    final avatarUrl = userModel.avatarUrl;

    final replySnapshot = _replyingTo;

    _messageController.clear();
    setState(() => _replyingTo = null);

    try {
      await _chatService.sendMessage(
        text,
        senderName: senderName,
        senderAvatarUrl: avatarUrl,
        roomId: widget.roomId,
        replyToId: replySnapshot?.id,
        replyToName: replySnapshot?.senderName,
        replyToContent: replySnapshot?.content,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error sending message: $e')));
      }
    }
  }

  void _setReplyingTo(ChatMessageModel message) {
    setState(() => _replyingTo = message);
    // Focus the text field so the keyboard opens immediately
    FocusScope.of(context).requestFocus(FocusNode());
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) FocusScope.of(context).unfocus();
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted) FocusScope.of(context).requestFocus(FocusNode());
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8F9FA),
        title: Column(
          children: [
            Text(
              widget.title,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            Text(
              widget.subtitle ?? "Active Now",
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: isDarkMode ? Colors.white38 : Colors.grey[500],
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () {
              showPremiumGeneralDialog(
                context: context,
                barrierLabel: "About Global Chat",
                child: AlertDialog(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32)),
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
                        title: "Global Chat",
                        subtitle: "Connect with your peers",
                        icon: Icons.hub_rounded,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Text(
                              "This is a real-time chat room for all users of GO-Study specific for this course. Please be respectful and follow community guidelines.",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white70
                                    : Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 32),
                            PremiumSubmitButton(
                              label: "Got it",
                              isLoading: false,
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessageModel>>(
              stream: _chatService.getMessagesStream(roomId: widget.roomId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          'assets/images/colob.svg',
                          width: 150,
                          height: 150,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          "No messages yet. Say hi!",
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == _currentUserId;

                    // Date grouping logic
                    bool showDateHeader = false;
                    if (index == messages.length - 1) {
                      showDateHeader = true;
                    } else {
                      final nextMessage = messages[index + 1];
                      final date = DateTime(
                        message.createdAt.year,
                        message.createdAt.month,
                        message.createdAt.day,
                      );
                      final nextDate = DateTime(
                        nextMessage.createdAt.year,
                        nextMessage.createdAt.month,
                        nextMessage.createdAt.day,
                      );
                      if (date != nextDate) {
                        showDateHeader = true;
                      }
                    }

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (showDateHeader)
                          _buildDateHeader(message.createdAt),
                        FadeInSlide(
                          duration: const Duration(milliseconds: 400),
                          beginOffset: 0.1,
                          child: _SwipeToReply(
                            isMe: isMe,
                            onReply: () => _setReplyingTo(message),
                            child: _MessageBubble(
                              message: message,
                              isMe: isMe,
                              theme: theme,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          // Reply preview banner
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _replyingTo != null
                ? _ReplyBanner(
                    key: ValueKey(_replyingTo!.id),
                    message: _replyingTo!,
                    theme: theme,
                    onCancel: () => setState(() => _replyingTo = null),
                  )
                : const SizedBox.shrink(),
          ),
          _buildInputArea(theme),
        ],
      ),
    );
  }

  Widget _buildDateHeader(DateTime date) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    String dateText;
    if (messageDate == today) {
      dateText = "Today";
    } else if (messageDate == yesterday) {
      dateText = "Yesterday";
    } else {
      dateText = DateFormat('MMM d, yyyy').format(date);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 32),
      alignment: Alignment.center,
      child: Text(
        dateText,
        style: GoogleFonts.outfit(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: theme.brightness == Brightness.dark
              ? Colors.white38
              : Colors.grey[500],
        ),
      ),
    );
  }

  Widget _buildInputArea(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withOpacity(0.5),
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {
                // Future attachment logic
              },
              icon: Icon(Icons.add_rounded, color: theme.colorScheme.primary),
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 5,
                minLines: 1,
                style: GoogleFonts.outfit(fontSize: 15),
                decoration: InputDecoration(
                  hintText: "Send a message",
                  hintStyle: GoogleFonts.outfit(
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            ScaleButton(
              onTap: _sendMessage,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reply Banner – shown above the input area when replying to a message
// ---------------------------------------------------------------------------
class _ReplyBanner extends StatelessWidget {
  final ChatMessageModel message;
  final ThemeData theme;
  final VoidCallback onCancel;

  const _ReplyBanner({
    super.key,
    required this.message,
    required this.theme,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;
    final accentColor = theme.colorScheme.primary;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? accentColor.withOpacity(0.12)
            : accentColor.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(color: accentColor, width: 3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Replying to ${message.senderName ?? 'Anonymous'}',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message.content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onCancel,
            icon: Icon(
              Icons.close_rounded,
              size: 18,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Swipe-to-Reply wrapper
// ---------------------------------------------------------------------------
class _SwipeToReply extends StatefulWidget {
  final Widget child;
  final bool isMe;
  final VoidCallback onReply;

  const _SwipeToReply({
    required this.child,
    required this.isMe,
    required this.onReply,
  });

  @override
  State<_SwipeToReply> createState() => _SwipeToReplyState();
}

class _SwipeToReplyState extends State<_SwipeToReply>
    with SingleTickerProviderStateMixin {
  double _dragOffset = 0;
  bool _triggered = false;

  static const double _triggerThreshold = 60.0;
  static const double _maxDrag = 80.0;

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    // Allow right-swipe for received messages, left-swipe for own messages
    final delta = widget.isMe ? -details.delta.dx : details.delta.dx;
    if (delta < 0) return; // ignore wrong direction
    setState(() {
      _dragOffset = (_dragOffset + delta).clamp(0.0, _maxDrag);
      if (_dragOffset >= _triggerThreshold && !_triggered) {
        _triggered = true;
      }
    });
  }

  void _onHorizontalDragEnd(DragEndDetails _) {
    if (_triggered) widget.onReply();
    setState(() {
      _dragOffset = 0;
      _triggered = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = (_dragOffset / _triggerThreshold).clamp(0.0, 1.0);
    final iconOpacity = progress;
    final iconScale = 0.6 + 0.4 * progress;

    // The reply icon appears on the opposite side of the bubble
    final replyIcon = Opacity(
      opacity: iconOpacity,
      child: Transform.scale(
        scale: iconScale,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.reply_all_rounded,
            color: theme.colorScheme.onPrimaryContainer,
            size: 20,
          ),
        ),
      ),
    );

    return GestureDetector(
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      child: Transform.translate(
        offset: Offset(widget.isMe ? -_dragOffset : _dragOffset, 0),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            widget.child,
            // Icon positioned outside the bubble
            if (widget.isMe)
              Positioned(
                left: -36,
                top: 0,
                bottom: 0,
                child: Center(child: replyIcon),
              )
            else
              Positioned(
                right: -36,
                top: 0,
                bottom: 0,
                child: Center(child: replyIcon),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Message Bubble
// ---------------------------------------------------------------------------
class _MessageBubble extends StatelessWidget {
  final ChatMessageModel message;
  final bool isMe;
  final ThemeData theme;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.theme,
  });

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 12,
      backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
      backgroundImage: message.senderAvatarUrl != null
          ? CachedNetworkImageProvider(message.senderAvatarUrl!)
          : null,
      child: message.senderAvatarUrl == null
          ? Icon(
              Icons.person_rounded,
              size: 16,
              color: theme.colorScheme.primary,
            )
          : null,
    );
  }

  /// Quoted reply block shown inside the bubble when this message is a reply.
  Widget _buildReplyQuote() {
    final isDark = theme.brightness == Brightness.dark;
    final accentColor = isMe ? Colors.white.withOpacity(0.9) : theme.colorScheme.primary;
    final bgColor = isMe
        ? Colors.white.withOpacity(0.15)
        : (isDark
            ? theme.colorScheme.primary.withOpacity(0.12)
            : theme.colorScheme.primary.withOpacity(0.07));
    final textColor = isMe
        ? Colors.white.withOpacity(0.85)
        : theme.colorScheme.onSurface.withOpacity(0.65);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(color: accentColor, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message.replyToName ?? 'Anonymous',
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            message.replyToContent ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: textColor,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm');
    final isDarkMode = theme.brightness == Brightness.dark;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Row(
          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe) ...[const SizedBox(width: 8), _buildAvatar()],
            Flexible(
              child: IntrinsicWidth(
                child: Column(
                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                decoration: BoxDecoration(
                  color: isMe
                      ? (isDarkMode ? const Color(0xFF1E293B) : theme.colorScheme.primary)
                      : (isDarkMode ? const Color(0xFF334155) : Colors.white),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(24),
                    topRight: const Radius.circular(24),
                    bottomLeft: Radius.circular(isMe ? 24 : 0),
                    bottomRight: Radius.circular(isMe ? 0 : 24),
                  ),
                  border: isDarkMode || isMe
                      ? null
                      : Border.all(
                          color: Colors.grey[200]!,
                          width: 1,
                        ),
                ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!isMe)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text(
                                message.senderName ?? 'Anonymous',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          if (message.replyToContent != null) _buildReplyQuote(),
                          Text(
                            message.content,
                            style: GoogleFonts.outfit(
                              color: isMe
                                  ? Colors.white
                                  : (isDarkMode ? Colors.white : Colors.black87),
                              fontSize: 15,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            timeFormat.format(message.createdAt),
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: isDarkMode ? Colors.white30 : Colors.grey[400],
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.done_all_rounded,
                            size: 14,
                            color: isDarkMode ? Colors.white30 : theme.colorScheme.primary.withOpacity(0.7),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (isMe) ...[const SizedBox(width: 8), _buildAvatar()],
          ],
        ),
      ),
    );
  }
}
