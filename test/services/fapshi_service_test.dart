import 'package:flutter_test/flutter_test.dart';
import 'package:go_study/services/fapshi_service.dart';

void main() {
  group('FapshiService Tests', () {
    test('Phone number validation - valid Cameroon numbers', () {
      expect(FapshiService.isValidPhoneNumber('677123456'), isTrue);
      expect(FapshiService.isValidPhoneNumber('237677123456'), isTrue);
    });

    test('Phone number validation - invalid numbers', () {
      expect(FapshiService.isValidPhoneNumber('123456'), isFalse);
      expect(FapshiService.isValidPhoneNumber('abc123456'), isFalse);
    });

    test('Phone number formatting - returns 9 digits for Fapshi', () {
      expect(FapshiService.formatPhoneNumber('677123456'), '677123456');
      expect(FapshiService.formatPhoneNumber('237677123456'), '677123456');
    });

    test('Payment reference generation', () {
      final ref = FapshiService.generatePaymentRef();
      expect(ref.startsWith('FS_'), isTrue);
      expect(ref.length, greaterThan(10));
    });

    test('Fee calculation', () {
      expect(FapshiService.getDepartmentCreationFee(), 1000.0);
      expect(FapshiService.getDocumentUploadFee(), 0.0);
      expect(FapshiService.getDocumentDownloadFee(), 100.0);
      expect(FapshiService.getPastQuestionDownloadFee(), 100.0);
      expect(FapshiService.getAnswerDownloadFee(), 300.0);
      expect(FapshiService.getContributorUpgradeFee(), 5000.0);
    });
  });
}
