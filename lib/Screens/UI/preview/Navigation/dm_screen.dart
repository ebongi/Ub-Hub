import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_study/Screens/Shared/animations.dart';
import 'package:go_study/Screens/UI/preview/Navigation/private_chat_screen.dart';
import 'package:go_study/Screens/UI/preview/Navigation/user_search_screen.dart';
import 'package:go_study/services/friends_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:go_study/services/message_provider.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

/// The main Direct Messages tab — shows friends list and pending requests.
class DmScreen extends StatefulWidget {
  const DmScreen({super.key});

  @override
  State<DmScreen> createState() => _DmScreenState();
}

class _DmScreenState extends State<DmScreen> {
  late final FriendsService _friendsService;
  late final String _myId;
  bool _requestsExpanded = true;

  @override
  void initState() {
    super.initState();
    _friendsService = FriendsService();
    _myId = sb.Supabase.instance.client.auth.currentUser?.id ?? '';
  }

  void _openSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserSearchScreen(friendsService: _friendsService),
      ),
    );
  }

  void _openChat(FriendProfile friend) {
    final messageProvider =
        Provider.of<MessageProvider>(context, listen: false);

    messageProvider.setChatOpen(true);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PrivateChatScreen(
          friend: friend,
          myId: _myId,
          friendsService: _friendsService,
        ),
      ),
    ).then((_) {
      messageProvider.setChatOpen(false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8F9FA),
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Messages',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.person_add_outlined,
                color: isDark ? Colors.white70 : Colors.black87),
            tooltip: 'Find friends',
            onPressed: _openSearch,
          ),
        ],
      ),
      body: Container(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8F9FA),
        child: Column(
          children: [
            // ─── Pending Requests Section ─────────────────────────────────────
            StreamBuilder<List<FriendRequest>>(
              stream: _friendsService.getPendingRequestsStream(),
              builder: (context, snapshot) {
                final requests = snapshot.data ?? [];
                if (requests.isEmpty) return const SizedBox.shrink();

                return Column(
                  children: [
                    InkWell(
                      onTap: () =>
                          setState(() => _requestsExpanded = !_requestsExpanded),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color:
                                    theme.colorScheme.primary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${requests.length} pending',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Friend Requests',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.6),
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              _requestsExpanded
                                  ? Icons.expand_less_rounded
                                  : Icons.expand_more_rounded,
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.4),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_requestsExpanded)
                      ...requests.map(
                        (req) => _RequestTile(
                          request: req,
                          theme: theme,
                          onAccept: () async {
                            await _friendsService.respondToRequest(req.id, true);
                          },
                          onDecline: () async {
                            await _friendsService.respondToRequest(req.id, false);
                          },
                        ),
                      ),
                    Divider(
                      height: 1,
                      indent: 20,
                      endIndent: 20,
                      color: theme.dividerColor.withOpacity(0.08),
                    ),
                  ],
                );
              },
            ),

            // ─── Friends / Conversations List ─────────────────────────────────
            Expanded(
              child: StreamBuilder<List<FriendProfile>>(
                stream: _friendsService.getFriendsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final friends = snapshot.data ?? [];

                  if (friends.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.07),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 64,
                              color: theme.colorScheme.primary.withOpacity(0.4),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'No friends yet',
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap the icon above to find\nand add fellow students',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: theme.colorScheme.onSurface.withOpacity(0.5),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 32),
                          FilledButton.icon(
                            onPressed: _openSearch,
                            icon: const Icon(Icons.person_add_rounded, size: 18),
                            label: Text('Find Friends',
                                style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold)),
                            style: FilledButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: friends.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      indent: 80,
                      endIndent: 20,
                      color: isDark ? Colors.white10 : Colors.grey[200],
                    ),
                    itemBuilder: (context, i) {
                      final friend = friends[i];
                      return FadeInSlide(
                        duration: Duration(milliseconds: 300 + i * 50),
                        beginOffset: 0.05,
                        child: _FriendTile(
                          friend: friend,
                          theme: theme,
                          isDark: isDark,
                          onTap: () => _openChat(friend),
                          onLongPress: () => _showFriendOptions(friend),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFriendOptions(FriendProfile friend) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 32,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              backgroundImage: friend.avatarUrl != null
                  ? CachedNetworkImageProvider(friend.avatarUrl!)
                  : null,
              child: friend.avatarUrl == null
                  ? Icon(Icons.person_rounded,
                      color: theme.colorScheme.primary, size: 32)
                  : null,
            ),
            const SizedBox(height: 12),
            Text(
              friend.name ?? 'Unknown',
              style:
                  GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Icon(Icons.chat_bubble_rounded,
                  color: theme.colorScheme.primary),
              title: Text('Send Message',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              onTap: () {
                Navigator.pop(context);
                _openChat(friend);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_remove_rounded,
                  color: Colors.redAccent),
              title: Text('Remove Friend',
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w600, color: Colors.redAccent)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              onTap: () async {
                Navigator.pop(context);
                await _friendsService.removeFriend(friend.id);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Friend tile in the conversations list
// ─────────────────────────────────────────────────────────────────────────────
class _FriendTile extends StatelessWidget {
  final FriendProfile friend;
  final ThemeData theme;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _FriendTile({
    required this.friend,
    required this.theme,
    required this.isDark,
    required this.onTap,
    required this.onLongPress,
  });

  String _formatLastMessageTime(DateTime? time) {
    if (time == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDate = DateTime(time.year, time.month, time.day);

    if (msgDate == today) {
      return DateFormat('HH:mm').format(time);
    } else if (msgDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM d').format(time);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lastMessageTime = _formatLastMessageTime(friend.lastMessageTime);

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  backgroundImage: friend.avatarUrl != null
                      ? CachedNetworkImageProvider(friend.avatarUrl!)
                      : null,
                  child: friend.avatarUrl == null
                      ? Icon(Icons.person_rounded,
                          color: theme.colorScheme.primary, size: 28)
                      : null,
                ),
                // Online indicator dot
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? const Color(0xFF0F172A) : Colors.white,
                        width: 2.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        friend.name ?? 'Unknown',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        lastMessageTime,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: isDark ? Colors.white38 : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          friend.lastMessage ?? 'No messages yet',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: isDark ? Colors.white38 : Colors.grey[600],
                          ),
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
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pending request tile
// ─────────────────────────────────────────────────────────────────────────────
class _RequestTile extends StatelessWidget {
  final FriendRequest request;
  final ThemeData theme;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _RequestTile({
    required this.request,
    required this.theme,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
            backgroundImage: request.senderAvatarUrl != null
                ? CachedNetworkImageProvider(request.senderAvatarUrl!)
                : null,
            child: request.senderAvatarUrl == null
                ? Icon(Icons.person_rounded,
                    color: theme.colorScheme.primary, size: 22)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              request.senderName,
              style: GoogleFonts.outfit(
                  fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          // Accept button
          IconButton(
            onPressed: onAccept,
            icon: const Icon(Icons.check_circle_rounded),
            color: Colors.green,
            iconSize: 28,
            tooltip: 'Accept',
          ),
          // Decline button
          IconButton(
            onPressed: onDecline,
            icon: const Icon(Icons.cancel_rounded),
            color: Colors.redAccent,
            iconSize: 28,
            tooltip: 'Decline',
          ),
        ],
      ),
    );
  }
}
