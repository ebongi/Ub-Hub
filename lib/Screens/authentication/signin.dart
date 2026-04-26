import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_study/core/error_handler.dart';
import 'package:go_study/services/auth.dart';


// ── Design tokens (shared with splash) ──────────────────────────────────────
const Color _deepNavy = Color(0xFF080E1E);
const Color _cardNavy = Color(0xFF111D3D);
const Color _accentBlue = Color(0xFF3B82F6);
const Color _accentCyan = Color(0xFF06B6D4);
const Color _white = Colors.white;

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
        Tween<Offset>(begin: const Offset(0, -0.15), end: Offset.zero).animate(
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
    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
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
    final bgColor = isDark ? _deepNavy : const Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // ── Background atmosphere ──────────────────────────────────────
          const Positioned.fill(child: _BackgroundPainter()),

          // ── Content ───────────────────────────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),

                    // ── Header ─────────────────────────────────────────
                    SlideTransition(
                      position: _headerSlide,
                      child: FadeTransition(
                        opacity: _headerFade,
                        child: const _SignInHeader(),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // ── Form card ──────────────────────────────────────
                    SlideTransition(
                      position: _cardSlide,
                      child: FadeTransition(
                        opacity: _cardFade,
                        child: _FormCard(
                          emailController: _emailController,
                          passwordController: _passwordController,
                          viewPassword: _viewPassword,
                          isLoading: _isLoading,
                          onTogglePassword: () =>
                              setState(() => _viewPassword = !_viewPassword),
                          onSignIn: _handleSignIn,
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── Footer ─────────────────────────────────────────
                    FadeTransition(
                      opacity: _footerFade,
                      child: _SignInFooter(onToggle: widget.istoggle),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Background (orbs + dot grid) ─────────────────────────────────────────────
class _BackgroundPainter extends StatelessWidget {
  const _BackgroundPainter();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return CustomPaint(
      painter: _BgPainter(isDark: isDark),
      child: const SizedBox.expand(),
    );
  }
}

class _BgPainter extends CustomPainter {
  final bool isDark;
  _BgPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final orbOpacity1 = isDark ? 0.13 : 0.07;
    final orbOpacity2 = isDark ? 0.09 : 0.05;
    final dotOpacity = isDark ? 0.025 : 0.05;

    // Orb top-left
    final orbPaint1 = Paint()
      ..shader = RadialGradient(
        colors: [_accentBlue.withOpacity(orbOpacity1), Colors.transparent],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.1, size.height * 0.05),
          radius: 220,
        ),
      );
    canvas.drawCircle(
      Offset(size.width * 0.1, size.height * 0.05),
      220,
      orbPaint1,
    );

    // Orb bottom-right
    final orbPaint2 = Paint()
      ..shader = RadialGradient(
        colors: [_accentCyan.withOpacity(orbOpacity2), Colors.transparent],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.9, size.height * 0.85),
          radius: 260,
        ),
      );
    canvas.drawCircle(
      Offset(size.width * 0.9, size.height * 0.85),
      260,
      orbPaint2,
    );

    // Dot grid
    final dotPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withOpacity(dotOpacity);
    const spacing = 32.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BgPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

// ── Header section ────────────────────────────────────────────────────────────
class _SignInHeader extends StatelessWidget {
  const _SignInHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Brand wordmark
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [_accentBlue, _accentCyan],
          ).createShader(bounds),
          child: Text.rich(
            TextSpan(
              text: 'Go',
              style: GoogleFonts.outfit(
                fontSize: 48,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 3,
                height: 1,
              ),
              children: [
                TextSpan(
                  text: 'Study',
                  style: GoogleFonts.outfit(
                    fontSize: 48,
                    fontWeight: FontWeight.w300,
                    color: Colors.blue,
                    letterSpacing: 3,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Greeting
        Text(
          'Welcome\nback.',
          style: GoogleFonts.outfit(
            fontSize: 42,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).brightness == Brightness.dark
                ? _white
                : const Color(0xFF0F172A),
            height: 1.1,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Sign in to continue your academic journey.',
          style: GoogleFonts.outfit(
            fontSize: 15,
            color: (Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : const Color(0xFF0F172A))
                .withOpacity(0.45),
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
  final VoidCallback onTogglePassword;
  final VoidCallback onSignIn;

  const _FormCard({
    required this.emailController,
    required this.passwordController,
    required this.viewPassword,
    required this.isLoading,
    required this.onTogglePassword,
    required this.onSignIn,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? _cardNavy : Colors.white;
    final borderColor = isDark
        ? Colors.white.withOpacity(0.07)
        : Colors.black.withOpacity(0.05);

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: _accentBlue.withOpacity(isDark ? 0.12 : 0.08),
            blurRadius: 40,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Email
          _FieldLabel(label: 'Email address'),
          const SizedBox(height: 8),
          _GoTextField(
            controller: emailController,
            hint: 'you@example.com',
            icon: Icons.alternate_email_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please enter your email';
              return null;
            },
          ),

          const SizedBox(height: 22),

          // Password
          _FieldLabel(label: 'Password'),
          const SizedBox(height: 8),
          _GoTextField(
            controller: passwordController,
            hint: '••••••••',
            icon: Icons.lock_outline_rounded,
            obscureText: !viewPassword,
            suffixIcon: GestureDetector(
              onTap: onTogglePassword,
              child: Icon(
                viewPassword
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
                color: (Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : const Color(0xFF0F172A))
                    .withOpacity(0.35),
                size: 20,
              ),
            ),
            validator: (v) =>
                v == null || v.length < 6 ? 'Minimum 6 characters' : null,
          ),

          const SizedBox(height: 10),

          // Forgot password
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Forgot password?',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: _accentCyan.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          const SizedBox(height: 28),

          // Sign in button
          _SignInButton(isLoading: isLoading, onPressed: onSignIn),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      label,
      style: GoogleFonts.outfit(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: (isDark ? Colors.white : const Color(0xFF0F172A))
            .withOpacity(0.45),
        letterSpacing: 0.8,
      ),
    );
  }
}

class _GoTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const _GoTextField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: GoogleFonts.outfit(
        color: (Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : const Color(0xFF0F172A))
            .withOpacity(0.9),
        fontSize: 15,
      ),
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.outfit(
          color: (Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : const Color(0xFF0F172A))
              .withOpacity(0.2),
          fontSize: 15,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Icon(
            icon,
            color: (Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : const Color(0xFF0F172A))
                .withOpacity(0.3),
            size: 20,
          ),
        ),
        suffixIcon: suffixIcon != null
            ? Padding(
                padding: const EdgeInsets.only(right: 4),
                child: suffixIcon,
              )
            : null,
        filled: true,
        fillColor: (Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : const Color(0xFF0F172A))
            .withOpacity(0.05),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: (Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : const Color(0xFF0F172A))
                .withOpacity(0.08),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: (Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : const Color(0xFF0F172A))
                .withOpacity(0.08),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _accentBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
        errorStyle: GoogleFonts.outfit(
          color: const Color(0xFFEF4444),
          fontSize: 12,
        ),
      ),
    );
  }
}

class _SignInButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _SignInButton({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: isLoading
              ? LinearGradient(
                  colors: [
                    _accentBlue.withOpacity(0.5),
                    _accentCyan.withOpacity(0.5),
                  ],
                )
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_accentBlue, _accentCyan],
                ),
          boxShadow: isLoading
              ? []
              : [
                  BoxShadow(
                    color: _accentBlue.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
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
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  'Sign In',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      ),
    );
  }
}

// ── Footer ────────────────────────────────────────────────────────────────────
class _SignInFooter extends StatelessWidget {
  final Function onToggle;
  const _SignInFooter({required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Divider with OR
        Row(
          children: [
            Expanded(
              child: Divider(
                color: (Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : const Color(0xFF0F172A))
                    .withOpacity(0.08),
                thickness: 1,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'OR',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: (Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : const Color(0xFF0F172A))
                      .withOpacity(0.2),
                  letterSpacing: 2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: Divider(
                color: (Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : const Color(0xFF0F172A))
                    .withOpacity(0.08),
                thickness: 1,
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Don't have an account?",
                style: GoogleFonts.outfit(
                  color: (Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : const Color(0xFF0F172A))
                      .withOpacity(0.4),
                  fontSize: 14.5,
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => onToggle(),
                child: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [_accentBlue, _accentCyan],
                  ).createShader(bounds),
                  child: Text(
                    'Sign Up',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
