import 'package:flutter/material.dart';

/// Responsive back button that works for both mobile and web
class ResponsiveBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color? color;
  final double? size;

  const ResponsiveBackButton({
    super.key,
    this.onPressed,
    this.color,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.onSurface;

    return IconButton(
      onPressed: onPressed ?? () => Navigator.of(context).pop(),
      icon: Icon(
        Icons.arrow_back,
        color: effectiveColor,
        size: size,
      ),
      tooltip: 'Retour',
    );
  }
}
