import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_study/l10n/generated/app_localizations.dart';

/// Shared "this view failed to load" state: icon + friendly title + optional
/// retry button. Pass an already-friendly [title] (e.g. from
/// `ErrorHandler.getFriendlyMessage`) — never a raw exception/`snapshot.error`.
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    this.title,
    this.icon = Icons.error_outline_rounded,
    this.onRetry,
    this.retryLabel,
    this.compact = false,
  });

  final String? title;
  final IconData icon;
  final VoidCallback? onRetry;
  final String? retryLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? 16 : 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: compact ? 44 : 60,
              color: Colors.red.withOpacity(0.5),
            ),
            SizedBox(height: compact ? 10 : 14),
            Text(
              title ?? 'Something went wrong. Please try again.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: compact ? 15 : 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (onRetry != null) ...[
              SizedBox(height: compact ? 14 : 20),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(retryLabel ?? l10n.retryButton),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
