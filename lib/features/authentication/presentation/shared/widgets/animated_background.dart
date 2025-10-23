import 'package:flutter/material.dart';
class AnimatedBackground extends StatelessWidget {
  final Animation<double> animation;
  final List<Color> gradientColors;
  final bool showPattern;
  const AnimatedBackground({
    super.key,
    required this.animation,
    required this.gradientColors,
    this.showPattern = true,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradientColors,
        ),
      ),
      child: showPattern
          ? CustomPaint(
              painter: _BackgroundPainter(animation: animation),
              child: Container(),
            )
          : null,
    );
  }
}
class _BackgroundPainter extends CustomPainter {
  final Animation<double> animation;
  _BackgroundPainter({required this.animation}) : super(repaint: animation);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..style = PaintingStyle.fill;
    final radius = size.width * 0.3 * (1 + animation.value * 0.2);
    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.3),
      radius,
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.7),
      radius * 0.8,
      paint..color = Colors.blue.withOpacity(0.02),
    );
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}