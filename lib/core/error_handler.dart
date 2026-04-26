import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class ErrorHandler {
  /// Translates a raw exception into a user-friendly message.
  static String getFriendlyMessage(dynamic error) {
    if (error is PostgrestException) {
      // Handle specific Supabase Database errors
      switch (error.code) {
        case '42501':
          return 'Permission denied. You don\'t have access to perform this action.';
        case '23505':
          return 'This record already exists.';
        case 'PGRST204':
          return 'A required database column is missing. Please contact support.';
        default:
          return 'Database error: ${error.message}';
      }
    }

    if (error is AuthException) {
      // Handle Supabase Auth errors
      return error.message;
    }

    if (error is SocketException || error.toString().contains('SocketException')) {
      return 'No internet connection. Please check your network.';
    }

    if (error is TimeoutException || error.toString().contains('timed out')) {
      return 'The request took too long. Please try again.';
    }

    if (error is String) {
      return error;
    }

    // Default fallback
    final errorStr = error.toString();
    if (errorStr.contains('PostgrestException')) {
      return 'Database operation failed. Please try again later.';
    }

    return 'Something went wrong. Please try again.';
  }

  /// Displays a stylized, friendly error snackbar.
  static void showErrorSnackBar(BuildContext context, dynamic error) {
    final message = getFriendlyMessage(error);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.redAccent.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
        elevation: 0,
      ),
    );
  }

  /// Displays a success snackbar for consistency.
  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
        elevation: 0,
      ),
    );
  }
}
