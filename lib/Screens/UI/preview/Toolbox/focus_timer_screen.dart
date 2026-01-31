import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FocusTimerScreen extends StatefulWidget {
  const FocusTimerScreen({super.key});

  @override
  State<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends State<FocusTimerScreen>
    with TickerProviderStateMixin {
  int _secondsRemaining = 25 * 60;
  Timer? _timer;
  bool _isRunning = false;
  late AnimationController _rotationController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  void _startTimer() {
    if (_isRunning) {
      _timer?.cancel();
    } else {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            if (_secondsRemaining > 0) {
              _secondsRemaining--;
            } else {
              _timer?.cancel();
              _isRunning = false;
            }
          });
        }
      });
    }
    setState(() => _isRunning = !_isRunning);
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _secondsRemaining = 25 * 60;
      _isRunning = false;
    });
  }

  String _formatTime(int seconds) {
    int m = seconds ~/ 60;
    int s = seconds % 60;
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    _timer?.cancel();
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(
        context,
      ).scaffoldBackgroundColor, // Deep midnight blue or light background
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Focus Mode",
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        leading: BackButton(color: Theme.of(context).iconTheme.color),
      ),
      body: Stack(
        children: [
          // Next-Gen Particle Background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _rotationController,
              builder: (context, child) {
                return CustomPaint(
                  painter: ParticlePainter(
                    progress: _rotationController.value,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.1),
                  ),
                );
              },
            ),
          ),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 3D Perspective Timer Card
                TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0, end: _isRunning ? 1 : 0),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.elasticOut,
                  builder: (context, double value, child) {
                    return Transform(
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.002) // Perspective
                        ..rotateX(-0.1 * (1 - value))
                        ..rotateY(
                          0.2 *
                              value *
                              math.sin(
                                _rotationController.value * 2 * math.pi * 0.5,
                              ),
                        ),
                      alignment: Alignment.center,
                      child: child,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(
                            0.3 * _pulseController.value,
                          ),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                        BoxShadow(
                          color: Colors.purple.withOpacity(0.2),
                          blurRadius: 50,
                          offset: const Offset(0, 20),
                        ),
                      ],
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: Theme.of(context).brightness == Brightness.dark
                            ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                            : [
                                const Color(0xFFF1F5F9),
                                const Color(0xFFE2E8F0),
                              ],
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Glassy Ring
                        SizedBox(
                          width: 250,
                          height: 250,
                          child: CircularProgressIndicator(
                            value: _secondsRemaining / (25 * 60),
                            strokeWidth: 4,
                            backgroundColor:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.white10
                                : Colors.black12,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _isRunning
                                  ? Colors.cyanAccent
                                  : (Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white24
                                        : Colors.black26),
                            ),
                          ),
                        ),
                        // Inner Glow Circle
                        Container(
                          width: 210,
                          height: 210,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).dividerColor.withOpacity(0.1),
                            ),
                            gradient: RadialGradient(
                              colors: [
                                Colors.blue.withOpacity(
                                  0.1 * _pulseController.value,
                                ),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        // Time Text
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _isRunning ? "FOCUSING" : "IDLE",
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                letterSpacing: 4,
                                color: _isRunning
                                    ? Colors.cyanAccent
                                    : Theme.of(
                                        context,
                                      ).textTheme.bodySmall?.color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _formatTime(_secondsRemaining),
                              style: GoogleFonts.outfit(
                                fontSize: 64,
                                fontWeight: FontWeight.w200,
                                color: Theme.of(
                                  context,
                                ).textTheme.bodyLarge?.color,
                                shadows: [
                                  Shadow(
                                    color: Colors.cyanAccent.withOpacity(
                                      0.5 * _pulseController.value,
                                    ),
                                    blurRadius: 20,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 100),

                // Futuristic Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildFuturisticButton(
                      context,
                      onPressed: _startTimer,
                      icon: _isRunning
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      label: _isRunning ? "PAUSE" : "ENGAGE",
                      isPrimary: true,
                    ),
                    const SizedBox(width: 24),
                    _buildFuturisticButton(
                      context,
                      onPressed: _resetTimer,
                      icon: Icons.refresh_rounded,
                      label: "RESET",
                      isPrimary: false,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFuturisticButton(
    BuildContext context, {
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required bool isPrimary,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isPrimary
                ? Colors.cyanAccent.withOpacity(0.5)
                : Theme.of(context).dividerColor.withOpacity(0.2),
          ),
          gradient: LinearGradient(
            colors: isPrimary
                ? [Colors.cyanAccent.withOpacity(0.2), Colors.transparent]
                : [
                    Theme.of(context).cardColor.withOpacity(0.5),
                    Colors.transparent,
                  ],
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isPrimary
                  ? Colors.white
                  : Theme.of(context).iconTheme.color,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: isPrimary
                    ? Colors.white
                    : Theme.of(context).textTheme.bodyLarge?.color,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ParticlePainter extends CustomPainter {
  final double progress;
  final Color? color;
  ParticlePainter({required this.progress, this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color ?? Colors.white.withOpacity(0.1);
    final random = math.Random(42);

    for (int i = 0; i < 50; i++) {
      double x = random.nextDouble() * size.width;
      double y =
          (random.nextDouble() * size.height +
              (progress * 100 * (1 + random.nextDouble()))) %
          size.height;
      double s = random.nextDouble() * 2 + 1;

      canvas.drawCircle(Offset(x, y), s, paint);
    }

    // Glowing orbs
    final glowPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);

    glowPaint.color = Colors.blue.withOpacity(0.05);
    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.3),
      100,
      glowPaint,
    );

    glowPaint.color = Colors.purple.withOpacity(0.05);
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.7),
      150,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) => true;
}
