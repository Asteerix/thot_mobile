import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
class OptionSelectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;
  final double? height;
  final double? iconSize;
  final Color? selectedColor;
  final Color? unselectedColor;
  const OptionSelectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
    this.height,
    this.iconSize,
    this.selectedColor,
    this.unselectedColor,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final effectiveSelectedColor = selectedColor ?? colorScheme.surface;
    final effectiveUnselectedColor = unselectedColor ?? colorScheme.surface;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: height ?? 200,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? effectiveSelectedColor.withOpacity(0.2)
              : effectiveUnselectedColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? effectiveSelectedColor.withOpacity(0.5)
                : effectiveUnselectedColor.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                    ? effectiveSelectedColor.withOpacity(0.25)
                    : effectiveUnselectedColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: effectiveSelectedColor,
                size: iconSize ?? 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                color: effectiveSelectedColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: effectiveSelectedColor.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}