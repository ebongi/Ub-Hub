import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_study/Screens/Shared/premium_dialog.dart';
import 'package:go_study/core/error_handler.dart';
import 'package:go_study/l10n/generated/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

const String _kPlayStoreUrl =
    "https://play.google.com/store/apps/details?id=com.ebongsume.gostudy";

Future<void> _launchStoreListing(BuildContext context) async {
  final uri = Uri.parse(_kPlayStoreUrl);
  try {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw "Could not open the Play Store";
    }
  } catch (e) {
    if (context.mounted) ErrorHandler.showErrorSnackBar(context, e);
  }
}

// Since this is just a dialog logic, we can make it a function or a simple widget
Future<void> showRatingDialog(BuildContext context) async {
  return showPremiumGeneralDialog(
    context: context,
    barrierLabel: AppLocalizations.of(context)!.rateUsBarrierLabel,
    child: Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final l10n = AppLocalizations.of(context)!;

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
              PremiumDialogHeader(
                title: l10n.rateUsTitle,
                subtitle: l10n.helpUsImproveSubtitle,
                icon: Icons.star_rounded,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  children: [
                    Text(
                      l10n.rateUsBody,
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
                            child: Text(l10n.laterButton,
                                style: GoogleFonts.outfit(
                                    color: isDark ? Colors.white38 : Colors.grey[500],
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: PremiumSubmitButton(
                            label: l10n.rateNowButton,
                            isLoading: false,
                            onPressed: () {
                              Navigator.pop(context);
                              _launchStoreListing(context);
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
