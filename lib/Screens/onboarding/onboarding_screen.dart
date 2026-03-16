import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_svg/flutter_svg.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentPage = 0;

  Future<void> _onIntroEnd(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstLaunch', false);
    if (context.mounted) {
      Navigator.of(context).pushReplacementNamed('/auth');
    }
  }

  Widget _buildImage(String assetName, [double width = 350]) {
    if (assetName.endsWith('.svg')) {
      return SvgPicture.asset('assets/images/$assetName', width: width);
    }
    return Image.asset('assets/images/$assetName', width: width);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final pageDecoration = PageDecoration(
      titleTextStyle: GoogleFonts.outfit(
        fontSize: 28.0,
        fontWeight: FontWeight.w700,
        color:
            textTheme.headlineMedium?.color ??
            (theme.brightness == Brightness.dark
                ? Colors.white
                : Colors.black87),
      ),
      bodyTextStyle: GoogleFonts.outfit(
        fontSize: 18.0,
        color:
            textTheme.bodyLarge?.color?.withOpacity(0.7) ??
            (theme.brightness == Brightness.dark
                ? Colors.white70
                : Colors.black54),
      ),
      bodyPadding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
      pageColor: theme.scaffoldBackgroundColor,
      imagePadding: const EdgeInsets.only(bottom: 0.0),
      titlePadding: const EdgeInsets.only(top: 0.0, bottom: 8.0),
      bodyAlignment: Alignment.center,
      imageAlignment: Alignment.center,
    );

    return IntroductionScreen(
      globalBackgroundColor: theme.scaffoldBackgroundColor,
      allowImplicitScrolling: true,
      onChange: (index) {
        setState(() {
          _currentPage = index;
        });
      },
      pages: [
        PageViewModel(
          titleWidget: FadeInDown(
            key: ValueKey('title_0_$_currentPage'),
            duration: const Duration(milliseconds: 500),
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF4285F4), Color(0xFF9B72F3)],
              ).createShader(bounds),
              child: Text(
                "Welcome to GO Study",
                textAlign: TextAlign.center,
                style: pageDecoration.titleTextStyle.copyWith(color: Colors.white),
              ),
            ),
          ),
          bodyWidget: FadeInUp(
            key: ValueKey('body_0_$_currentPage'),
            duration: const Duration(milliseconds: 500),
            child: Text(
              "Your Campus, Anytime. Everything you need to study smarter, collaborate faster, and achieve more — all in one place.",
              textAlign: TextAlign.center,
              style: pageDecoration.bodyTextStyle,
            ),
          ),
          image: ZoomIn(
            key: ValueKey('img_0_$_currentPage'),
            duration: const Duration(milliseconds: 600),
            child: _buildImage('logoicon.svg', 500),
          ),
          decoration: pageDecoration,
        ),
        PageViewModel(
          titleWidget: FadeInDown(
            key: ValueKey('title_tailored_$_currentPage'),
            duration: const Duration(milliseconds: 500),
            child: Text(
              "Tailored for You",
              textAlign: TextAlign.center,
              style: pageDecoration.titleTextStyle,
            ),
          ),
          bodyWidget: FadeInUp(
            key: ValueKey('body_tailored_$_currentPage'),
            duration: const Duration(milliseconds: 500),
            child: Text(
              "Select your university and enjoy a customized experience with your departments, courses, and campus news.",
              textAlign: TextAlign.center,
              style: pageDecoration.bodyTextStyle,
            ),
          ),
          image: ZoomIn(
            key: ValueKey('img_tailored_$_currentPage'),
            duration: const Duration(milliseconds: 600),
            child: Icon(
              Icons.school_rounded,
              size: 180,
              color: colorScheme.primary,
            ),
          ),
          decoration: pageDecoration,
        ),
        PageViewModel(
          titleWidget: FadeInDown(
            key: ValueKey('title_ai_$_currentPage'),
            duration: const Duration(milliseconds: 500),
            child: Text(
              "Premium AI Assistant",
              textAlign: TextAlign.center,
              style: pageDecoration.titleTextStyle,
            ),
          ),
          bodyWidget: FadeInUp(
            key: ValueKey('body_ai_$_currentPage'),
            duration: const Duration(milliseconds: 500),
            child: Text(
              "Access powerful AI tools to summarize notes, generate study plans, and help you master difficult topics.",
              textAlign: TextAlign.center,
              style: pageDecoration.bodyTextStyle,
            ),
          ),
          image: ZoomIn(
            key: ValueKey('img_ai_$_currentPage'),
            duration: const Duration(milliseconds: 600),
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF4285F4), Color(0xFF9B72F3)],
              ).createShader(bounds),
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: 180,
                color: Colors.white,
              ),
            ),
          ),
          decoration: pageDecoration,
        ),
        PageViewModel(
          titleWidget: FadeInDown(
            key: ValueKey('title_3_$_currentPage'),
            duration: const Duration(milliseconds: 500),
            child: Text(
              "Connect & Collaborate",
              textAlign: TextAlign.center,
              style: pageDecoration.titleTextStyle,
            ),
          ),
          bodyWidget: FadeInUp(
            key: ValueKey('body_3_$_currentPage'),
            duration: const Duration(milliseconds: 500),
            child: Text(
              "Share notes, collaborate on assignments, and chat with coursemates in dedicated study groups.",
              textAlign: TextAlign.center,
              style: pageDecoration.bodyTextStyle,
            ),
          ),
          image: ZoomIn(
            key: ValueKey('img_3_$_currentPage'),
            duration: const Duration(milliseconds: 600),
            child: _buildImage('colob.svg', 600),
          ),
          decoration: pageDecoration,
        ),
      ],
      onDone: () => _onIntroEnd(context),
      onSkip: () => _onIntroEnd(context),
      showSkipButton: true,
      skipOrBackFlex: 0,
      nextFlex: 0,
      showBackButton: false,
      back: Icon(Icons.arrow_back, color: colorScheme.primary),
      skip: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'Skip',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            color: colorScheme.primary,
          ),
        ),
      ),
      next: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
      ),
      done: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4285F4), Color(0xFF9B72F3)],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4285F4).withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          'Get Started',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      curve: Curves.fastLinearToSlowEaseIn,
      controlsMargin: const EdgeInsets.all(24),
      controlsPadding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      dotsDecorator: DotsDecorator(
        size: const Size(8.0, 8.0),
        color: theme.brightness == Brightness.dark
            ? Colors.white24
            : Colors.black12,
        activeSize: const Size(24.0, 8.0),
        activeColor: colorScheme.primary,
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25.0),
        ),
      ),
    );
  }
}
