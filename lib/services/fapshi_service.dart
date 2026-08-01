import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:go_study/services/payment_models.dart';
import 'package:go_study/core/app_config.dart';
import 'package:go_study/services/profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:io';

/// Service for handling Fapshi integration (Direct Pay)
class FapshiService {
  
  static String get _baseUrl {
    final env = AppConfig.fapshiEnv.toLowerCase();
    if (env == 'production' || env == 'prod' || env == 'live') {
      return 'https://live.fapshi.com';
    }
    return 'https://sandbox.fapshi.com';
  }

  /// Collect payment using Fapshi Direct Pay (USSD Push)
  static Future<Map<String, dynamic>> collectPayment({
    required double amount,
    required String phoneNumber,
    String? email,
    String? description,
  }) async {
    try {
      final apiUser = AppConfig.fapshiApiUser.trim();
      final apiKey = AppConfig.fapshiApiKey.trim();

      if (apiUser.isEmpty || apiKey.isEmpty) {
        throw Exception('Fapshi credentials (API User or API Key) are missing.');
      }

      final formattedPhone = formatPhoneNumber(phoneNumber);
      final externalId = generatePaymentRef();

      final response = await http.post(
        Uri.parse('$_baseUrl/direct-pay'),
        headers: {
          'Content-Type': 'application/json',
          'apiuser': apiUser,
          'apikey': apiKey,
        },
        body: jsonEncode({
          'amount': amount.toInt(),
          'phone': formattedPhone,
          'email': email ?? 'customer@gostudy.app',
          'externalId': externalId,
          'message': description ?? 'GoStudy Payment',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        // Fapshi returns {'transId': '...'} on success
        final transId = data['transId'];
        return {
          ...data,
          'id': transId,
          'paymentId': transId,
          'externalId': externalId,
        };
      } else if (response.statusCode == 403) {
        // Fallback to Initiate Pay if Direct Pay is forbidden
        return await initiatePayment(
          amount: amount,
          phoneNumber: phoneNumber,
          email: email,
          description: description,
        );
      } else {
        String errorMessage;
        try {
          final error = jsonDecode(response.body);
          errorMessage = error['message'] ?? response.body;
        } catch (_) {
          errorMessage = response.body;
        }
        throw Exception('Fapshi API Error (${response.statusCode}): $errorMessage');
      }
    } catch (e) {
      if (kDebugMode) print('Fapshi Payment Error: $e');
      rethrow;
    }
  }

  /// Initiate payment using Fapshi Hosted Checkout (Redirect)
  static Future<Map<String, dynamic>> initiatePayment({
    required double amount,
    required String phoneNumber,
    String? email,
    String? description,
  }) async {
    try {
      final apiUser = AppConfig.fapshiApiUser.trim();
      final apiKey = AppConfig.fapshiApiKey.trim();

      final response = await http.post(
        Uri.parse('$_baseUrl/initiate-pay'),
        headers: {
          'Content-Type': 'application/json',
          'apiuser': apiUser,
          'apikey': apiKey,
        },
        body: jsonEncode({
          'amount': amount.toInt(),
          'phone': formatPhoneNumber(phoneNumber),
          'email': email ?? 'customer@gostudy.app',
          'externalId': generatePaymentRef(),
          'message': description ?? 'GoStudy Payment',
          'userId': Supabase.instance.client.auth.currentUser?.id ?? 'anonymous',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        // Initiate pay returns {'link': '...', 'transId': '...'}
        return {
          ...data,
          'id': data['transId'],
          'paymentId': data['transId'],
          'redirectUrl': data['link'],
        };
      } else {
        throw Exception('Fapshi API Error (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) print('Fapshi Initiate Error: $e');
      rethrow;
    }
  }

  /// Check the status of a payment
  static Future<PaymentStatus> checkPaymentStatus(String transId) async {
    try {
      final apiUser = AppConfig.fapshiApiUser.trim();
      final apiKey = AppConfig.fapshiApiKey.trim();

      final response = await http.get(
        Uri.parse('$_baseUrl/payment-status/$transId'),
        headers: {
          'apiuser': apiUser,
          'apikey': apiKey,
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final status = data['status'] as String?;
        
        if (kDebugMode) {
          print('Fapshi Status Check for $transId: $status');
        }

        switch (status?.toUpperCase()) {
          case 'SUCCESSFUL':
            return PaymentStatus.success;
          case 'FAILED':
            throw Exception('Payment Failed: ${data['reason'] ?? 'Unknown error'}');
          case 'EXPIRED':
            return PaymentStatus.cancelled;
          case 'PENDING':
          default:
            return PaymentStatus.pending;
        }
      } else {
        throw Exception('Failed to check Fapshi status: ${response.body}');
      }
    } on SocketException catch (e) {
      if (kDebugMode) print('Fapshi Network Error: $e');
      throw Exception('Network error: Please check your internet connection.');
    } catch (e) {
      if (e.toString().contains('Payment Failed:')) rethrow;
      throw Exception('Failed to check payment status: $e');
    }
  }

  /// Poll for payment success with network resilience
  static Future<PaymentStatus> waitForSuccessfulPayment(
    String transId, {
    Duration timeout = const Duration(minutes: 5),
    Function(String)? onStatusUpdate,
  }) async {
    final startTime = DateTime.now();
    int retrySeconds = 5;

    while (DateTime.now().difference(startTime) < timeout) {
      try {
        // 1. Check physical connectivity first
        final connectivityResult = await Connectivity().checkConnectivity();
        if (connectivityResult.contains(ConnectivityResult.none)) {
          onStatusUpdate?.call("Offline: Waiting for internet...");
          await Future.delayed(const Duration(seconds: 5));
          continue;
        }

        // 2. Attempt to check status
        final status = await checkPaymentStatus(transId);
        
        if (status == PaymentStatus.success || status == PaymentStatus.cancelled) {
          return status;
        }
        
        // Reset retry delay on successful API reach
        retrySeconds = 5;
        onStatusUpdate?.call("Waiting for payment approval...");

      } catch (e) {
        if (e.toString().contains('Payment Failed:')) rethrow;
        
        // 3. Handle network/timeout errors with backoff
        if (kDebugMode) print('Fapshi Polling error: $e');
        onStatusUpdate?.call("Connection issue: Retrying in ${retrySeconds}s...");
        
        await Future.delayed(Duration(seconds: retrySeconds));
        // Exponential backoff up to 30 seconds
        retrySeconds = (retrySeconds * 1.5).toInt().clamp(5, 30);
        continue;
      }
      
      await Future.delayed(Duration(seconds: retrySeconds));
    }
    return PaymentStatus.pending;
  }

  /// Generate a unique payment reference
  static String generatePaymentRef() {
    return 'FS_${DateTime.now().millisecondsSinceEpoch}';
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
  /// Expected format: 6XXXXXXXX or 237XXXXXXXXX
  static bool isValidPhoneNumber(String phoneNumber) {
    final cleaned = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.length == 9 && cleaned.startsWith('6')) return true;
    return cleaned.startsWith('237') && cleaned.length == 12;
  }

  /// Format phone number to local format (9 digits) for Fapshi API
  static String formatPhoneNumber(String phoneNumber) {
    final cleaned = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.startsWith('237') && cleaned.length == 12) {
      return cleaned.substring(3);
    }
    return cleaned;
  }
}
