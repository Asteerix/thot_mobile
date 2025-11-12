import 'package:flutter/material.dart';
import 'package:thot/core/presentation/theme/app_colors.dart';

/// Chip pour sélectionner un preset d'aspect ratio
/// Utilisé dans l'éditeur d'images pour choisir les ratios
class AspectPresetChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const AspectPresetChip({
    super.key,
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: selected && enabled
              ? const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: selected && enabled
              ? null
              : (isDark ? AppColors.darkCard : Colors.grey[800]),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : (isDark
                    ? AppColors.darkBorder
                    : Colors.white.withOpacity(0.2)),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: enabled ? Colors.white : Colors.white.withOpacity(0.3),
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
