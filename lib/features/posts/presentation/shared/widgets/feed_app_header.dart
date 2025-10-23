import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
class FeedAppHeader extends StatelessWidget {
  final String title;
  final IconData? iconData;
  final bool showViewToggle;
  final VoidCallback? onViewToggle;
  final IconData? viewModeIcon;
  final VoidCallback? onSearch;
  final VoidCallback? onNotifications;
  const FeedAppHeader({
    super.key,
    required this.title,
    this.iconData,
    this.showViewToggle = true,
    this.onViewToggle,
    this.viewModeIcon,
    this.onSearch,
    this.onNotifications,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return SliverAppBar(
      pinned: true,
      floating: true,
      snap: true,
      expandedHeight: 56,
      backgroundColor: isDark ? Colors.black : cs.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: iconData != null
                  ? LinearGradient(
                      colors: [cs.primary, cs.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: iconData != null ? null : cs.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: iconData != null
                  ? Icon(
                      iconData,
                      color: cs.onPrimary,
                      size: 20,
                    )
                  : Text(
                      'T',
                      style: TextStyle(
                        color: cs.onPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 22,
            ),
          ),
        ],
      ),
      actions: [
        if (showViewToggle && onViewToggle != null && viewModeIcon != null)
          Container(
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                onViewToggle!();
              },
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  viewModeIcon,
                  key: ValueKey(viewModeIcon),
                ),
              ),
            ),
          ),
        if (onSearch != null)
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              onSearch!();
            },
            icon: const Icon(Icons.search_rounded),
          ),
        if (onNotifications != null)
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              onNotifications!();
            },
            icon: const Icon(Icons.notifications_outlined),
          ),
        const SizedBox(width: 8),
      ],
    );
  }
}