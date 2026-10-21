import 'package:flutter/material.dart';
import 'package:go_study/l10n/generated/app_localizations.dart';
import 'package:go_study/locale_provider.dart';
import 'package:go_study/theme/app_radius.dart';
import 'package:go_study/theme/app_text_styles.dart';

/// "Set Your App Language" dialog: centered icon, bold title, body text,
/// then the language choices, then a Cancel button — matching the
/// reference dialog's chrome while keeping the app's existing in-app
/// locale picker (this app manages locale itself rather than deferring to
/// OS language settings like Coursera does).
void showAppLanguageDialog(
  BuildContext context,
  LocaleProvider localeProvider,
  AppLocalizations l10n,
) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sheet)),
      contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.language_rounded, size: 40, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              l10n.appLanguageTitle,
              textAlign: TextAlign.center,
              style: AppText.sectionTitle(context).copyWith(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.appLanguageSubtitle,
              textAlign: TextAlign.center,
              style: AppText.body(context),
            ),
            const SizedBox(height: 12),
            RadioListTile<Locale?>(
              title: Text(l10n.languageSystemDefault),
              value: null,
              groupValue: localeProvider.locale,
              onChanged: (value) {
                localeProvider.setLocale(value);
                Navigator.pop(context);
              },
            ),
            RadioListTile<Locale?>(
              title: Text(l10n.languageEnglish),
              value: const Locale('en'),
              groupValue: localeProvider.locale,
              onChanged: (value) {
                localeProvider.setLocale(value);
                Navigator.pop(context);
              },
            ),
            RadioListTile<Locale?>(
              title: Text(l10n.languageFrench),
              value: const Locale('fr'),
              groupValue: localeProvider.locale,
              onChanged: (value) {
                localeProvider.setLocale(value);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            l10n.cancel,
            style: AppText.body(context).copyWith(
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}
