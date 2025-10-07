import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:neo/Screens/authentication/wrap.dart';
import 'Shared/constanst.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return IntroductionScreen(
      globalBackgroundColor: Colors.white,

      /// The various onboarding pages, introducing the basic functionalities of the application
      pages: [
        PageViewModel(
          title: "Welcome to Neo",
          body:
              "Your one-step platform to connect, share, and learn.Discover resources, collaborate with peers,and stay updated on your faculty and beyond",
          image: buildImage(path: "assets/images/environmentstudy.png"),
          decoration: pageDecoration(),
        ),
        PageViewModel(
          title: "Share & Discover",
          body:
              "Share resources, upload Notes,study guides,or project tours to help peers,Access resources shared by students from your department and also from others",
          image: buildImage(path: "assets/images/undraw_collab_h1mq.png"),
          decoration: pageDecoration(),
        ),
        PageViewModel(
          title: "Collaborate Across Departments & Fields",
          body:
              "Connect with students from other departments,exchange ideas,and work together on interdisciplinary projects",
          image: buildImage(path: "assets/images/team_work.png"),
          decoration: pageDecoration(),
        ),
        PageViewModel(
          title: "Ready to dive in?",
          body:
              "Join your faculty's Community,start sharing resources, and explore events and materials tailored to your needs. Let's make learning collaborative, interactive and above all fun",
          image: buildImage(path: "assets/images/undraw_startled_ez5h.png"),
          decoration: pageDecoration(),
        ),
      ],
      onDone: () async {
        // When done, set the flag to false
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isFirstTime', false);
        // Navigate to the AuthWrapper, which will now show the Signin screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AuthWrapper()),
        );
      },
      onSkip: () {},
      showSkipButton: true,
      skip: Text(
        "Skip",
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
      ),
      next: Text(
        "Next",
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
      ),
      done: Text(
        "Get Started",
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
      ),
      curve: Curves.fastEaseInToSlowEaseOut,
      controlsMargin: EdgeInsets.all(16),
      controlsPadding: EdgeInsets.all(16),
      dotsDecorator: DotsDecorator(
        size: Size(10, 10),
        color: Colors.grey,
        activeSize: Size(20, 10),
        activeColor: Colors.blue,
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadiusGeometry.circular(12),
        ),
      ),
    );
  }
}
