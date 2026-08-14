import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_study/services/gemma_client.dart';

void main() {
  group('unwrapModelResponseText', () {
    test('extracts token from TextResponse', () {
      expect(unwrapModelResponseText(const TextResponse('hello')), 'hello');
    });

    test('returns empty string for FunctionCallResponse', () {
      expect(
        unwrapModelResponseText(
          const FunctionCallResponse(name: 'foo', args: {}),
        ),
        '',
      );
    });

    test('returns empty string for ThinkingResponse', () {
      expect(
        unwrapModelResponseText(const ThinkingResponse('thinking...')),
        '',
      );
    });
  });

  group('shouldStopForLength', () {
    test('false below the limit', () {
      expect(shouldStopForLength(100, limit: 4000), isFalse);
    });

    test('true at or above the limit', () {
      expect(shouldStopForLength(4000, limit: 4000), isTrue);
      expect(shouldStopForLength(5000, limit: 4000), isTrue);
    });

    test('uses gemmaMaxResponseChars as the default limit', () {
      expect(shouldStopForLength(gemmaMaxResponseChars - 1), isFalse);
      expect(shouldStopForLength(gemmaMaxResponseChars), isTrue);
    });
  });
}
