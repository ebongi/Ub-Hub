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
            child: Text(
              "Welcome to GO Study",
              textAlign: TextAlign.center,
              style: pageDecoration.titleTextStyle,
            ),
          ),
          bodyWidget: FadeInUp(
            key: ValueKey('body_0_$_currentPage'),
            duration: const Duration(milliseconds: 500),
            child: Text(
              "Welcome to Your Campus, Anytime.Everything you need to study smarter, collaborate faster, and achieve more — all in one place.",
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
          titleWidget: FadeInRight(
            key: ValueKey('title_2_$_currentPage'),
            duration: const Duration(milliseconds: 500),
            child: Text(
              "Access All Your Materials",
              textAlign: TextAlign.center,
              style: pageDecoration.titleTextStyle,
            ),
          ),
          bodyWidget: FadeInLeft(
            key: ValueKey('body_2_$_currentPage'),
            duration: const Duration(milliseconds: 500),
            child: Text(
              "Access department materials, past questions, and important academic updates all in one place.",
              textAlign: TextAlign.center,
              style: pageDecoration.bodyTextStyle,
            ),
          ),
          image: FadeInDown(
            key: ValueKey('img_2_$_currentPage'),
            duration: const Duration(milliseconds: 600),
            child: _buildImage('library.svg', 600),
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
              "Share notes, collaborate on assignments, and chat with coursemates — all within one space. Create or join study groups organized by course, topic, or department..",
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
      skip: Text(
        'Skip',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: colorScheme.primary,
        ),
      ),
      next: Icon(Icons.arrow_forward, color: colorScheme.primary),
      done: Text(
        'Done',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: colorScheme.primary,
        ),
      ),
      curve: Curves.fastLinearToSlowEaseIn,
      controlsMargin: const EdgeInsets.all(16),
      controlsPadding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      dotsDecorator: DotsDecorator(
        size: const Size(10.0, 10.0),
        color: theme.brightness == Brightness.dark
            ? Colors.white24
            : Colors.black12,
        activeSize: const Size(22.0, 10.0),
        activeColor: colorScheme.primary,
        activeShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(25.0)),
        ),
      ),
    );
  }
}
