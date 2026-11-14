import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_study/Screens/authentication/register_form_widgets.dart';
import 'package:go_study/Screens/UI/preview/Settings/privacy_policy_screen.dart';
import 'package:go_study/Screens/UI/preview/Settings/terms_of_service_screen.dart';
import 'package:go_study/l10n/generated/app_localizations.dart';
import 'package:go_study/theme/app_spacing.dart';

/// Step 2 of sign-up: academic affiliation + finalizing the profile (was
/// the separate Academic and Finalize steps, merged to match the 2-step
/// design reference).
class AcademicDetailsStep extends StatelessWidget {
  const AcademicDetailsStep({
    super.key,
    required this.formKey,
    required this.phoneController,
    required this.matriculeController,
    required this.bioController,
    required this.selectedLevel,
    required this.onLevelChanged,
    required this.agreedToTerms,
    required this.onAgreedToTermsChanged,
    required this.isDark,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController phoneController;
  final TextEditingController matriculeController;
  final TextEditingController bioController;
  final String selectedLevel;
  final ValueChanged<String?> onLevelChanged;
  final bool agreedToTerms;
  final ValueChanged<bool> onAgreedToTermsChanged;
  final bool isDark;

  static const _levelCodes = ['200', '300', '400', 'Resit'];

  String _levelDisplayName(AppLocalizations l10n, String code) =>
      code == 'Resit' ? l10n.academicLevelResit : code;

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
            const SizedBox(height: AppSpacing.xl),
            RegistrationField(
              label: l10n.studentMatriculeLabel,
              hint: l10n.officialUniversityIdHint,
              icon: Icons.badge_outlined,
              controller: matriculeController,
              isDark: isDark,
              validator: (v) =>
                  v == null || v.isEmpty ? l10n.matriculeRequired : null,
            ),
            const SizedBox(height: AppSpacing.xl),
            RegistrationDropdown<String>(
              label: l10n.currentAcademicLevelLabel,
              hint: l10n.selectYourLevelHint,
              icon: Icons.trending_up_rounded,
              value: selectedLevel,
              isDark: isDark,
              items: _levelCodes
                  .map(
                    (code) => DropdownMenuItem<String>(
                      value: code,
                      child: Text(
                        _levelDisplayName(l10n, code),
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          color: regHeadingColor(isDark),
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: onLevelChanged,
              validator: (val) =>
                  val == null || val.isEmpty ? l10n.pleaseSelectLevel : null,
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
            _TermsCheckbox(
              agreedToTerms: agreedToTerms,
              onAgreedToTermsChanged: onAgreedToTermsChanged,
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }
}

class _TermsCheckbox extends StatelessWidget {
  const _TermsCheckbox({
    required this.agreedToTerms,
    required this.onAgreedToTermsChanged,
    required this.isDark,
  });

  final bool agreedToTerms;
  final ValueChanged<bool> onAgreedToTermsChanged;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FormField<bool>(
      initialValue: agreedToTerms,
      validator: (value) =>
          (value ?? false) ? null : l10n.agreeToTermsRequired,
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
    );
  }
}
