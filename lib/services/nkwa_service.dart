import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:neo/services/payment_models.dart';
import 'package:neo/core/app_config.dart';

/// Service for handling Nkwa Pay integration
class NkwaService {
  // Nkwa API credentials from environment
  static String get _apiKey => AppConfig.nkwaApiKey;

  // Base URLs
  static const String _stagingUrl = 'https://api.pay.staging.mynkwa.com';
  static const String _productionUrl = 'https://api.pay.mynkwa.com';

  // Default to production as most users use production keys
  static String get _baseUrl => _productionUrl;

  /// Collect payment from a phone number
  static Future<Map<String, dynamic>> collectPayment({
    required double amount,
    required String phoneNumber,
    String? description,
  }) async {
    try {
      if (_apiKey.isEmpty) {
        throw Exception('Nkwa API Key is missing. Check .env');
      }

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
        // Try to decode JSON error, otherwise use raw body
        String errorMessage;
        try {
          final error = jsonDecode(response.body);
          errorMessage = error['message'] ?? response.body;
        } catch (_) {
          errorMessage = response.body;
        }

        throw Exception('API Error (${response.statusCode}): $errorMessage');
      }
    } catch (e) {
      print('Nkwa Payment Error: $e');
      rethrow;
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
        print('Nkwa Payment Status response: ${response.body}');
        print('Nkwa Payment Status check for $paymentId: $status');

        switch (status?.toLowerCase()) {
          case 'success':
          case 'successful':
          case 'completed':
          case 'validated':
            return PaymentStatus.success;
          case 'failed':
          case 'error':
          case 'denied':
          case 'rejected':
            final reason = data['reason'] ?? status;
            throw Exception('Payment Failed: $reason');
          case 'canceled':
          case 'cancelled':
            return PaymentStatus.cancelled;
          case 'pending':
          case 'processing':
          case 'initiated':
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
    return 1000.0; // 1000 XAF
  }

  /// Get the document upload fee amount
  static double getDocumentUploadFee() {
    return 0.0; // Free
  }

  /// Get the document download fee amount
  static double getDocumentDownloadFee() {
    return 150.0; // 150 XAF
  }

  /// Get the past question download fee amount
  static double getPastQuestionDownloadFee() {
    return 150.0; // 150 XAF
  }

  /// Get the past question answer download fee amount
  static double getAnswerDownloadFee() {
    return 300.0; // 300 XAF
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

    // Should start with 237 (12 digits) OR be 9 digits (likely starting with 6)
    if (cleaned.length == 9) return true;
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
