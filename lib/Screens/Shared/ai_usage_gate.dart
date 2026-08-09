import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_study/l10n/generated/app_localizations.dart';
import 'package:go_study/services/profile.dart';
import 'package:go_study/Screens/UI/preview/Settings/subscription_plans_screen.dart';

class AIUsageGate {
  static Future<bool> checkAndShow(BuildContext context, UserProfile profile) async {
    if (profile.canUseAI) return true;

    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final l10n = AppLocalizations.of(context)!;

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
          title: Row(
            children: [
              Icon(Icons.lock_clock_outlined, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Text(
                l10n.aiCreditsRequiredTitle,
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.outOfAiCreditsBody,
                style: GoogleFonts.outfit(fontSize: 15),
              ),
              const SizedBox(height: 24),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.bolt_rounded, color: Colors.amber),
                ),
                title: Text(l10n.get50CreditsTitle, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                subtitle: Text(l10n.only500XafSubtitle, style: GoogleFonts.outfit(fontSize: 12)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SubscriptionPlansScreen(userProfile: profile)),
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.notNowButton, style: GoogleFonts.outfit(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SubscriptionPlansScreen(userProfile: profile)),
                );
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(l10n.topUpButton, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    return proceed ?? false;
  }
}
