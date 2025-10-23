import 'package:flutter/material.dart';
import 'package:thot/core/themes/app_colors.dart';

/// Bouton d'outil pour l'éditeur d'images
/// Rotation, flip, reset, etc.
class ImageToolButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool enabled;
  final Future<void> Function()? onPressed;

  const ImageToolButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Tooltip(
        message: tooltip,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.grey[800],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? AppColors.darkBorder
                  : Colors.white.withOpacity(0.1),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: enabled && onPressed != null
                  ? () async => await onPressed!()
                  : null,
              borderRadius: BorderRadius.circular(12),
              child: Icon(
                icon,
                size: 20,
                color: enabled ? Colors.white : Colors.white.withOpacity(0.3),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
