import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:thot/shared/widgets/logo_white.dart';
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
      title: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: const LogoWhite(
          fontSize: 32,
          letterSpacing: 2,
          showSubtitle: false,
        ),
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
            icon: Icon(Icons.search),
          ),
        if (onNotifications != null)
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              onNotifications!();
            },
            icon: Icon(Icons.notifications),
          ),
        const SizedBox(width: 8),
      ],
    );
  }
}