import 'package:flutter/material.dart';

/// Reusable screen title header with subtitle
class ScreenTitleHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final TextAlign textAlign;
  final EdgeInsetsGeometry? padding;

  const ScreenTitleHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.textAlign = TextAlign.center,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: textAlign == TextAlign.center
            ? CrossAxisAlignment.center
            : textAlign == TextAlign.left
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.end,
        children: [
          Text(
            title,
            style: theme.textTheme.displaySmall?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
            textAlign: textAlign,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 12),
            Text(
              subtitle!,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: textAlign,
            ),
          ],
        ],
      ),
    );
  }
}
