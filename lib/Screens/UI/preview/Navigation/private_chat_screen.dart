import 'package:flutter/material.dart';
import 'package:go_study/Screens/UI/preview/Navigation/chat_screen.dart';
import 'package:go_study/services/chat_service.dart';
import 'package:go_study/services/friends_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

/// A private 1-on-1 chat between the current user and [friend].
/// Reuses [ChatScreen] with a deterministic DM room ID.
class PrivateChatScreen extends StatelessWidget {
  final FriendProfile friend;
  final String myId;
  final FriendsService friendsService;

  const PrivateChatScreen({
    super.key,
    required this.friend,
    required this.myId,
    required this.friendsService,
  });

  @override
  Widget build(BuildContext context) {
    final roomId = FriendsService.dmRoomId(myId, friend.id);
    final currentUserId =
        sb.Supabase.instance.client.auth.currentUser?.id ?? myId;

    return ChatScreen(
      chatService: ChatService(),
      currentUserId: currentUserId,
      roomId: roomId,
      title: friend.name ?? 'Private Chat',
      subtitle: 'Private Message',
    );
  }
}
