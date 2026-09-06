import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_study/Screens/authentication/wrap.dart';
import 'package:go_study/Screens/onboarding/onboarding_screen.dart';
import 'package:go_study/core/app_assets.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SplashScreen extends StatefulWidget {
  final bool isFirstLaunch;

  const SplashScreen({super.key, required this.isFirstLaunch});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _totalDuration = Duration(milliseconds: 2600);
  static const _navigateAfter = Duration(milliseconds: 3000);

  // Timeline, as fractions of _totalDuration:
  //   0.00 - 0.19  "G" emblem revealed left-to-right (wipe)
  //   0.19 - 0.31  stationary hold
  //   0.31 - 0.54  "oStudy" fades in while sliding slightly left-to-right
  //   0.54 - 0.77  tagline revealed left-to-right (wipe)
  //   0.77 - 1.00  final hold: complete lockup sits static
  late final AnimationController _controller;
  late final Animation<double> _iconReveal;
  late final Animation<double> _textFade;
  late final Animation<double> _textSlide;
  late final Animation<double> _taglineReveal;
  late final Timer _timer;
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();

    _controller = AnimationController(vsync: this, duration: _totalDuration)
      ..forward();

    _iconReveal = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.19, curve: Curves.easeInOut),
    );

    _textFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.31, 0.54, curve: Curves.easeOut),
    );

    _textSlide = Tween<double>(begin: -16, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.31, 0.54, curve: Curves.easeOutCubic),
      ),
    );

    _taglineReveal = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.54, 0.77, curve: Curves.easeInOut),
    );

    _timer = Timer(_navigateAfter, () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, animation, __) {
            return widget.isFirstLaunch
                ? const OnboardingScreen()
                : const AuthWrapper();
          },
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 350),
        ),
      );
    });
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() {
        _version = info.version;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _version = '';
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _controller.dispose();
    super.dispose();
  }

  // Clips `child` to a rectangle growing from its left edge, without
  // altering the space `child` reserves in its parent - so the reveal
  // never shifts sibling widgets or the surrounding layout.
  Widget _leftWipe({required Animation<double> reveal, required Widget child}) {
    return AnimatedBuilder(
      animation: reveal,
      builder: (context, c) => ClipRect(
        clipper: _LeftWipeClipper(reveal.value),
        child: c,
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _leftWipe(
                      reveal: _iconReveal,
                      child: Image.asset(
                        AppAssets.logo,
                        width: 78,
                        height: 78,
                        fit: BoxFit.contain,
                        cacheWidth: 200,
                      ),
                    ),
                    const SizedBox(width: 4),
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) => Opacity(
                        opacity: _textFade.value,
                        child: Transform.translate(
                          offset: Offset(_textSlide.value, 0),
                          child: child,
                        ),
                      ),
                      child: Text(
                        'oStudy',
                        style: GoogleFonts.outfit(
                          fontSize: 42,
                          fontWeight: FontWeight.w800,
                          fontStyle: FontStyle.italic,
                          color: const Color(0xFF1656D8),
                          height: 1.0,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _leftWipe(
                  reveal: _taglineReveal,
                  child: Text(
                    'Your Smart Learning Partner',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF6B7A99),
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_version.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: 24,
              child: Center(
                child: Text(
                  'v$_version',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF9AA5B8),
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LeftWipeClipper extends CustomClipper<Rect> {
  const _LeftWipeClipper(this.progress);

  final double progress;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(0, 0, size.width * progress, size.height);

  @override
  bool shouldReclip(covariant _LeftWipeClipper oldClipper) =>
      oldClipper.progress != progress;
}
