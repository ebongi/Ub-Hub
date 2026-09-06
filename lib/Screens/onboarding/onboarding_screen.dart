import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_study/core/app_wordmark.dart';
import 'package:go_study/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  List<_OnboardingPageData> _pages(AppLocalizations l10n) => [
    _OnboardingPageData(
      image: 'assets/images/college project-rafiki.png',
      title: l10n.onboardingPage1Title,
      body: l10n.onboardingPage1Body,
      accent: const Color(0xFFE11D48),
    ),
    _OnboardingPageData(
      image: 'assets/images/Teaching-rafiki.png',
      title: l10n.onboardingPage2Title,
      body: l10n.onboardingPage2Body,
      accent: const Color(0xFF0EA5E9),
    ),
    _OnboardingPageData(
      image: 'assets/images/college students-rafiki.png',
      title: l10n.onboardingPage3Title,
      body: l10n.onboardingPage3Body,
      accent: const Color(0xFF7C3AED),
    ),
    _OnboardingPageData(
      image: 'assets/images/Learning-rafiki.png',
      title: l10n.onboardingPage4Title,
      body: l10n.onboardingPage4Body,
      accent: const Color(0xFF16A34A),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstLaunch', false);
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/auth');
  }

  void _skip() {
    _finishOnboarding();
  }

  void _next() {
    final l10n = AppLocalizations.of(context)!;
    if (_currentPage == _pages(l10n).length - 1) {
      _finishOnboarding();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _previous() {
    if (_currentPage == 0) return;
    _pageController.previousPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final pages = _pages(l10n);
    final page = pages[_currentPage];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFFF7F7F7) : Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -80,
              right: -60,
              child: _SoftBlob(color: page.accent.withOpacity(0.08), size: 220),
            ),
            Positioned(
              bottom: -60,
              left: -50,
              child: _SoftBlob(color: page.accent.withOpacity(0.06), size: 180),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const AppWordmark(fontSize: 14),
                      const Spacer(),
                      TextButton(
                        onPressed: _skip,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.black87,
                        ),
                        child: Text(
                          l10n.onboardingSkip,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: pages.length,
                      onPageChanged: (index) {
                        setState(() => _currentPage = index);
                      },
                      itemBuilder: (context, index) {
                        final data = pages[index];
                        return _OnboardingPage(data: data, isDark: isDark);
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _PageDots(
                        currentIndex: _currentPage,
                        count: pages.length,
                      ),
                      const Spacer(),
                      _NavButton(
                        icon: Icons.arrow_back_rounded,
                        onPressed: _previous,
                        enabled: _currentPage > 0,
                        background: Colors.white,
                        foreground: Colors.black87,
                        borderColor: Colors.black12,
                      ),
                      const SizedBox(width: 12),
                      _NavButton(
                        icon: Icons.arrow_forward_rounded,
                        onPressed: _next,
                        enabled: true,
                        background: Colors.black,
                        foreground: Colors.white,
                        borderColor: Colors.black,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.data,
    required this.isDark,
  });

  final _OnboardingPageData data;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final imageHeight = size.height < 700 ? 250.0 : 310.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: imageHeight,
          child: Center(
            child: Image.asset(
              data.image,
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.only(right: 8),
          child: Text(
            data.title,
            textAlign: TextAlign.left,
            style: GoogleFonts.outfit(
              fontSize: size.width < 380 ? 32 : 36,
              height: 1.0,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.only(right: 16),
          child: Text(
            data.body,
            textAlign: TextAlign.left,
            style: GoogleFonts.outfit(
              fontSize: 14.5,
              height: 1.55,
              color: Colors.black54,
            ),
          ),
        ),
      ],
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({
    required this.currentIndex,
    required this.count,
  });

  final int currentIndex;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(count, (index) {
        final active = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(right: 6),
          width: active ? 22 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: active ? Colors.black : Colors.black26,
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.onPressed,
    required this.enabled,
    required this.background,
    required this.foreground,
    required this.borderColor,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final bool enabled;
  final Color background;
  final Color foreground;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? background : background.withOpacity(0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: borderColor.withOpacity(enabled ? 1 : 0.2)),
      ),
      elevation: enabled && background == Colors.black ? 4 : 0,
      shadowColor: Colors.black26,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: enabled ? onPressed : null,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: foreground, size: 20),
        ),
      ),
    );
  }
}

class _SoftBlob extends StatelessWidget {
  const _SoftBlob({
    required this.color,
    required this.size,
  });

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.image,
    required this.title,
    required this.body,
    required this.accent,
  });

  final String image;
  final String title;
  final String body;
  final Color accent;
}
