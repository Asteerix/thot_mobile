import 'package:flutter/material.dart';
import 'package:thot/core/themes/app_colors.dart';
class VerificationBadge extends StatelessWidget {
  final double size;
  const VerificationBadge({
    super.key,
    this.size = 16.0,
  });
  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.verified,
      size: size,
      color: AppColors.blue,
      semanticLabel: 'Vérifié',
    );
  }
}
class SubscriptionButton extends StatelessWidget {
  final bool isSubscribed;
  final VoidCallback onPressed;
  const SubscriptionButton({
    super.key,
    required this.isSubscribed,
    required this.onPressed,
  });
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isSubscribed
            ? (isDark
                ? AppColors.darkCard
                : Theme.of(context).colorScheme.surfaceContainerHighest)
            : AppColors.green,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Text(
        isSubscribed ? 'Abonné' : "S'abonner",
        style: const TextStyle(
          fontFamily: 'Tailwind',
          fontSize: 14,
        ),
      ),
    );
  }
}
class NotificationBadge extends StatelessWidget {
  final int count;
  final Color? color;
  const NotificationBadge({
    super.key,
    required this.count,
    this.color,
  });
  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();
    final badgeColor = color ?? AppColors.red;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: badgeColor,
        shape: BoxShape.circle,
      ),
      child: Text(
        count > 99 ? '99+' : count.toString(),
        style: TextStyle(
          color: Theme.of(context).colorScheme.onError,
          fontSize: 8,
          fontWeight: FontWeight.bold,
          fontFamily: 'Tailwind',
        ),
      ),
    );
  }
}
class PerplexityTooltip extends StatelessWidget {
  final String message;
  final Widget child;
  const PerplexityTooltip({
    super.key,
    required this.message,
    required this.child,
  });
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Tooltip(
      message: message,
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkCard
            : Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
        fontSize: 12,
        fontFamily: 'Tailwind',
      ),
      child: child,
    );
  }
}