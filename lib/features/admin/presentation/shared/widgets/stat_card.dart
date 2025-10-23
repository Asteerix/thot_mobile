import 'package:flutter/material.dart';
import 'package:thot/core/constants/spacing_constants.dart';
import 'package:thot/shared/utils/responsive_utils.dart';
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: color,
          size: ResponsiveUtils.getAdaptiveIconSize(context, large: 32),
        ),
        SizedBox(height: SpacingConstants.space4),
        Text(
          value,
          style: TextStyle(
            fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 20),
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 12),
            color: Theme.of(context).colorScheme.outline,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(SpacingConstants.space8),
        child: content,
      );
    }
    return content;
  }
}
class StatsGrid extends StatelessWidget {
  final List<StatCard> stats;
  final EdgeInsetsGeometry? padding;
  const StatsGrid({
    super.key,
    required this.stats,
    this.padding,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? EdgeInsets.all(SpacingConstants.space16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(SpacingConstants.space12),
      ),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        mainAxisSpacing: SpacingConstants.space12,
        crossAxisSpacing: SpacingConstants.space12,
        childAspectRatio: 1.0,
        children: stats,
      ),
    );
  }
}
class StatsRow extends StatelessWidget {
  final List<StatCard> stats;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  const StatsRow({
    super.key,
    required this.stats,
    this.padding,
    this.backgroundColor,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: backgroundColor ??
            Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: stats.map((stat) => Expanded(child: stat)).toList(),
      ),
    );
  }
}