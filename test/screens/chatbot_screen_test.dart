import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:go_study/Screens/UI/preview/Chatbot/chatbot_screen.dart';
import 'package:go_study/services/ai_sync_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'package:go_study/services/ai_service.dart';

class MockAISyncService extends Mock implements AISyncService {}

class MockAIService extends Mock implements AIService {}

class MockSupabaseClient extends Mock implements sb.SupabaseClient {}

void main() {
  late MockAISyncService mockSyncService;
  late MockAIService mockAIService;

  setUp(() {
    mockSyncService = MockAISyncService();
    mockAIService = MockAIService();

    registerFallbackValue([]); // For any() with history list
    registerFallbackValue(AIChatMessage(text: '', isUser: true));
    registerFallbackValue(<AIChatMessage>[]);
    registerFallbackValue(AIAttachment('', null));
    registerFallbackValue(ChatMessage(
      text: '',
      isUser: true,
      createdAt: DateTime.now(),
    ));
    registerFallbackValue(ChatSession(
      id: '',
      title: '',
      messages: [],
      createdAt: DateTime.now(),
    ));

    when(() => mockSyncService.loadSessions()).thenAnswer((_) async => []);
    when(() => mockAIService.resetChat()).thenReturn(null);
    when(() => mockAIService.updateHistory(any())).thenReturn(null);
  });

  Widget createChatbotScreen() {
    return MaterialApp(
      home: ChatbotScreen(
        aiService: mockAIService,
        syncService: mockSyncService,
      ),
    );
  }

  testWidgets('ChatbotScreen renders empty state initially', (tester) async {
    await tester.pumpWidget(createChatbotScreen());
    await tester.pump();

    expect(find.text('How can I help you today?'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('Sending a message adds it to the list', (tester) async {
    when(() => mockSyncService.saveSession(any())).thenAnswer((_) async {});
    when(
      () => mockSyncService.saveMessage(any(), any()),
    ).thenAnswer((_) async {});
    when(
      () => mockAIService.streamMessage(
        any(),
        attachments: any(named: 'attachments'),
      ),
    ).thenAnswer(
      (_) => Stream.fromIterable(['Part 1 ', 'Part 2 ', 'Final Part']),
    );

    await tester.pumpWidget(createChatbotScreen());
    await tester.pump();

    final textField = find.byType(TextField);
    await tester.enterText(textField, 'Hello AI');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump(); // Start stream
    await tester.pump(); // Process chunks
    await tester.pump(); // Final update

    expect(find.textContaining('Part 1 Part 2 Final Part'), findsOneWidget);
  });
}
