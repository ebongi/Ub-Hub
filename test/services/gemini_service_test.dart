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

      expect(result, contains('Gemini Error:'));
    });
  });
}
