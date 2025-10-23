import 'package:flutter/material.dart';
class InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? borderWidth;
  const InfoTile({
    super.key,
    required this.icon,
    required this.label,
    required this.accent,
    required this.child,
    this.padding,
    this.borderWidth,
  });
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withOpacity(0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accent.withOpacity(0.28),
          width: borderWidth ?? 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 22, color: accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}