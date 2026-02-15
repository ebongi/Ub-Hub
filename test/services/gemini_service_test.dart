import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:neo/services/gemini_service.dart';
import 'package:neo/services/gemini_client.dart';

class MockGeminiClient extends Mock implements GeminiClient {}

void main() {
  late GeminiService geminiService;
  late MockGeminiClient mockClient;

  setUp(() {
    mockClient = MockGeminiClient();
    geminiService = GeminiService(client: mockClient);
  });

  group('GeminiService Tests', () {
    test('sendMessage should return response text on success', () async {
      when(
        () => mockClient.sendMessage(any()),
      ).thenAnswer((_) async => 'Hello from AI');

      final result = await geminiService.sendMessage('Hi');

      expect(result, 'Hello from AI');
    });

    test('sendMessage should return error message on exception', () async {
      when(
        () => mockClient.sendMessage(any()),
      ).thenThrow(Exception('API Error'));

      final result = await geminiService.sendMessage('Hi');

      expect(result, contains('error connecting to the AI service:'));
    });

    test(
      'generateStudyPlan should call sendMessage with formatted prompt',
      () async {
        when(
          () => mockClient.sendMessage(any()),
        ).thenAnswer((_) async => 'Mocked Study Plan');

        final result = await geminiService.generateStudyPlan(
          tasks: [],
          exams: [],
        );

        expect(result, 'Mocked Study Plan');
        verify(
          () => mockClient.sendMessage(
            any(that: contains('expert academic advisor')),
          ),
        ).called(1);
      },
    );

    test(
      'generateQuiz should call sendMessage with formatted prompt',
      () async {
        when(
          () => mockClient.sendMessage(any()),
        ).thenAnswer((_) async => '{"questions": []}');

        final result = await geminiService.generateQuiz('History of Cameroon');

        expect(result, '{"questions": []}');
        verify(
          () => mockClient.sendMessage(any(that: contains('expert educator'))),
        ).called(1);
      },
    );

    test(
      'summarizePdf should call sendMessageStream and return summary',
      () async {
        when(
          () => mockClient.sendMessageStream(
            any(),
            attachments: any(named: 'attachments'),
          ),
        ).thenAnswer((_) => Stream.fromIterable(['This is ', 'a summary']));

        final result = await geminiService.summarizePdf(Uint8List(0));

        expect(result, 'This is a summary');
        verify(
          () => mockClient.sendMessageStream(
            any(that: contains('academic assistant')),
            attachments: any(named: 'attachments'),
          ),
        ).called(1);
      },
    );
  });
}
