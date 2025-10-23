import 'package:flutter/material.dart';

/// Generic gradient background container used across multiple screens
class GradientBackgroundContainer extends StatelessWidget {
  final Widget child;
  final List<Color> gradientColors;
  final AlignmentGeometry begin;
  final AlignmentGeometry end;

  const GradientBackgroundContainer({
    super.key,
    required this.child,
    required this.gradientColors,
    this.begin = Alignment.topCenter,
    this.end = Alignment.bottomCenter,
  });

  /// Factory for auth screens dark gradient
  factory GradientBackgroundContainer.authDark({
    required Widget child,
    required BuildContext context,
  }) {
    final theme = Theme.of(context);
    return GradientBackgroundContainer(
      gradientColors: [
        theme.colorScheme.primaryContainer.withOpacity(0.3),
        theme.colorScheme.background,
      ],
      child: child,
    );
  }

  /// Factory for standard screen gradient
  factory GradientBackgroundContainer.standard({
    required Widget child,
    required BuildContext context,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return GradientBackgroundContainer(
      gradientColors: [
        colorScheme.primaryContainer.withOpacity(0.1),
        colorScheme.background,
      ],
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: begin,
          end: end,
          colors: gradientColors,
        ),
      ),
      child: child,
    );
  }
}
