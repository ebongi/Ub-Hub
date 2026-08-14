import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:go_study/services/ai_service.dart';
import 'package:go_study/services/gemma_client.dart';
import 'package:go_study/services/gemma_service.dart';

class MockGemmaClient extends Mock implements GemmaClient {}

void main() {
  late GemmaService gemmaService;
  late MockGemmaClient mockClient;

  setUp(() {
    mockClient = MockGemmaClient();
    gemmaService = GemmaService(client: mockClient);
  });

  group('GemmaService Tests', () {
    test('requiresCredits is false — on-device chat is free', () {
      expect(gemmaService.requiresCredits, isFalse);
    });

    test('supportsAttachments is false — Phase 1 is text-only', () {
      expect(gemmaService.supportsAttachments, isFalse);
    });

    test('sendMessage passes through client output', () async {
      when(
        () => mockClient.sendMessage(any()),
      ).thenAnswer((_) async => 'Hello from Gemma');

      final result = await gemmaService.sendMessage('Hi');

      expect(result, 'Hello from Gemma');
      verify(() => mockClient.sendMessage('Hi')).called(1);
    });

    test('sendMessage throws UnsupportedError on non-empty attachments', () {
      expect(
        () => gemmaService.sendMessage(
          'Hi',
          attachments: [AIAttachment('image/png', <int>[])],
        ),
        throwsUnsupportedError,
      );
      verifyNever(() => mockClient.sendMessage(any()));
    });

    test('streamMessage passes through client output', () async {
      when(() => mockClient.sendMessageStream(any())).thenAnswer(
        (_) => Stream.fromIterable(['chunk1', 'chunk2']),
      );

      final chunks = await gemmaService.streamMessage('Hi').toList();

      expect(chunks, ['chunk1', 'chunk2']);
    });

    test('streamMessage never yields the credit-exhausted sentinel', () async {
      when(() => mockClient.sendMessageStream(any())).thenAnswer(
        (_) => Stream.fromIterable(['some', 'response']),
      );

      final chunks = await gemmaService.streamMessage('Hi').toList();

      expect(chunks, isNot(contains('OUT_OF_CREDITS')));
    });

    test('streamMessage throws UnsupportedError on non-empty attachments', () {
      expect(
        () => gemmaService.streamMessage(
          'Hi',
          attachments: [AIAttachment('image/png', <int>[])],
        ),
        throwsUnsupportedError,
      );
      verifyNever(() => mockClient.sendMessageStream(any()));
    });

    test('generateStudyPlan throws UnimplementedError (Phase 2 scope)', () {
      expect(
        () => gemmaService.generateStudyPlan(tasks: const [], exams: const []),
        throwsUnimplementedError,
      );
    });

    test('generateQuiz throws UnimplementedError (Phase 3 scope)', () {
      expect(
        () => gemmaService.generateQuiz(
          null,
          difficulty: QuestionDifficulty.intermediate,
        ),
        throwsUnimplementedError,
      );
    });

    test('summarizePdf throws UnimplementedError (Phase 3 scope)', () {
      expect(() => gemmaService.summarizePdf(null), throwsUnimplementedError);
    });
  });
}
