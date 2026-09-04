import 'package:animate_do/animate_do.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_study/core/error_handler.dart';
import 'package:go_study/l10n/generated/app_localizations.dart';
import 'package:go_study/services/auth.dart';
import 'package:go_study/Screens/authentication/register_form_widgets.dart';

class Signin extends StatefulWidget {
  final Authentication? authService;
  const Signin({super.key, required this.istoggle, this.authService});
  final Function istoggle;

  @override
  State<Signin> createState() => _SigninState();
}

class _SigninState extends State<Signin> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late final Authentication _authentication;
  bool _viewPassword = false;
  bool _isLoading = false;

  late AnimationController _entryController;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;
  late Animation<double> _cardFade;
  late Animation<Offset> _cardSlide;
  late Animation<double> _footerFade;

  @override
  void initState() {
    super.initState();
    _authentication = widget.authService ?? Authentication();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _headerFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    _headerSlide =
        Tween<Offset>(begin: const Offset(0, -0.12), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entryController,
            curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
          ),
        );

    _cardFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.25, 0.75, curve: Curves.easeOut),
      ),
    );
    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.10), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entryController,
            curve: const Interval(0.25, 0.75, curve: Curves.easeOut),
          ),
        );

    _footerFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.55, 1.0, curve: Curves.easeOut),
      ),
    );

    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (_isLoading) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    try {
      await _authentication.signUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } on sb.AuthException catch (e) {
      if (mounted) ErrorHandler.showErrorSnackBar(context, e);
    } catch (e) {
      if (mounted) ErrorHandler.showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: regBgColor(isDark),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // ── Brand chip ─────────────────────────────────────────────
                SlideTransition(
                  position: _headerSlide,
                  child: FadeTransition(
                    opacity: _headerFade,
                    child: _BrandChip(isDark: isDark),
                  ),
                ),

                const SizedBox(height: 32),

                // ── Heading ────────────────────────────────────────────────
                SlideTransition(
                  position: _headerSlide,
                  child: FadeTransition(
                    opacity: _headerFade,
                    child: _SignInHeader(isDark: isDark),
                  ),
                ),

                const SizedBox(height: 32),

                // ── Form card ──────────────────────────────────────────────
                SlideTransition(
                  position: _cardSlide,
                  child: FadeTransition(
                    opacity: _cardFade,
                    child: _FormCard(
                      emailController: _emailController,
                      passwordController: _passwordController,
                      viewPassword: _viewPassword,
                      isLoading: _isLoading,
                      isDark: isDark,
                      onTogglePassword: () =>
                          setState(() => _viewPassword = !_viewPassword),
                      onSignIn: _handleSignIn,
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // ── Footer ─────────────────────────────────────────────────
                FadeTransition(
                  opacity: _footerFade,
                  child: _SignInFooter(onToggle: widget.istoggle, isDark: isDark),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Brand chip ────────────────────────────────────────────────────────────────
class _BrandChip extends StatelessWidget {
  final bool isDark;
  const _BrandChip({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: regIndigo(context),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.school_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        Text.rich(
          TextSpan(
            text: 'Go',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: regIndigo(context),
              letterSpacing: 0.2,
            ),
            children: [
              TextSpan(
                text: 'Study',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w400,
                  color: isDark ? Colors.white.withOpacity(0.8) : regSlate700,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Header section ────────────────────────────────────────────────────────────
class _SignInHeader extends StatelessWidget {
  final bool isDark;
  const _SignInHeader({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.signInWelcomeBack,
          style: GoogleFonts.outfit(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: regHeadingColor(isDark),
            height: 1.15,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.signInSubtitle,
          style: GoogleFonts.outfit(
            fontSize: 14.5,
            color: regBodyColor(isDark),
            fontWeight: FontWeight.w400,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

// ── Form card ─────────────────────────────────────────────────────────────────
class _FormCard extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool viewPassword;
  final bool isLoading;
  final bool isDark;
  final VoidCallback onTogglePassword;
  final VoidCallback onSignIn;

  const _FormCard({
    required this.emailController,
    required this.passwordController,
    required this.viewPassword,
    required this.isLoading,
    required this.isDark,
    required this.onTogglePassword,
    required this.onSignIn,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: regSurfaceColor(isDark),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: regBorderColor(isDark), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Email
          FadeInDown(
            duration: const Duration(milliseconds: 350),
            delay: const Duration(milliseconds: 50),
            child: _EduField(
              label: l10n.emailAddressLabel,
              hint: l10n.emailAddressHint,
              icon: Icons.alternate_email_rounded,
              controller: emailController,
              isDark: isDark,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return l10n.pleaseEnterEmail;
                }
                return null;
              },
            ),
          ),

          const SizedBox(height: 20),

          // Password
          FadeInDown(
            duration: const Duration(milliseconds: 350),
            delay: const Duration(milliseconds: 120),
            child: _EduField(
              label: l10n.passwordLabel,
              hint: '••••••••',
              icon: Icons.lock_outline_rounded,
              controller: passwordController,
              isDark: isDark,
              obscureText: !viewPassword,
              suffixIcon: GestureDetector(
                onTap: onTogglePassword,
                child: Icon(
                  viewPassword
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                  color: regIconColor(isDark),
                  size: 20,
                ),
              ),
              validator: (v) =>
                  v == null || v.length < 6 ? l10n.minimumSixCharacters : null,
            ),
          ),

          const SizedBox(height: 8),

          // Forgot password
          FadeInDown(
            duration: const Duration(milliseconds: 350),
            delay: const Duration(milliseconds: 180),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  l10n.forgotPassword,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: regIndigo(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Sign in button
          FadeInDown(
            duration: const Duration(milliseconds: 350),
            delay: const Duration(milliseconds: 230),
            child: _PrimaryButton(
              label: l10n.signInButton,
              isLoading: isLoading,
              onPressed: onSignIn,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable educational field ─────────────────────────────────────────────────
class _EduField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final bool isDark;
  final bool obscureText;
  final TextInputType keyboardType;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const _EduField({
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    required this.isDark,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white.withOpacity(0.7) : regSlate700,
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          style: GoogleFonts.outfit(
            fontSize: 15,
            color: isDark ? Colors.white.withOpacity(0.9) : regSlate900,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.outfit(
              fontSize: 15,
              color: isDark ? Colors.white.withOpacity(0.2) : regSlate300,
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
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: regBorderColor(isDark)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: regBorderColor(isDark)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: regIndigo(context), width: 1.8),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.6),
            ),
            errorStyle: GoogleFonts.outfit(
              color: const Color(0xFFEF4444),
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Primary button ─────────────────────────────────────────────────────────────
class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onPressed;

  const _PrimaryButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: regIndigo(context),
          disabledBackgroundColor: regIndigo(context).withOpacity(0.55),
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
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
            : Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
      ),
    );
  }
}

// ── Footer ────────────────────────────────────────────────────────────────────
class _SignInFooter extends StatelessWidget {
  final Function onToggle;
  final bool isDark;
  const _SignInFooter({required this.onToggle, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        // OR divider
        Row(
          children: [
            Expanded(
              child: Divider(
                color: regBorderColor(isDark),
                thickness: 1,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                l10n.orDivider,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: regBodyColor(isDark),
                  letterSpacing: 2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: Divider(
                color: regBorderColor(isDark),
                thickness: 1,
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Sign up link
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.noAccountPrompt,
                style: GoogleFonts.outfit(
                  color: regBodyColor(isDark),
                  fontSize: 14.5,
                ),
              ),
              const SizedBox(width: 5),
              GestureDetector(
                onTap: () => onToggle(),
                child: Text(
                  l10n.signUpLink,
                  style: GoogleFonts.outfit(
                    color: regIndigo(context),
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),
      ],
    );
  }
}
