import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:go_study/Screens/UI/preview/Chatbot/chatbot_screen.dart';
import 'package:go_study/services/ai_sync_service.dart';
import 'package:go_study/services/gemini_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

class MockAISyncService extends Mock implements AISyncService {}

class MockGeminiService extends Mock implements GeminiService {}

class MockSupabaseClient extends Mock implements sb.SupabaseClient {}

void main() {
  late MockAISyncService mockSyncService;
  late MockGeminiService mockGeminiService;

  setUp(() {
    mockSyncService = MockAISyncService();
    mockGeminiService = MockGeminiService();

    registerFallbackValue([]); // For any() with history list

    when(() => mockSyncService.loadSessions()).thenAnswer((_) async => []);
    when(() => mockGeminiService.resetChat()).thenReturn(null);
    when(() => mockGeminiService.updateHistory(any())).thenReturn(null);
  });

  Widget createChatbotScreen() {
    return MaterialApp(
      home: ChatbotScreen(
        geminiService: mockGeminiService,
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
      () => mockGeminiService.streamMessage(
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
