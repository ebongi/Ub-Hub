import 'package:flutter_test/flutter_test.dart';
import 'dart:async';
import 'package:mocktail/mocktail.dart';
import 'package:go_study/services/chat_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}

class MockPostgrestFilterBuilder extends Mock
    implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {}

class MockUser extends Mock implements User {}

// Using a Fake to handle the complex PostgrestFilterBuilder inheritance/return types
class FakePostgrestFilterBuilder extends Fake
    implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {
  @override
  Future<T> then<T>(
    FutureOr<T> Function(List<Map<String, dynamic>>) onValue, {
    Function? onError,
  }) {
    return Future.value(
      <Map<String, dynamic>>[],
    ).then(onValue, onError: onError);
  }
}

void main() {
  late ChatService chatService;
  late MockSupabaseClient mockSupabase;
  late MockGoTrueClient mockAuth;

  setUpAll(() {
    registerFallbackValue(FakePostgrestFilterBuilder());
  });

  setUp(() {
    mockSupabase = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    when(() => mockSupabase.auth).thenAnswer((_) => mockAuth);
    chatService = ChatService(supabase: mockSupabase);
  });

  group('ChatService Tests', () {
    test(
      'sendMessage should throw exception if user is not logged in',
      () async {
        when(() => mockAuth.currentUser).thenAnswer((_) => null);

        expect(
          () => chatService.sendMessage('Hello'),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'description',
              contains('not authenticated'),
            ),
          ),
        );
      },
    );

    test('sendMessage should call insert when user is authenticated', () async {
      final mockUser = MockUser();
      when(() => mockUser.id).thenAnswer((_) => 'user_123');
      when(() => mockAuth.currentUser).thenAnswer((_) => mockUser);

      final mockQueryBuilder = MockSupabaseQueryBuilder();
      final fakeFilterBuilder = FakePostgrestFilterBuilder();

      when(
        () => mockSupabase.from('messages'),
      ).thenAnswer((_) => mockQueryBuilder);
      when(
        () => mockQueryBuilder.insert(any()),
      ).thenAnswer((_) => fakeFilterBuilder);

      await chatService.sendMessage('Test content', senderName: 'Tester');

      verify(() => mockSupabase.from('messages')).called(1);
      verify(() => mockQueryBuilder.insert(any())).called(1);
    });

    // ---------- Reply-to field tests ----------

    test('sendMessage includes reply fields in insert payload when provided',
        () async {
      final mockUser = MockUser();
      when(() => mockUser.id).thenReturn('user_123');
      when(() => mockAuth.currentUser).thenReturn(mockUser);

      final mockQueryBuilder = MockSupabaseQueryBuilder();
      final fakeFilterBuilder = FakePostgrestFilterBuilder();

      when(() => mockSupabase.from('messages'))
          .thenAnswer((_) => mockQueryBuilder);
      when(() => mockQueryBuilder.insert(any()))
          .thenAnswer((_) => fakeFilterBuilder);

      await chatService.sendMessage(
        'I agree!',
        senderName: 'Bob',
        replyToId: 'msg_1',
        replyToName: 'Alice',
        replyToContent: 'Hello World',
      );

      final captured =
          verify(() => mockQueryBuilder.insert(captureAny())).captured;
      final payload = captured.first as Map<String, dynamic>;

      expect(payload['reply_to_id'], 'msg_1');
      expect(payload['reply_to_name'], 'Alice');
      expect(payload['reply_to_content'], 'Hello World');
    });

    test('sendMessage omits reply fields when not provided', () async {
      final mockUser = MockUser();
      when(() => mockUser.id).thenReturn('user_123');
      when(() => mockAuth.currentUser).thenReturn(mockUser);

      final mockQueryBuilder = MockSupabaseQueryBuilder();
      final fakeFilterBuilder = FakePostgrestFilterBuilder();

      when(() => mockSupabase.from('messages'))
          .thenAnswer((_) => mockQueryBuilder);
      when(() => mockQueryBuilder.insert(any()))
          .thenAnswer((_) => fakeFilterBuilder);

      await chatService.sendMessage('Plain message', senderName: 'Carol');

      final captured =
          verify(() => mockQueryBuilder.insert(captureAny())).captured;
      final payload = captured.first as Map<String, dynamic>;

      expect(payload.containsKey('reply_to_id'), isFalse);
      expect(payload.containsKey('reply_to_name'), isFalse);
      expect(payload.containsKey('reply_to_content'), isFalse);
    });
  });
}
