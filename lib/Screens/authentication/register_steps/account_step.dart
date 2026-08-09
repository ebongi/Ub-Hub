import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_study/l10n/generated/app_localizations.dart';
import 'package:go_study/Screens/authentication/register_form_widgets.dart';

class AccountStep extends StatelessWidget {
  const AccountStep({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.isPasswordObscured,
    required this.isConfirmPasswordObscured,
    required this.onTogglePassword,
    required this.onToggleConfirmPassword,
    required this.onPasswordChanged,
    required this.isDark,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool isPasswordObscured;
  final bool isConfirmPasswordObscured;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirmPassword;
  final ValueChanged<String> onPasswordChanged;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final password = passwordController.text;
    final strength = _strengthOf(password);
    final l10n = AppLocalizations.of(context)!;

    return Form(
      key: formKey,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RegistrationPageHeader(
              title: l10n.accountStepTitle,
              description: l10n.accountStepDescription,
              icon: Icons.lock_person_outlined,
              isDark: isDark,
            ),
            const SizedBox(height: 18),
            RegistrationSectionFocus(
              title: l10n.accountCredentialsTitle,
              subtitle: l10n.accountCredentialsSubtitle,
              icon: Icons.shield_outlined,
              isDark: isDark,
            ),
            const SizedBox(height: 20),
            RegistrationField(
              label: l10n.academicEmailLabel,
              hint: l10n.academicEmailHint,
              icon: Icons.alternate_email_rounded,
              controller: emailController,
              isDark: isDark,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                final email = v?.trim() ?? '';
                if (email.isEmpty) return l10n.pleaseEnterEmail;
                if (!RegExp(
                  r"^[a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
                ).hasMatch(email)) {
                  return l10n.pleaseEnterValidEmail;
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            RegistrationField(
              label: l10n.securePasswordLabel,
              hint: l10n.enterStrongPasswordHint,
              icon: Icons.lock_outline_rounded,
              controller: passwordController,
              isDark: isDark,
              obscureText: isPasswordObscured,
              onChanged: onPasswordChanged,
              suffixIcon: GestureDetector(
                onTap: onTogglePassword,
                child: Icon(
                  isPasswordObscured
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  color: regIconColor(isDark),
                  size: 20,
                ),
              ),
              validator: (v) {
                final value = v ?? '';
                if (value.isEmpty) return l10n.passwordRequired;
                if (value.length < 8) return l10n.minimumEightCharacters;
                if (!value.contains(RegExp(r'[A-Z]'))) {
                  return l10n.addUppercaseLetter;
                }
                if (!value.contains(RegExp(r'[0-9]'))) {
                  return l10n.addDigit;
                }
                if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
                  return l10n.addSpecialCharacter;
                }
                return null;
              },
            ),
            if (password.isNotEmpty) ...[
              const SizedBox(height: 16),
              _StrengthMeter(
                strength: strength,
                isDark: isDark,
              ),
            ],
            const SizedBox(height: 20),
            RegistrationField(
              label: l10n.confirmPasswordLabel,
              hint: l10n.repeatPasswordHint,
              icon: Icons.lock_reset_rounded,
              controller: confirmPasswordController,
              isDark: isDark,
              obscureText: isConfirmPasswordObscured,
              suffixIcon: GestureDetector(
                onTap: onToggleConfirmPassword,
                child: Icon(
                  isConfirmPasswordObscured
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  color: regIconColor(isDark),
                  size: 20,
                ),
              ),
              validator: (v) {
                if (v != passwordController.text) return l10n.passwordsDoNotMatch;
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  double _strengthOf(String password) {
    double value = 0;
    if (password.length >= 8) value += 0.25;
    if (password.contains(RegExp(r'[A-Z]'))) value += 0.25;
    if (password.contains(RegExp(r'[0-9]'))) value += 0.25;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) value += 0.25;
    return value;
  }
}

class _StrengthMeter extends StatelessWidget {
  const _StrengthMeter({
    required this.strength,
    required this.isDark,
  });

  final double strength;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final segments = (strength * 4).round().clamp(0, 4);
    final strengthColor = segments == 0 ? regBodyColor(isDark) : _getColor(segments);
    final emptyColor = regBorderColor(isDark);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: strengthColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: strengthColor.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.passwordSecurityLabel,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: regHeadingColor(isDark).withOpacity(0.7),
                ),
              ),
              Text(
                _label(l10n, segments),
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: strengthColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(4, (index) {
              final isFilled = index < segments;
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 5,
                  margin: EdgeInsets.only(right: index < 3 ? 6 : 0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: isFilled ? strengthColor : emptyColor.withOpacity(0.2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.passwordStrengthHint,
            style: GoogleFonts.outfit(
              fontSize: 11.5,
              color: regBodyColor(isDark),
            ),
          ),
        ],
      ),
    );
  }

  String _label(AppLocalizations l10n, int segments) {
    switch (segments) {
      case 1:
        return l10n.passwordStrengthWeak;
      case 2:
        return l10n.passwordStrengthFair;
      case 3:
        return l10n.passwordStrengthGood;
      case 4:
        return l10n.passwordStrengthStrong;
      default:
        return '—';
    }
  }

  Color _getColor(int segments) {
    switch (segments) {
      case 1:
        return const Color(0xFFEF4444);
      case 2:
        return const Color(0xFFF97316);
      case 3:
        return const Color(0xFFF59E0B);
      case 4:
        return regGreen;
      default:
        return Colors.transparent;
    }
  }
}
