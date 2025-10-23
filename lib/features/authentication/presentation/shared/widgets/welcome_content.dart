import 'package:flutter/material.dart';
class WelcomeTitle extends StatelessWidget {
  final bool usePrimaryColor;
  const WelcomeTitle({
    super.key,
    this.usePrimaryColor = false,
  });
  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
class WelcomeSubtitle extends StatelessWidget {
  final bool usePrimaryColor;
  const WelcomeSubtitle({
    super.key,
    this.usePrimaryColor = false,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Text(
      'L\'information qui compte\npour ceux qui pensent',
      style: usePrimaryColor
          ? theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            )
          : TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
              fontWeight: FontWeight.w400,
              height: 1.5,
              letterSpacing: 0.5,
            ),
      textAlign: TextAlign.center,
    );
  }
}