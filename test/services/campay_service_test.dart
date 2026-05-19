import 'package:flutter_test/flutter_test.dart';
import 'package:go_study/services/campay_service.dart';

void main() {
  group('CampayService Tests', () {
    test('Phone number validation - valid Cameroon numbers', () {
      expect(CampayService.isValidPhoneNumber('677123456'), isTrue);
      expect(CampayService.isValidPhoneNumber('237677123456'), isTrue);
    });

    test('Phone number validation - invalid numbers', () {
      expect(CampayService.isValidPhoneNumber('123456'), isFalse);
      expect(CampayService.isValidPhoneNumber('abc123456'), isFalse);
    });

    test('Phone number formatting', () {
      expect(CampayService.formatPhoneNumber('677123456'), '237677123456');
      expect(CampayService.formatPhoneNumber('237677123456'), '237677123456');
    });

    test('Payment reference generation', () {
      final ref = CampayService.generatePaymentRef();
      expect(ref.startsWith('PAY_'), isTrue);
      expect(ref.length, greaterThan(10));
    });

    test('Fee calculation', () {
      expect(CampayService.getDepartmentCreationFee(), 1000.0);
      expect(CampayService.getDocumentUploadFee(), 0.0);
      expect(CampayService.getDocumentDownloadFee(), 100.0);
      expect(CampayService.getPastQuestionDownloadFee(), 100.0);
      expect(CampayService.getAnswerDownloadFee(), 300.0);
      expect(CampayService.getContributorUpgradeFee(), 5000.0);
    });
  });
}
