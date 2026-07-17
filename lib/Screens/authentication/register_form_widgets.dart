import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
    isDark ? Colors.white.withOpacity(0.1) : regSlate300;
Color regFieldFill(bool isDark) =>
    isDark ? Colors.white.withOpacity(0.06) : regSlate100;
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
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white.withOpacity(0.8) : regSlate700,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLines: maxLines,
          validator: validator,
          onChanged: onChanged,
          style: GoogleFonts.outfit(
            fontSize: 15.5,
            color: isDark ? Colors.white.withOpacity(0.95) : regSlate900,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.outfit(
              fontSize: 15,
              color: isDark ? Colors.white.withOpacity(0.25) : regSlate300,
            ),
            prefixIcon: Icon(icon, color: primary.withOpacity(0.7), size: 20),
            suffixIcon: suffixIcon != null
                ? Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: suffixIcon,
                  )
                : null,
            filled: true,
            fillColor: regFieldFill(isDark),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 18,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: regBorderColor(isDark)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  BorderSide(color: regBorderColor(isDark).withOpacity(0.8)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: Color(0xFFEF4444), width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
            ),
            errorStyle: GoogleFonts.outfit(
              color: const Color(0xFFEF4444),
              fontSize: 12.5,
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
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white.withOpacity(0.8) : regSlate700,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 8),
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
            prefixIcon: Icon(icon, color: primary.withOpacity(0.7), size: 20),
            filled: true,
            fillColor: regFieldFill(isDark),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 18,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: regBorderColor(isDark)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  BorderSide(color: regBorderColor(isDark).withOpacity(0.8)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: Color(0xFFEF4444), width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
            ),
            errorStyle: GoogleFonts.outfit(
              color: const Color(0xFFEF4444),
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class RegistrationPageHeader extends StatelessWidget {
  const RegistrationPageHeader({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.isDark,
  });

  final String title;
  final String description;
  final IconData icon;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final primary = regIndigo(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: regSurfaceColor(isDark),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: regBorderColor(isDark).withOpacity(0.6)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primary, primary.withOpacity(0.75)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: regHeadingColor(isDark),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.outfit(
                    fontSize: 12.8,
                    height: 1.45,
                    color: regBodyColor(isDark),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RegistrationSectionFocus extends StatelessWidget {
  const RegistrationSectionFocus({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isDark,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: regIndigo(context).withOpacity(isDark ? 0.12 : 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: regIndigo(context).withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: regIndigo(context),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: regHeadingColor(isDark),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(
                    fontSize: 12.5,
                    height: 1.4,
                    color: regBodyColor(isDark),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
