import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LinkTile extends StatelessWidget {
  const LinkTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.onLongPress,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Semantics(
      button: true,
      label: '$title. $subtitle.',
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 0,
        color: cs.surfaceContainerHighest,
        surfaceTintColor: cs.surfaceTint,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: cs.outlineVariant),
        ),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            Feedback.forTap(context);
            onTap();
          },
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                IconBadge(icon: icon),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class IconBadge extends StatelessWidget {
  const IconBadge({super.key, required this.icon});
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.primary.withOpacity(0.30)),
      ),
      child: Icon(icon, color: cs.primary, size: 22),
    );
  }
}
