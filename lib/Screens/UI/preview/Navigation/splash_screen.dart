import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_study/main.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SplashScreen extends StatefulWidget {
  final bool isFirstLaunch;
  const SplashScreen({super.key, required this.isFirstLaunch});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  String _version = '';
  String buildnumber = '';

  late AnimationController _progressController;
  late Animation<double> _progressWidth;

  Future<void> _loadVersionDetails() async {
    final appinfo = await PackageInfo.fromPlatform();
    setState(() {
      _version = appinfo.version;
      buildnumber = appinfo.buildNumber;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadVersionDetails();

    // Simple progress animation
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _progressWidth = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    // Start progress
    _progressController.forward();

    // Navigate after 3s
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, animation, __) =>
                AppEntryPoint(isFirstLaunch: widget.isFirstLaunch),
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color backgroundColor = theme.scaffoldBackgroundColor;
    final Color primaryColor = theme.colorScheme.primary;

    const Color accentBlue = Color(0xFF3B82F6);
    const Color accentCyan = Color(0xFF06B6D4);

    final Color textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Padding(
        padding: const EdgeInsets.only(left: 70),
        child: Center(
          child: SizedBox(
            width: 450,
            height: 380,
            child: SvgPicture.asset(
              'assets/images/gostudy_logo_professional.svg',
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
