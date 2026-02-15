import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neo/Screens/Shared/animations.dart';
import 'package:neo/Screens/Shared/constanst.dart';
import 'package:neo/services/chat_service.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

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

  @override
  void initState() {
    super.initState();
    _chatService = widget.chatService ?? ChatService();
    _currentUserId = widget.currentUserId ?? _getSupabaseId();
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
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final userModel = Provider.of<UserModel>(context, listen: false);
    final senderName = userModel.name ?? 'Anonymous';
    final avatarUrl = userModel.avatarUrl;

    _messageController.clear();

    try {
      await _chatService.sendMessage(
        text,
        senderName: senderName,
        senderAvatarUrl: avatarUrl,
        roomId: widget.roomId,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error sending message: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        iconTheme: theme.appBarTheme.iconTheme,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              child: Icon(
                Icons.groups_rounded,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: theme.appBarTheme.titleTextStyle?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.subtitle ??
                        (widget.roomId == 'global'
                            ? "Public Community Hub"
                            : "Study Group"),
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("About Global Chat"),
                  content: const Text(
                    "This is a real-time chat room for all users of Ub-Hub. "
                    "Please be respectful and follow community guidelines.",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Got it"),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/images/chat_bg.png'),
            repeat: ImageRepeat.repeat,
            opacity: isDarkMode ? 0.1 : 0.25, // Adjusted for clearer visibility
          ),
        ),
        child: Column(
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
                          Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 64,
                            color: theme.colorScheme.primary.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "No messages yet. Say hi!",
                            style: GoogleFonts.outfit(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true, // Newest messages at the bottom
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
                            child: _MessageBubble(
                              message: message,
                              isMe: isMe,
                              theme: theme,
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            _buildInputArea(theme),
          ],
        ),
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
      margin: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        children: [
          Expanded(child: Divider(color: theme.dividerColor.withOpacity(0.05))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              dateText,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withOpacity(0.4),
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(child: Divider(color: theme.dividerColor.withOpacity(0.05))),
        ],
      ),
    );
  }

  Widget _buildInputArea(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      decoration: BoxDecoration(
        color: Colors.transparent, // Maintain background visibility
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
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
                  hintText: "Spread some love...",
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
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm');
    final isDarkMode = theme.brightness == Brightness.dark;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe) ...[_buildAvatar(), const SizedBox(width: 8)],
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: isMe
                      ? LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.primary.withOpacity(0.85),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isMe ? null : theme.cardTheme.color,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(isMe ? 20 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isMe)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          message.senderName ?? 'Anonymous',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
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
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          timeFormat.format(message.createdAt),
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            color:
                                (isMe
                                        ? Colors.white
                                        : (isDarkMode
                                              ? Colors.white
                                              : Colors.black87))
                                    .withOpacity(0.5),
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.done_all,
                            size: 14,
                            color: Colors.white.withOpacity(0.7),
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
