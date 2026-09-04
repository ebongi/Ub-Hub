import 'package:flutter/material.dart';
import 'package:go_study/l10n/generated/app_localizations.dart';
import 'package:go_study/theme/app_radius.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centered grey pill — "You can send up to N more messages" — driven by the
/// user's remaining AI credits. Renders nothing when the user has unlimited
/// access (admin or an active Unlimited AI subscription).
class MessageQuotaPill extends StatelessWidget {
  const MessageQuotaPill({
    super.key,
    required this.count,
    this.unlimited = false,
  });

  final int count;
  final bool unlimited;

  @override
  Widget build(BuildContext context) {
    if (unlimited) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(AppRadius.chip),
        ),
        child: Text(
          l10n.assistantMessagesRemaining(count < 0 ? 0 : count),
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ),
    );
  }
}
