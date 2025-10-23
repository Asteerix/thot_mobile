import 'package:flutter/material.dart';
import 'package:thot/core/themes/app_colors.dart';
import 'sparkline.dart';
class StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final double deltaPct;
  final List<double> series;
  final VoidCallback? onTap;
  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.deltaPct,
    required this.series,
    this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final positive = deltaPct >= 0;
    return Material(
      color: cs.surfaceContainerHighest.withOpacity(0.5),
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: cs.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ),
                  _DeltaChip(percent: deltaPct),
                ],
              ),
              const Spacer(),
              Text(
                _formatNumber(value),
                style: theme.textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Sparkline(
                data: series,
                color: positive ? AppColors.success : AppColors.red,
              ),
            ],
          ),
        ),
      ),
    );
  }
  String _formatNumber(int number) {
    final n = number.toDouble();
    if (n >= 1000000) {
      final v = (n / 1000000);
      return '${v.toStringAsFixed(v < 10 ? 1 : 0)} M';
    }
    if (n >= 1000) {
      final v = (n / 1000);
      return '${v.toStringAsFixed(v < 10 ? 1 : 0)} k';
    }
    return number.toString();
  }
}
class _DeltaChip extends StatelessWidget {
  final double percent;
  const _DeltaChip({required this.percent});
  @override
  Widget build(BuildContext context) {
    final positive = percent >= 0;
    final bg = (positive ? AppColors.success : AppColors.red).withOpacity(0.18);
    final fg = positive ? AppColors.success : AppColors.red;
    final icon = positive ? Icons.trending_up : Icons.trending_down;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 4),
          Text(
            '${percent.abs().toStringAsFixed(1)} %',
            style: TextStyle(color: fg, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}