import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_study/Screens/authentication/register_form_widgets.dart';
import 'package:go_study/Screens/UI/preview/Settings/privacy_policy_screen.dart';
import 'package:go_study/Screens/UI/preview/Settings/terms_of_service_screen.dart';
import 'package:go_study/l10n/generated/app_localizations.dart';
import 'package:go_study/theme/app_spacing.dart';

class FinalizeStep extends StatelessWidget {
  const FinalizeStep({
    super.key,
    required this.formKey,
    required this.bioController,
    required this.agreedToTerms,
    required this.onAgreedToTermsChanged,
    required this.isDark,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController bioController;
  final bool agreedToTerms;
  final ValueChanged<bool> onAgreedToTermsChanged;
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
              title: l10n.finalizeStepTitle,
              description: l10n.finalizeStepDescription,
              icon: Icons.check_circle_outline_rounded,
              isDark: isDark,
            ),
            const SizedBox(height: 18),
            RegistrationSectionFocus(
              title: l10n.finalizeProfileTitle,
              subtitle: l10n.finalizeProfileSubtitle,
              icon: Icons.assignment_ind_outlined,
              isDark: isDark,
            ),
            const SizedBox(height: AppSpacing.xl),
            RegistrationField(
              label: l10n.academicBioLabel,
              hint: l10n.academicBioHint,
              icon: Icons.description_outlined,
              controller: bioController,
              isDark: isDark,
              maxLines: 3,
            ),
            const SizedBox(height: AppSpacing.xxl),
            FormField<bool>(
              initialValue: agreedToTerms,
              validator: (value) => (value ?? false)
                  ? null
                  : l10n.agreeToTermsRequired,
              builder: (field) {
                void toggle(bool value) {
                  onAgreedToTermsChanged(value);
                  field.didChange(value);
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: agreedToTerms,
                          onChanged: (val) => toggle(val ?? false),
                          activeColor: regIndigo(context),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => toggle(!agreedToTerms),
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: const EdgeInsets.only(top: AppSpacing.md),
                              child: Wrap(
                                children: [
                                  Text(
                                    l10n.agreeToTermsPrefix,
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      color: regBodyColor(isDark),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const TermsOfServiceScreen(),
                                      ),
                                    ),
                                    child: Text(
                                      l10n.termsOfServiceLink,
                                      style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: regIndigo(context),
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    l10n.andSeparator,
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      color: regBodyColor(isDark),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const PrivacyPolicyScreen(),
                                      ),
                                    ),
                                    child: Text(
                                      l10n.privacyPolicyLink,
                                      style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: regIndigo(context),
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '.',
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      color: regBodyColor(isDark),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (field.hasError)
                      Padding(
                        padding: const EdgeInsets.only(
                          left: AppSpacing.md,
                          top: AppSpacing.xs,
                        ),
                        child: Text(
                          field.errorText!,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: const Color(0xFFEF4444),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
