import 'package:flutter_test/flutter_test.dart';
import 'package:neo/services/chat_service.dart';

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
  });
}
