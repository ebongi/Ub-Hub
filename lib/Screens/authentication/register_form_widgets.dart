import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_study/theme/app_spacing.dart';

Color regIndigo(BuildContext context) => Theme.of(context).colorScheme.primary;
const Color regSlate900 = Color(0xFF0F172A);
const Color regSlate700 = Color(0xFF334155);
const Color regSlate500 = Color(0xFF64748B);
const Color regSlate300 = Color(0xFFCBD5E1);
const Color regSlate100 = Color(0xFFF1F5F9);
const Color regGreen = Color(0xFF10B981);

Color regBgColor(bool isDark) =>
    isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
Color regSurfaceColor(bool isDark) =>
    isDark ? const Color(0xFF1E293B) : Colors.white;
Color regHeadingColor(bool isDark) => isDark ? Colors.white : regSlate900;
Color regBodyColor(bool isDark) =>
    isDark ? Colors.white.withOpacity(0.55) : regSlate500;
Color regBorderColor(bool isDark) =>
    isDark ? Colors.white.withOpacity(0.14) : regSlate300;
Color regFieldFill(bool isDark) =>
    isDark ? Colors.white.withOpacity(0.04) : Colors.white;
Color regIconColor(bool isDark) =>
    isDark ? Colors.white.withOpacity(0.4) : regSlate500;

class RegistrationField extends StatelessWidget {
  const RegistrationField({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    required this.isDark,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.suffixIcon,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
  });

  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final bool isDark;
  final bool obscureText;
  final TextInputType keyboardType;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final primary = regIndigo(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white.withOpacity(0.75) : regSlate700,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLines: maxLines,
          validator: validator,
          onChanged: onChanged,
          style: GoogleFonts.outfit(
            fontSize: 15,
            color: isDark ? Colors.white.withOpacity(0.95) : regSlate900,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.outfit(
              fontSize: 15,
              color: isDark ? Colors.white.withOpacity(0.25) : regSlate300,
            ),
            prefixIcon: Icon(icon, color: regIconColor(isDark), size: 19),
            suffixIcon: suffixIcon != null
                ? Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: suffixIcon,
                  )
                : null,
            filled: true,
            fillColor: regFieldFill(isDark),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: regBorderColor(isDark), width: 1.2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: regBorderColor(isDark), width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
            ),
            errorStyle: GoogleFonts.outfit(
              color: const Color(0xFFEF4444),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class RegistrationDropdown<T> extends StatelessWidget {
  const RegistrationDropdown({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.value,
    required this.isDark,
    required this.items,
    required this.onChanged,
    this.validator,
    this.showLabel = true,
  });

  final String label;
  final String hint;
  final IconData icon;
  final T? value;
  final bool isDark;
  final bool showLabel;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? Function(T?)? validator;

  @override
  Widget build(BuildContext context) {
    final primary = regIndigo(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel && label.isNotEmpty) ...[
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white.withOpacity(0.75) : regSlate700,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        DropdownButtonFormField<T>(
          isExpanded: true,
          value: value is String && (value as String).isEmpty ? null : value,
          items: items,
          onChanged: onChanged,
          validator: validator,
          dropdownColor: regSurfaceColor(isDark),
          icon: Icon(Icons.expand_more_rounded, color: regIconColor(isDark)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.outfit(
              fontSize: 15,
              color: isDark ? Colors.white.withOpacity(0.25) : regSlate300,
            ),
            prefixIcon: Icon(icon, color: regIconColor(isDark), size: 19),
            filled: true,
            fillColor: regFieldFill(isDark),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: regBorderColor(isDark), width: 1.2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: regBorderColor(isDark), width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
            ),
            errorStyle: GoogleFonts.outfit(
              color: const Color(0xFFEF4444),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

/// Shared full-width primary CTA for the auth flow (Login / Proceed /
/// Register), so all three read as one consistent button family. Pass
/// [trailingIcon] for "Proceed"-style continue actions (matches the design
/// reference); leave it null for terminal actions like Login/Register.
class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.isLoading,
    required this.onPressed,
    this.trailingIcon,
  });

  final String label;
  final bool isLoading;
  final VoidCallback onPressed;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    final primary = regIndigo(context);
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          disabledBackgroundColor: primary.withOpacity(0.55),
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.outfit(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                  if (trailingIcon != null) ...[
                    const SizedBox(width: 8),
                    Icon(trailingIcon, size: 18, color: Colors.white),
                  ],
                ],
              ),
      ),
    );
  }
}

/// Two-node segmented tracker with a centered current-step label, echoing
/// the design reference's dashed "step name on the line" progress marker.
class AuthStepTracker extends StatelessWidget {
  const AuthStepTracker({
    super.key,
    required this.currentStep,
    required this.stepLabels,
    required this.isDark,
  });

  final int currentStep;
  final List<String> stepLabels;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final primary = regIndigo(context);
    final pending = regBorderColor(isDark);

    Widget node(int index) {
      final done = index <= currentStep;
      return Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: done ? primary : Colors.transparent,
          border: Border.all(color: done ? primary : pending, width: 1.6),
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            node(0),
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                color: currentStep >= 1 ? primary : pending,
              ),
            ),
            node(1),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          stepLabels[currentStep],
          style: GoogleFonts.outfit(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: primary,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}
