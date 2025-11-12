import 'package:flutter/material.dart';

class GradientBorderCard extends StatelessWidget {
  final Widget child;
  final Color color;
  final double radius;
  final double borderWidth;
  const GradientBorderCard({
    super.key,
    required this.child,
    required this.color,
    this.radius = 16,
    this.borderWidth = 1.5,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.55), color.withOpacity(0.18)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Container(
        margin: EdgeInsets.all(borderWidth),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(radius - 1),
        ),
        child: child,
      ),
    );
  }
}
