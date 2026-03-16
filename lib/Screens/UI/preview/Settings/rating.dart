import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_study/Screens/Shared/premium_dialog.dart';

// Since this is just a dialog logic, we can make it a function or a simple widget
Future<void> showRatingDialog(BuildContext context) async {
  return showPremiumGeneralDialog(
    context: context,
    barrierLabel: "Rate Us",
    child: Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
          surfaceTintColor: Colors.transparent,
          contentPadding: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const PremiumDialogHeader(
                title: "Rate Us!",
                subtitle: "Help us improve Ub-Hub",
                icon: Icons.star_rounded,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  children: [
                    Text(
                      "If you enjoy using Ub-Hub, please take a moment to rate us. Your feedback is invaluable!",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        color: isDark ? Colors.white70 : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: Text("Later",
                                style: GoogleFonts.outfit(
                                    color: isDark ? Colors.white38 : Colors.grey[500],
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: PremiumSubmitButton(
                            label: "Rate Now",
                            isLoading: false,
                            onPressed: () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Thank you for your rating! ⭐"),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}
