import 'package:flutter/material.dart';
import 'package:go_study/l10n/generated/app_localizations.dart';
import 'package:go_study/Screens/authentication/register_form_widgets.dart';

class IdentityStep extends StatelessWidget {
  const IdentityStep({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.phoneController,
    required this.isDark,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Form(
      key: formKey,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RegistrationPageHeader(
              title: l10n.identityStepTitle,
              description: l10n.identityStepDescription,
              icon: Icons.badge_outlined,
              isDark: isDark,
            ),
            const SizedBox(height: 18),
            RegistrationSectionFocus(
              title: l10n.personalIdentityTitle,
              subtitle: l10n.personalIdentitySubtitle,
              icon: Icons.person_pin_outlined,
              isDark: isDark,
            ),
            const SizedBox(height: 20),
            RegistrationField(
              label: l10n.fullLegalNameLabel,
              hint: l10n.firstLastNameHint,
              icon: Icons.person_outline_rounded,
              controller: nameController,
              isDark: isDark,
              validator: (v) =>
                  v == null || v.isEmpty ? l10n.fullNameRequired : null,
            ),
            const SizedBox(height: 24),
            RegistrationField(
              label: l10n.phoneContactLabel,
              hint: '+237 ...',
              icon: Icons.phone_android_rounded,
              controller: phoneController,
              isDark: isDark,
              keyboardType: TextInputType.phone,
              validator: (v) =>
                  v == null || v.isEmpty ? l10n.phoneRequired : null,
            ),
          ],
        ),
      ),
    );
  }
}
