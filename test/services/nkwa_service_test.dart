import 'package:flutter_test/flutter_test.dart';
import 'package:neo/services/nkwa_service.dart';

void main() {
  group('NkwaService Tests', () {
    test('Phone number validation - valid Cameroon numbers', () {
      expect(NkwaService.isValidPhoneNumber('677123456'), isTrue);
      expect(NkwaService.isValidPhoneNumber('237677123456'), isTrue);
    });

    test('Phone number validation - invalid numbers', () {
      expect(NkwaService.isValidPhoneNumber('123456'), isFalse);
      expect(NkwaService.isValidPhoneNumber('abc123456'), isFalse);
    });

    test('Phone number formatting', () {
      expect(NkwaService.formatPhoneNumber('677123456'), '237677123456');
      expect(NkwaService.formatPhoneNumber('237677123456'), '237677123456');
    });

    test('Payment reference generation', () {
      final ref = NkwaService.generatePaymentRef();
      expect(ref.startsWith('PAY_'), isTrue);
      expect(ref.length, greaterThan(10));
    });

    test('Fee calculation', () {
      expect(NkwaService.getDepartmentCreationFee(), 100.0);
      expect(NkwaService.getDocumentUploadFee(), 50.0);
    });
  });
}
