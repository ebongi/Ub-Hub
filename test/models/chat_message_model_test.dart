import 'package:flutter_test/flutter_test.dart';
import 'package:go_study/services/chat_service.dart';

void main() {
  group('ChatMessageModel Tests', () {
    test('fromJson should correctly map JSON to ChatMessageModel', () {
      final json = {
        'id': 'msg_1',
        'content': 'Hello World',
        'sender_id': 'user_1',
        'sender_name': 'Alice',
        'created_at': '2023-10-27T10:00:00Z',
        'room_id': 'general',
      };

      final message = ChatMessageModel.fromJson(json);

      expect(message.id, 'msg_1');
      expect(message.content, 'Hello World');
      expect(message.senderId, 'user_1');
      expect(message.senderName, 'Alice');
      expect(message.createdAt, DateTime.parse('2023-10-27T10:00:00Z'));
      expect(message.roomId, 'general');
    });

    test('toJson should correctly map ChatMessageModel to JSON', () {
      final message = ChatMessageModel(
        id: 'msg_2',
        content: 'Test JSON',
        senderId: 'user_2',
        senderName: 'Bob',
        createdAt: DateTime.now(),
        roomId: 'test_room',
      );

      final json = message.toJson();

      expect(json['content'], 'Test JSON');
      expect(json['sender_id'], 'user_2');
      expect(json['sender_name'], 'Bob');
      expect(json['room_id'], 'test_room');
    });

    // ---------- Reply-to field tests ----------

    test('fromJson should correctly map reply-to fields', () {
      final json = {
        'id': 'msg_3',
        'content': 'This is a reply',
        'sender_id': 'user_3',
        'sender_name': 'Carol',
        'created_at': '2024-01-01T09:00:00Z',
        'room_id': 'global',
        'reply_to_id': 'msg_1',
        'reply_to_name': 'Alice',
        'reply_to_content': 'Hello World',
      };

      final message = ChatMessageModel.fromJson(json);

      expect(message.replyToId, 'msg_1');
      expect(message.replyToName, 'Alice');
      expect(message.replyToContent, 'Hello World');
    });

    test('fromJson sets reply fields to null when absent (backward compat)', () {
      final json = {
        'id': 'msg_4',
        'content': 'Regular message',
        'sender_id': 'user_4',
        'created_at': '2024-01-01T09:00:00Z',
        'room_id': 'global',
      };

      final message = ChatMessageModel.fromJson(json);

      expect(message.replyToId, isNull);
      expect(message.replyToName, isNull);
      expect(message.replyToContent, isNull);
    });

    test('toJson includes reply fields when set', () {
      final message = ChatMessageModel(
        id: 'msg_5',
        content: 'Reply message',
        senderId: 'user_5',
        createdAt: DateTime.now(),
        replyToId: 'msg_1',
        replyToName: 'Alice',
        replyToContent: 'Hello World',
      );

      final json = message.toJson();

      expect(json['reply_to_id'], 'msg_1');
      expect(json['reply_to_name'], 'Alice');
      expect(json['reply_to_content'], 'Hello World');
    });

    test('toJson omits reply fields when not set', () {
      final message = ChatMessageModel(
        id: 'msg_6',
        content: 'Normal message',
        senderId: 'user_6',
        createdAt: DateTime.now(),
      );

      final json = message.toJson();

      expect(json.containsKey('reply_to_id'), isFalse);
      expect(json.containsKey('reply_to_name'), isFalse);
      expect(json.containsKey('reply_to_content'), isFalse);
    });
  });
}
