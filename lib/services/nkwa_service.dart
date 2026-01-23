import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:neo/services/payment_models.dart';

/// Service for handling Nkwa Pay integration
class NkwaService {
  // Nkwa API credentials
  static const String _apiKey = 'G2ufFuh77jUEwQN_CBRy_';
  static const String _stagingUrl = 'https://api.pay.staging.mynkwa.com';
  static const String _productionUrl = 'https://api.pay.mynkwa.com';

  // Use staging for now, switch to production when ready
  static const String _baseUrl = _stagingUrl;

  /// Collect payment from a phone number
  ///
  /// This initiates a mobile money payment collection.
  /// The user will receive a prompt on their phone to confirm the payment.
  static Future<Map<String, dynamic>> collectPayment({
    required double amount,
    required String phoneNumber,
    String? description,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/collect'),
        headers: {'Content-Type': 'application/json', 'X-API-KEY': _apiKey},
        body: jsonEncode({
          'amount': amount.toInt(),
          'phoneNumber': phoneNumber,
          if (description != null) 'description': description,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data as Map<String, dynamic>;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(
          'Payment collection failed: ${error['message'] ?? response.body}',
        );
      }
    } catch (e) {
      throw Exception('Failed to collect payment: $e');
    }
  }

  /// Check the status of a payment
  ///
  /// Returns the current status of a payment by its ID.
  /// Status can be: pending, success, failed, canceled
  static Future<PaymentStatus> checkPaymentStatus(String paymentId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/payments/$paymentId'),
        headers: {'X-API-KEY': _apiKey},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final status = data['status'] as String?;

        switch (status?.toLowerCase()) {
          case 'success':
          case 'successful':
            return PaymentStatus.success;
          case 'failed':
            return PaymentStatus.failed;
          case 'canceled':
          case 'cancelled':
            return PaymentStatus.cancelled;
          default:
            return PaymentStatus.pending;
        }
      } else {
        throw Exception('Failed to check payment status: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to check payment status: $e');
    }
  }

  /// Generate a unique payment reference
  static String generatePaymentRef() {
    return 'PAY_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Get the department creation fee amount
  static double getDepartmentCreationFee() {
    return 100.0; // 100 XAF
  }

  /// Get the currency code
  static String getCurrency() {
    return 'XAF'; // Central African Franc
  }

  /// Validate phone number format (Cameroon)
  /// Expected format: 237XXXXXXXXX (12 digits total)
  static bool isValidPhoneNumber(String phoneNumber) {
    // Remove any spaces or special characters
    final cleaned = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    // Should start with 237 and be 12 digits total
    return cleaned.startsWith('237') && cleaned.length == 12;
  }

  /// Format phone number to Cameroon format
  /// Adds 237 prefix if not present
  static String formatPhoneNumber(String phoneNumber) {
    final cleaned = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    if (cleaned.startsWith('237')) {
      return cleaned;
    } else if (cleaned.startsWith('6')) {
      // Cameroon mobile numbers start with 6
      return '237$cleaned';
    } else {
      return cleaned;
    }
  }
}
