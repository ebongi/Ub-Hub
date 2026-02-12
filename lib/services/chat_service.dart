import 'package:supabase_flutter/supabase_flutter.dart';

class ChatMessageModel {
  final String id;
  final String content;
  final String senderId;
  final String? senderName;
  final String? senderAvatarUrl;
  final DateTime createdAt;
  final String roomId;

  ChatMessageModel({
    required this.id,
    required this.content,
    required this.senderId,
    this.senderName,
    this.senderAvatarUrl,
    required this.createdAt,
    this.roomId = 'global',
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'sender_id': senderId,
      'sender_name': senderName,
      'sender_avatar_url': senderAvatarUrl,
      'room_id': roomId,
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
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _supabase.from('messages').insert({
      'content': content,
      'sender_id': user.id,
      'sender_name': senderName,
      'sender_avatar_url': senderAvatarUrl,
      'room_id': roomId,
    });
  }
}
