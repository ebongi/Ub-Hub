import 'package:animate_do/animate_do.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_study/core/app_wordmark.dart';
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
                const SizedBox(height: 20),

                // ── Wordmark ───────────────────────────────────────────────
                SlideTransition(
                  position: _headerSlide,
                  child: FadeTransition(
                    opacity: _headerFade,
                    child: const AppWordmark(fontSize: 20),
                  ),
                ),

                const SizedBox(height: 36),

                // ── Heading ────────────────────────────────────────────────
                SlideTransition(
                  position: _headerSlide,
                  child: FadeTransition(
                    opacity: _headerFade,
                    child: _SignInHeader(isDark: isDark),
                  ),
                ),

                const SizedBox(height: 32),

                // ── Fields ─────────────────────────────────────────────────
                SlideTransition(
                  position: _cardSlide,
                  child: FadeTransition(
                    opacity: _cardFade,
                    child: _SignInFields(
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

// ── Fields ────────────────────────────────────────────────────────────────────
class _SignInFields extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool viewPassword;
  final bool isLoading;
  final bool isDark;
  final VoidCallback onTogglePassword;
  final VoidCallback onSignIn;

  const _SignInFields({
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeInDown(
          duration: const Duration(milliseconds: 350),
          delay: const Duration(milliseconds: 50),
          child: RegistrationField(
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

        FadeInDown(
          duration: const Duration(milliseconds: 350),
          delay: const Duration(milliseconds: 120),
          child: RegistrationField(
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

        FadeInDown(
          duration: const Duration(milliseconds: 350),
          delay: const Duration(milliseconds: 230),
          child: AuthPrimaryButton(
            label: l10n.signInButton,
            isLoading: isLoading,
            onPressed: onSignIn,
          ),
        ),
      ],
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
    return Center(
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
    );
  }
}
