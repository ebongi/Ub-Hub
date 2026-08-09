import 'package:flutter/material.dart';
import 'package:go_study/Screens/UI/preview/Navigation/chat_screen.dart';
import 'package:go_study/l10n/generated/app_localizations.dart';
import 'package:go_study/services/friends_service.dart';

/// A private 1-on-1 chat between the current user and [friend].
/// Reuses [ChatScreen] with a deterministic DM room ID.
class PrivateChatScreen extends StatelessWidget {
  final FriendProfile friend;
  final String myId;

  const PrivateChatScreen({
    super.key,
    required this.friend,
    required this.myId,
  });

  @override
  Widget build(BuildContext context) {
    final roomId = FriendsService.dmRoomId(myId, friend.id);
    final l10n = AppLocalizations.of(context)!;

    return ChatScreen(
      currentUserId: myId,
      roomId: roomId,
      title: friend.name ?? l10n.privateChatTitle,
      subtitle: l10n.privateMessageSubtitle,
    );
  }
}
