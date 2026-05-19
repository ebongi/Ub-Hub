import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:go_study/services/payment_models.dart';
import 'package:go_study/core/app_config.dart';
import 'package:go_study/services/profile.dart';

/// Service for handling Campay integration
class CampayService {
  static String? _cachedToken;
  static DateTime? _tokenExpiryTime;

  // Base URL computed based on environment configuration
  static String get _baseUrl {
    final env = AppConfig.campayEnv.toLowerCase();
    if (env == 'production' || env == 'prod') {
      return 'https://campay.net';
    }
    return 'https://demo.campay.net';
  }

  /// Fetch access token dynamically or use the permanent dashboard token.
  static Future<String> _getAuthToken() async {
    // 1. If a permanent token is provided in configuration, use it directly.
    final permToken = AppConfig.campayToken;
    if (permToken.isNotEmpty) {
      return permToken;
    }

    // 2. Check if we have a valid cached token.
    if (_cachedToken != null &&
        _tokenExpiryTime != null &&
        DateTime.now().isBefore(_tokenExpiryTime!)) {
      return _cachedToken!;
    }

    // 3. Otherwise, fetch a new token dynamically.
    final username = AppConfig.campayUsername;
    final password = AppConfig.campayPassword;

    if (username.isEmpty || password.isEmpty) {
      throw Exception('Campay credentials (username/password or permanent token) are missing.');
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/token/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final token = data['token'] as String?;
        if (token == null || token.isEmpty) {
          throw Exception('Token not found in response');
        }

        _cachedToken = token;
        // Conservative 1-hour cache duration
        _tokenExpiryTime = DateTime.now().add(const Duration(hours: 1));

        return token;
      } else {
        throw Exception('Failed to get token (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      print('Campay Token Error: $e');
      rethrow;
    }
  }

  /// Collect payment from a phone number
  static Future<Map<String, dynamic>> collectPayment({
    required double amount,
    required String phoneNumber,
    String? description,
  }) async {
    try {
      final token = await _getAuthToken();
      final formattedPhone = formatPhoneNumber(phoneNumber);

      final response = await http.post(
        Uri.parse('$_baseUrl/api/collect/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        body: jsonEncode({
          'amount': amount.toInt().toString(),
          'currency': getCurrency(),
          'from': formattedPhone,
          'description': description ?? 'App Payment',
          'external_reference': generatePaymentRef(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final reference = data['reference'];
        // Provide 'id' and 'paymentId' key aliases for backward compatibility with screens
        return {
          ...data,
          'id': reference,
          'paymentId': reference,
        };
      } else {
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
      print('Campay Payment Error: $e');
      rethrow;
    }
  }

  /// Disburse payment to a phone number
  static Future<Map<String, dynamic>> disbursePayment({
    required double amount,
    required String phoneNumber,
    String? description,
  }) async {
    try {
      final token = await _getAuthToken();
      final formattedPhone = formatPhoneNumber(phoneNumber);

      final response = await http.post(
        Uri.parse('$_baseUrl/api/withdraw/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        body: jsonEncode({
          'amount': amount.toInt().toString(),
          'currency': getCurrency(),
          'phone_number': formattedPhone,
          'description': description ?? 'App Payout',
          'external_reference': generatePaymentRef(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final reference = data['reference'];
        // Provide 'id' and 'paymentId' key aliases for backward compatibility
        return {
          ...data,
          'id': reference,
          'paymentId': reference,
        };
      } else {
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
      print('Campay Payout Error: $e');
      rethrow;
    }
  }

  /// Check the status of a payment
  ///
  /// Returns the current status of a payment by its reference/ID.
  static Future<PaymentStatus> checkPaymentStatus(String paymentId) async {
    try {
      final token = await _getAuthToken();

      final response = await http.get(
        Uri.parse('$_baseUrl/api/transaction/$paymentId/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final status = data['status'] as String?;
        print('Campay Payment Status response: ${response.body}');
        print('Campay Payment Status check for $paymentId: $status');

        switch (status?.toUpperCase()) {
          case 'SUCCESSFUL':
          case 'SUCCESS':
          case 'COMPLETED':
          case 'VALIDATED':
            return PaymentStatus.success;
          case 'FAILED':
          case 'ERROR':
          case 'DENIED':
          case 'REJECTED':
            final reason = data['reason'] ?? status;
            throw Exception('Payment Failed: $reason');
          case 'CANCELLED':
          case 'CANCELED':
            return PaymentStatus.cancelled;
          case 'PENDING':
          case 'PROCESSING':
          case 'INITIATED':
          default:
            return PaymentStatus.pending;
        }
      } else {
        throw Exception('Failed to check payment status: ${response.body}');
      }
    } catch (e) {
      if (e.toString().contains('Payment Failed:')) {
        rethrow;
      }
      throw Exception('Failed to check payment status: $e');
    }
  }

  /// Poll for payment success with a timeout
  /// This gives the user time to approve the payment on their phone
  static Future<PaymentStatus> waitForSuccessfulPayment(
    String paymentId, {
    Duration timeout = const Duration(minutes: 2),
    Duration interval = const Duration(seconds: 5),
  }) async {
    final startTime = DateTime.now();
    while (DateTime.now().difference(startTime) < timeout) {
      try {
        final status = await checkPaymentStatus(paymentId);
        if (status == PaymentStatus.success ||
            status == PaymentStatus.cancelled) {
          return status;
        }
      } catch (e) {
        // Log error but keep polling if it's a network error
        if (kDebugMode) {
          print('Polling error: $e');
        }
      }
      await Future.delayed(interval);
    }
    return PaymentStatus.pending; // Timed out
  }

  /// Generate a unique payment reference
  static String generatePaymentRef() {
    return 'PAY_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Get the department creation fee amount
  static double getDepartmentCreationFee({UserRole? role}) {
    if (role == UserRole.admin) return 0.0;
    return 1000.0; // 1000 XAF
  }

  /// Get the document upload fee amount
  static double getDocumentUploadFee() {
    return 0.0; // Free
  }

  /// Get the document download fee amount
  static double getDocumentDownloadFee({UserRole? role}) {
    if (role == UserRole.contributor || role == UserRole.admin) {
      return 0.0; // Free for contributors
    }
    return 100.0; // 100 XAF for viewers
  }

  /// Get the past question download fee amount
  static double getPastQuestionDownloadFee({UserRole? role}) {
    if (role == UserRole.contributor || role == UserRole.admin) {
      return 0.0; // Free for contributors
    }
    return 100.0; // 100 XAF for viewers
  }

  /// Get the past question answer download fee amount
  static double getAnswerDownloadFee({UserRole? role}) {
    if (role == UserRole.contributor || role == UserRole.admin) {
      return 0.0; // Free for contributors
    }
    return 300.0; // 300 XAF for viewers
  }

  /// Get the contributor upgrade fee
  static double getContributorUpgradeFee() {
    return 5000.0; // 5000 XAF
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
