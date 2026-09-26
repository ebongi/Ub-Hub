import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_study/services/notification_service.dart';
import 'package:go_study/services/notification_model.dart';

class ChatMessageModel {
  final String id;
  final String content;
  final String senderId;
  final String? senderName;
  final String? senderAvatarUrl;
  final DateTime createdAt;
  final String roomId;

  // Reply-to fields
  final String? replyToId;
  final String? replyToName;
  final String? replyToContent;

  ChatMessageModel({
    required this.id,
    required this.content,
    required this.senderId,
    this.senderName,
    this.senderAvatarUrl,
    required this.createdAt,
    this.roomId = 'global',
    this.replyToId,
    this.replyToName,
    this.replyToContent,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'],
      content: json['content'],
      senderId: json['sender_id'],
      senderName: json['sender_name'],
      senderAvatarUrl: json['sender_avatar_url'],
      createdAt: DateTime.parse(json['created_at']),
      roomId: json['room_id'] ?? 'global',
      replyToId: json['reply_to_id'],
      replyToName: json['reply_to_name'],
      replyToContent: json['reply_to_content'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'sender_id': senderId,
      'sender_name': senderName,
      'sender_avatar_url': senderAvatarUrl,
      'room_id': roomId,
      if (replyToId != null) 'reply_to_id': replyToId,
      if (replyToName != null) 'reply_to_name': replyToName,
      if (replyToContent != null) 'reply_to_content': replyToContent,
    };
  }
}

class ChatService {
  final SupabaseClient _supabase;

  ChatService({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  Stream<List<ChatMessageModel>> getMessagesStream({String roomId = 'global'}) {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .order('created_at', ascending: false)
        .map(
          (data) =>
              data.map((json) => ChatMessageModel.fromJson(json)).toList(),
        );
  }

  Future<void> sendMessage(
    String content, {
    String? senderName,
    String? senderAvatarUrl,
    String roomId = 'global',
    String? replyToId,
    String? replyToName,
    String? replyToContent,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _supabase.from('messages').insert({
      'content': content,
      'sender_id': user.id,
      'sender_name': senderName,
      'sender_avatar_url': senderAvatarUrl,
      'room_id': roomId,
      if (replyToId != null) 'reply_to_id': replyToId,
      if (replyToName != null) 'reply_to_name': replyToName,
      if (replyToContent != null) 'reply_to_content': replyToContent,
    });

    // Trigger notification (best-effort – may not be available in test env)
    try {
      if (roomId.startsWith('dm_')) {
        // ── Direct message ─────────────────────────────────────────────────
        // Extract the recipient from the dm_uid1_uid2 convention
        String? recipientId;
        final parts = roomId.split('_');
        if (parts.length == 3) {
          recipientId = parts[1] == user.id ? parts[2] : parts[1];
        }

        if (recipientId != null) {
          await NotificationService().createNotification(
            title: 'New message from ${senderName ?? "Someone"}',
            body: content,
            type: NotificationType.message,
            recipientId: recipientId,
            data: {'roomId': roomId},
            showLocal: true,
          );

          // Also push to the recipient's background/terminated device — the
          // DB row above only shows a local alert if their app is already
          // open with an active realtime subscription.
          await NotificationService().triggerPushViaEdgeFunction(
            scope: 'dm',
            scopeId: roomId,
            title: 'New message from ${senderName ?? "Someone"}',
            body: content,
            type: NotificationType.message,
            data: {'roomId': roomId},
            insertNotification: false, // already inserted above
          );
        }
      } else {
        // ── Group / department / global room ───────────────────────────────
        // Let the Edge Function resolve room membership and send FCM pushes.
        // We do NOT insert notification rows here (group chats are read via
        // the chat stream, not the notifications list).
        await NotificationService().triggerPushViaEdgeFunction(
          scope: 'room',
          scopeId: roomId,
          title: senderName ?? 'New Message',
          body: content,
          type: NotificationType.message,
          data: {'roomId': roomId, 'messageType': 'group'},
          insertNotification: false,
        );
      }
    } catch (_) {
      // Silently ignore – notification service unavailable (e.g. in tests)
    }
  }
}
