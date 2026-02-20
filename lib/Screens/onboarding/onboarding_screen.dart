import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  Future<void> _onIntroEnd(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstLaunch', false);
    if (context.mounted) {
      Navigator.of(context).pushReplacementNamed('/auth');
    }
  }

  Widget _buildImage(String assetName, [double width = 350]) {
    return Image.asset('assets/images/$assetName', width: width);
  }

  @override
  Widget build(BuildContext context) {
    final pageDecoration = PageDecoration(
      titleTextStyle: GoogleFonts.outfit(
        fontSize: 28.0,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
      bodyTextStyle: GoogleFonts.outfit(fontSize: 18.0, color: Colors.white70),
      bodyPadding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
      pageColor: const Color(0xFF030E22), // Deep midnight blue
      imagePadding: EdgeInsets.zero,
    );

    return IntroductionScreen(
      globalBackgroundColor: const Color(0xFF030E22),
      allowImplicitScrolling: true,
      pages: [
        PageViewModel(
          title: "Welcome to Ub Studies",
          body:
              "Your ultimate academic companion for the University of Buea. Stay organized and excel in your studies.",
          image: _buildImage('4.png'),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "Track Your Progress",
          body: "Stay focused using our advanced 3D study timer.",
          image: _buildImage('2.png'),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "Resource Hub",
          body:
              "Access department materials, past questions, and important academic updates all in one place.",
          image: _buildImage('3.png'),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "Connect & Collaborate",
          body:
              "Join the global chat to discuss with peers and use our AI assistant for instant study help.",
          image: _buildImage('1.png'),
          decoration: pageDecoration,
        ),
      ],
      onDone: () => _onIntroEnd(context),
      onSkip: () =>
          _onIntroEnd(context), // You can also override onSkip callback
      showSkipButton: true,
      skipOrBackFlex: 0,
      nextFlex: 0,
      showBackButton: false,
      //rtl: true, // Display as right-to-left
      back: const Icon(Icons.arrow_back, color: Colors.cyanAccent),
      skip: const Text(
        'Skip',
        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.cyanAccent),
      ),
      next: const Icon(Icons.arrow_forward, color: Colors.cyanAccent),
      done: const Text(
        'Done',
        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.cyanAccent),
      ),
      curve: Curves.fastLinearToSlowEaseIn,
      controlsMargin: const EdgeInsets.all(16),
      controlsPadding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      dotsDecorator: const DotsDecorator(
        size: Size(10.0, 10.0),
        color: Color(0xFFBDBDBD),
        activeSize: Size(22.0, 10.0),
        activeColor: Colors.cyanAccent,
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(25.0)),
        ),
      ),
    );
  }
}
