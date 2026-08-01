import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
        
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
          title: Row(
            children: [
              Icon(Icons.lock_clock_outlined, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Text(
                "AI Credits Required",
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "You have run out of AI credits. Upgrade to a premium plan or top up your credits to continue using Gemini Academic.",
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
                title: Text("Get 50 Credits", style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                subtitle: Text("Only 500 XAF", style: GoogleFonts.outfit(fontSize: 12)),
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
              child: Text("Not Now", style: GoogleFonts.outfit(color: Colors.grey)),
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
              child: Text("Top Up", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    return proceed ?? false;
  }
}
