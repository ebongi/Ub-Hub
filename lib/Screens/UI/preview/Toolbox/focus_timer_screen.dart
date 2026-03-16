import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_study/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_study/Screens/Shared/premium_dialog.dart';

class FocusTimerScreen extends StatefulWidget {
  const FocusTimerScreen({super.key});

  @override
  State<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends State<FocusTimerScreen>
    with TickerProviderStateMixin {
  int _secondsRemaining = 25 * 60;
  int _focusDuration = 25; // in minutes
  Timer? _timer;
  bool _isRunning = false;
  late AnimationController _rotationController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _focusDuration = prefs.getInt('focus_duration') ?? 25;
      if (!_isRunning) {
        _secondsRemaining = _focusDuration * 60;
      }
    });
  }

  Future<void> _saveDuration(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('focus_duration', minutes);
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
              NotificationService().showAlert(
                id: 888,
                title: "Focus Complete!",
                body: "Great job! Take a short break.",
              );
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
      _secondsRemaining = _focusDuration * 60;
      _isRunning = false;
    });
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _FocusSettingsSheet(
        currentDuration: _focusDuration,
        onChanged: (minutes) {
          setState(() {
            _focusDuration = minutes;
            _resetTimer();
          });
          _saveDuration(minutes);
        },
      ),
    );
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
        actions: [
          IconButton(
            onPressed: _showSettings,
            icon: const Icon(Icons.tune_rounded),
            tooltip: "Settings",
          ),
          const SizedBox(width: 8),
        ],
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
                            value: _secondsRemaining / (_focusDuration * 60),
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

class _FocusSettingsSheet extends StatefulWidget {
  final int currentDuration;
  final ValueChanged<int> onChanged;

  const _FocusSettingsSheet({
    required this.currentDuration,
    required this.onChanged,
  });

  @override
  State<_FocusSettingsSheet> createState() => _FocusSettingsSheetState();
}

class _FocusSettingsSheetState extends State<_FocusSettingsSheet> {
  late int _duration;

  @override
  void initState() {
    super.initState();
    _duration = widget.currentDuration;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Customize Timer",
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey.withOpacity(0.1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            "QUICK PRESETS",
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildPresetChip(15),
              _buildPresetChip(25),
              _buildPresetChip(45),
              _buildPresetChip(60),
            ],
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "CUSTOM DURATION",
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: Colors.grey,
                ),
              ),
              Text(
                "$_duration min",
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.cyanAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.cyanAccent,
              inactiveTrackColor: Colors.cyanAccent.withOpacity(0.1),
              thumbColor: Colors.cyanAccent,
              overlayColor: Colors.cyanAccent.withOpacity(0.2),
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            ),
            child: Slider(
              value: _duration.toDouble(),
              min: 1,
              max: 120,
              onChanged: (value) {
                setState(() => _duration = value.toInt());
                widget.onChanged(_duration);
              },
            ),
          ),
          const SizedBox(height: 40),
          PremiumSubmitButton(
            label: "Apply & Close",
            isLoading: false,
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPresetChip(int minutes) {
    final isSelected = _duration == minutes;
    return GestureDetector(
      onTap: () {
        setState(() => _duration = minutes);
        widget.onChanged(minutes);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.cyanAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.cyanAccent
                : Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Text(
          "$minutes",
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.black : null,
          ),
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
