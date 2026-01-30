import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:neo/Screens/Shared/constanst.dart';
import 'package:neo/Screens/UI/preview/Navigation/chat_screen.dart';
import 'package:neo/services/chat_service.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

class MockChatService extends Mock implements ChatService {}

class MockSupabase extends Mock implements sb.Supabase {}

class MockSupabaseClient extends Mock implements sb.SupabaseClient {}

class MockGoTrueClient extends Mock implements sb.GoTrueClient {}

class MockUser extends Mock implements sb.User {}

void main() {
  late MockChatService mockChatService;
  late MockSupabaseClient mockSupabaseClient;

  setUpAll(() {
    registerFallbackValue(Uri.parse('http://localhost'));
  });

  setUp(() {
    mockChatService = MockChatService();
    mockSupabaseClient = MockSupabaseClient();
    final mockAuth = MockGoTrueClient();
    final mockUser = MockUser();

    when(() => mockSupabaseClient.auth).thenReturn(mockAuth);
    when(() => mockAuth.currentUser).thenReturn(mockUser);
    when(() => mockUser.id).thenReturn('test_user_id');
  });

  Widget createChatScreen() {
    return ChangeNotifierProvider<UserModel>(
      create: (_) => UserModel(name: 'Test User'),
      child: MaterialApp(
        home: ChatScreen(
          chatService: mockChatService,
          currentUserId: 'test_user_id',
        ),
      ),
    );
  }

  testWidgets('ChatScreen should render correctly with background and input', (
    tester,
  ) async {
    when(
      () => mockChatService.getMessagesStream(),
    ).thenAnswer((_) => Stream.value([]));

    await tester.pumpWidget(createChatScreen());

    expect(find.text('Global Chat'), findsOneWidget);
    expect(find.text('Public Community Hub'), findsOneWidget);
    expect(find.text('Message'), findsOneWidget); // Hint text

    // Check for the background image asset
    final containerFinder = find.byWidgetPredicate(
      (widget) =>
          widget is Container &&
          widget.decoration is BoxDecoration &&
          (widget.decoration as BoxDecoration).image != null,
    );
    expect(containerFinder, findsOneWidget);
  });

  testWidgets('ChatScreen should show empty state when no messages', (
    tester,
  ) async {
    when(
      () => mockChatService.getMessagesStream(),
    ).thenAnswer((_) => Stream.value([]));

    await tester.pumpWidget(createChatScreen());
    await tester.pump();

    expect(find.text('No messages yet. Say hi!'), findsOneWidget);
  });

  testWidgets('ChatScreen should render message bubbles', (tester) async {
    final messages = [
      ChatMessageModel(
        id: '1',
        content: 'Hello from me',
        senderId: 'test_user_id',
        senderName: 'Test User',
        createdAt: DateTime.now(),
      ),
      ChatMessageModel(
        id: '2',
        content: 'Hello from someone else',
        senderId: 'other_user',
        senderName: 'Alice',
        createdAt: DateTime.now(),
      ),
    ];

    when(
      () => mockChatService.getMessagesStream(),
    ).thenAnswer((_) => Stream.value(messages));

    await tester.pumpWidget(createChatScreen());
    await tester.pump(); // Start animations

    expect(find.text('Hello from me'), findsOneWidget);
    expect(
      find.text('Test User'),
      findsOneWidget,
    ); // Now displayed for "me" too
    expect(find.text('Hello from someone else'), findsOneWidget);
    expect(find.text('Alice'), findsOneWidget);
  });
}
