import 'package:flutter/material.dart';

/// Generic animated wrapper for screens with fade and slide animations
class AnimatedScreenWrapper extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Curve fadeCurve;
  final Curve slideCurve;
  final Offset slideBegin;
  final bool enableFade;
  final bool enableSlide;

  const AnimatedScreenWrapper({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 800),
    this.fadeCurve = Curves.easeOut,
    this.slideCurve = Curves.easeOutCubic,
    this.slideBegin = const Offset(0, 0.1),
    this.enableFade = true,
    this.enableSlide = true,
  });

  @override
  State<AnimatedScreenWrapper> createState() => _AnimatedScreenWrapperState();
}

class _AnimatedScreenWrapperState extends State<AnimatedScreenWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: widget.fadeCurve,
    );

    _slideAnimation = Tween<Offset>(
      begin: widget.slideBegin,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.slideCurve,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget result = widget.child;

    if (widget.enableSlide) {
      result = SlideTransition(
        position: _slideAnimation,
        child: result,
      );
    }

    if (widget.enableFade) {
      result = FadeTransition(
        opacity: _fadeAnimation,
        child: result,
      );
    }

    return result;
  }
}
