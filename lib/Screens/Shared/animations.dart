import 'package:flutter/material.dart';

class FadeInSlide extends StatefulWidget {
  final Widget child;
  final double delay;
  final Duration duration;
  final double beginOffset;

  const FadeInSlide({
    super.key,
    required this.child,
    this.delay = 0,
    this.duration = const Duration(milliseconds: 600),
    this.beginOffset = 0.3,
  });

  @override
  State<FadeInSlide> createState() => _FadeInSlideState();
}

class _FadeInSlideState extends State<FadeInSlide>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _opacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _offset = Tween<Offset>(
      begin: Offset(0, widget.beginOffset),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    if (widget.delay == 0) {
      _controller.forward();
    } else {
      Future.delayed(Duration(milliseconds: (widget.delay * 1000).round()), () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _offset, child: widget.child),
    );
  }
}

class ScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final Duration duration;
  final double scale;

  const ScaleButton({
    super.key,
    required this.child,
    required this.onTap,
    this.duration = const Duration(milliseconds: 100),
    this.scale = 0.95,
  });

  @override
  State<ScaleButton> createState() => _ScaleButtonState();
}

class _ScaleButtonState extends State<ScaleButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      upperBound: 1.0,
      lowerBound: 0.0,
    );
    _scale = Tween<double>(begin: 1.0, end: widget.scale).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}
