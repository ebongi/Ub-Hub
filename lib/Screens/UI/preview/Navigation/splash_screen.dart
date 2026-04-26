import 'package:flutter/material.dart';
import 'package:go_study/main.dart';
import 'package:package_info_plus/package_info_plus.dart';
// Hide Rive's 'Animation' to avoid ambiguity with Flutter's Animation class
import 'package:rive/rive.dart' hide Animation;

class SplashScreen extends StatefulWidget {
  final bool isFirstLaunch;
  const SplashScreen({super.key, required this.isFirstLaunch});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  String _version = '';
  String _buildNumber = '';

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // FileLoader must be created once and disposed — no StateMachineController needed
  final FileLoader _fileLoader = FileLoader.fromAsset(
    'assets/rive/15288-28809-just-for-test.riv',
    riveFactory: Factory.flutter,
  );

  Future<void> _loadVersionDetails() async {
    final appInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _version = appInfo.version;
        _buildNumber = appInfo.buildNumber;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadVersionDetails();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(
          CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
        );

    // Reveal text after animation settles
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _fadeController.forward();
    });

    // Navigate after splash completes
    Future.delayed(const Duration(milliseconds: 3200), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, animation, __) =>
                AppEntryPoint(isFirstLaunch: widget.isFirstLaunch),
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _fileLoader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top colour band ──
            _ColorBand(primary: cs.primary, secondary: cs.secondary),

            // ── Main content ──
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Rive animation (new v0.14 API)
                    SizedBox(
                      width: 260,
                      height: 260,
                      child: RiveWidgetBuilder(
                        fileLoader: _fileLoader,
                        artboardSelector: const ArtboardDefault(),
                        stateMachineSelector: const StateMachineDefault(),
                        builder: (context, state) {
                          return switch (state) {
                            RiveLoaded(:final controller) => RiveWidget(
                              controller: controller,
                              fit: Fit.contain,
                            ),
                            RiveLoading() => const Center(
                              child: CircularProgressIndicator.adaptive(),
                            ),
                            RiveFailed() => Center(
                              child: Icon(
                                Icons.animation,
                                size: 64,
                                color: cs.primary,
                              ),
                            ),
                          };
                        },
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Staggered text reveal
                    SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          children: [
                            Text(
                              'GoStudy',
                              style: theme.textTheme.displaySmall?.copyWith(
                                color: cs.primary,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _TaglineRow(
                              colorScheme: cs,
                              tags: const ['Learn', 'Practice', 'Achieve'],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Algorithm Driven UBCOMSA',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: cs.onSurface.withOpacity(0.65),
                                letterSpacing: 0.2,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Version badge ──
            Padding(
              padding: const EdgeInsets.only(bottom: 28),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _VersionBadge(
                  version: _version,
                  buildNumber: _buildNumber,
                  colorScheme: cs,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Top colour band ──────────────────────────────────────────────────────────

class _ColorBand extends StatelessWidget {
  final Color primary;
  final Color secondary;
  const _ColorBand({required this.primary, required this.secondary});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 4,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primary, secondary, primary],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}

// ─── Tagline pill row ─────────────────────────────────────────────────────────

class _TaglineRow extends StatelessWidget {
  final ColorScheme colorScheme;
  final List<String> tags;
  const _TaglineRow({required this.colorScheme, required this.tags});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: tags
          .map(
            (tag) => Chip(
              label: Text(
                tag,
                style: TextStyle(
                  color: colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              backgroundColor: colorScheme.secondaryContainer,
              side: BorderSide.none,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              visualDensity: VisualDensity.compact,
            ),
          )
          .toList(),
    );
  }
}

// ─── Version badge ────────────────────────────────────────────────────────────

class _VersionBadge extends StatelessWidget {
  final String version;
  final String buildNumber;
  final ColorScheme colorScheme;

  const _VersionBadge({
    required this.version,
    required this.buildNumber,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    if (version.isEmpty) return const SizedBox.shrink();

    final label = 'v$version${buildNumber.isNotEmpty ? ' ($buildNumber)' : ''}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontSize: 12,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
