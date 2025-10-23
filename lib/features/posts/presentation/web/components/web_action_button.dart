import 'package:flutter/material.dart';
import '../../../../../core/themes/web_theme.dart';
class WebActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isActive;
  final ColorScheme? colorScheme;
  const WebActionButton({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.isActive = false,
    this.colorScheme,
  });
  @override
  Widget build(BuildContext context) {
    final scheme = colorScheme ?? Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(WebTheme.borderRadiusSmall),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: WebTheme.sm,
          vertical: WebTheme.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive
                  ? scheme.primary
                  : scheme.onSurface.withOpacity(0.6),
            ),
            if (label.isNotEmpty) ...[
              const SizedBox(width: WebTheme.xs),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: isActive
                      ? scheme.primary
                      : scheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}