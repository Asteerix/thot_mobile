// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import '../../../core/themes/web_theme.dart';
import 'responsive_layout.dart';

/// Navigation item model for sidebar (private, internal use only)
class _NavigationItem {
  final String label;
  final IconData icon;
  final String route;
  final int? badgeCount;

  const _NavigationItem({
    required this.label,
    required this.icon,
    required this.route,
    this.badgeCount,
  });
}

/// Web sidebar navigation with collapsible support
///
/// Provides a responsive navigation sidebar for web layouts with:
/// - Fixed navigation items (Feed, Explore, Notifications, Messages, Profile, Settings)
/// - Collapsible state on tablets (expands/collapses with toggle button)
/// - Active route highlighting
/// - Badge support for notification counts (unused currently)
/// - Optional user profile section (unused currently)
///
/// Used by [WebScaffold] for desktop and tablet layouts.
class WebSidebar extends StatefulWidget {
  /// Current active route for highlighting the corresponding navigation item
  final String currentRoute;

  /// Callback when user navigates to a different route
  final Function(String route) onNavigate;

  /// Whether the sidebar is collapsed (tablet only)
  final bool collapsed;

  /// Callback to toggle sidebar collapse state (tablet only)
  final VoidCallback? onToggleCollapse;

  /// Optional user profile widget to display at the bottom
  /// Note: Currently unused in the codebase
  final Widget? userProfile;

  const WebSidebar({
    super.key,
    required this.currentRoute,
    required this.onNavigate,
    this.collapsed = false,
    this.onToggleCollapse,
    this.userProfile,
  });

  @override
  State<WebSidebar> createState() => _WebSidebarState();
}

class _WebSidebarState extends State<WebSidebar> {
  static const List<_NavigationItem> _navigationItems = [
    _NavigationItem(label: 'Feed', icon: Icons.home, route: '/'),
    _NavigationItem(
        label: 'Explore', icon: Icons.explore, route: '/explore'),
    _NavigationItem(
        label: 'Notifications',
        icon: Icons.notifications,
        route: '/notifications'),
    _NavigationItem(
        label: 'Messages', icon: Icons.mail, route: '/messages'),
    _NavigationItem(
        label: 'Profile', icon: Icons.person, route: '/profile'),
    _NavigationItem(
        label: 'Settings', icon: Icons.settings, route: '/settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isTablet = context.isTablet;
    final isCollapsed = widget.collapsed && isTablet;
    final width = isCollapsed
        ? WebTheme.sidebarWidthCollapsed
        : WebTheme.sidebarWidthExpanded;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: width,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          _buildLogoSection(colorScheme, isCollapsed),
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(
                vertical: WebTheme.md,
                horizontal: isCollapsed ? WebTheme.sm : WebTheme.md,
              ),
              children: _navigationItems
                  .map((item) => _buildNavigationItem(item, colorScheme, isCollapsed))
                  .toList(),
            ),
          ),
          if (widget.userProfile != null) ...[
            Divider(color: colorScheme.outline.withOpacity(0.2)),
            Padding(
              padding: const EdgeInsets.all(WebTheme.md),
              child: widget.userProfile!,
            ),
          ],
          if (isTablet && widget.onToggleCollapse != null) ...[
            Divider(color: colorScheme.outline.withOpacity(0.2)),
            _buildCollapseToggle(colorScheme),
          ],
        ],
      ),
    );
  }

  Widget _buildLogoSection(ColorScheme colorScheme, bool isCollapsed) {
    return Container(
      height: WebTheme.headerHeight,
      padding: const EdgeInsets.symmetric(horizontal: WebTheme.md),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Center(
        child: isCollapsed
            ? Icon(
                Icons.bookOpen,
                size: 32,
                color: colorScheme.primary,
              )
            : Text(
                'THOT',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
      ),
    );
  }

  Widget _buildNavigationItem(
    _NavigationItem item,
    ColorScheme colorScheme,
    bool isCollapsed,
  ) {
    final isActive = widget.currentRoute == item.route;

    return Padding(
      padding: const EdgeInsets.only(bottom: WebTheme.xs),
      child: Material(
        color: isActive ? colorScheme.primaryContainer : colorScheme.surface,
        borderRadius: BorderRadius.circular(WebTheme.borderRadiusMedium),
        child: InkWell(
          onTap: () => widget.onNavigate(item.route),
          borderRadius: BorderRadius.circular(WebTheme.borderRadiusMedium),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isCollapsed ? WebTheme.sm : WebTheme.md,
              vertical: WebTheme.md,
            ),
            child: Row(
              mainAxisAlignment: isCollapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                _buildNavigationIcon(item, colorScheme, isActive),
                if (!isCollapsed) ...[
                  const SizedBox(width: WebTheme.md),
                  Expanded(
                    child: Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.w500,
                        color: isActive
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationIcon(
    _NavigationItem item,
    ColorScheme colorScheme,
    bool isActive,
  ) {
    if (item.badgeCount == null || item.badgeCount! <= 0) {
      return Icon(
        item.icon,
        size: WebTheme.sidebarIconSize,
        color: isActive ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(
          item.icon,
          size: WebTheme.sidebarIconSize,
          color: isActive ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
        ),
        Positioned(
          right: -8,
          top: -8,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: colorScheme.error,
              shape: BoxShape.circle,
            ),
            constraints: const BoxConstraints(
              minWidth: 16,
              minHeight: 16,
            ),
            child: Text(
              item.badgeCount! > 9 ? '9+' : '${item.badgeCount}',
              style: TextStyle(
                color: colorScheme.onError,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCollapseToggle(ColorScheme colorScheme) {
    return IconButton(
      icon: Icon(
        widget.collapsed ? Icons.chevron_right : Icons.arrow_back_ios_new,
        color: colorScheme.onSurface,
      ),
      onPressed: widget.onToggleCollapse,
      tooltip: widget.collapsed ? 'Expand sidebar' : 'Collapse sidebar',
    );
  }
}

// ============================================================================
// UNUSED WIDGET - SidebarUserProfile
// ============================================================================
// Cette classe n'est jamais utilisée dans la codebase. Elle a été créée pour
// afficher un profil utilisateur dans la sidebar, mais cette fonctionnalité
// n'a jamais été implémentée dans l'application.
//
// Le paramètre userProfile de WebSidebar (ligne 26) n'est jamais passé avec
// une valeur réelle dans les 46 écrans web qui utilisent WebScaffold.
//
// Si vous souhaitez utiliser cette fonctionnalité à l'avenir, décommentez
// cette classe et passez une instance de SidebarUserProfile au paramètre
// userProfile de WebSidebar.
// ============================================================================

/*
/// User profile widget for sidebar
class SidebarUserProfile extends StatelessWidget {
  final String? avatarUrl;
  final String name;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool collapsed;

  const SidebarUserProfile({
    super.key,
    this.avatarUrl,
    required this.name,
    this.subtitle,
    this.onTap,
    this.collapsed = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (collapsed) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(WebTheme.avatarSizeMedium / 2),
        child: CircleAvatar(
          radius: WebTheme.avatarSizeMedium / 2,
          backgroundColor: colorScheme.primaryContainer,
          backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
          child: avatarUrl == null
              ? Icon(
                  Icons.person,
                  size: WebTheme.avatarSizeMedium / 2,
                  color: colorScheme.onPrimaryContainer,
                )
              : null,
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(WebTheme.borderRadiusMedium),
      child: Padding(
        padding: const EdgeInsets.all(WebTheme.sm),
        child: Row(
          children: [
            CircleAvatar(
              radius: WebTheme.avatarSizeSmall / 2,
              backgroundColor: colorScheme.primaryContainer,
              backgroundImage:
                  avatarUrl != null ? NetworkImage(avatarUrl!) : null,
              child: avatarUrl == null
                  ? Icon(
                      Icons.person,
                      size: WebTheme.avatarSizeSmall / 2,
                      color: colorScheme.onPrimaryContainer,
                    )
                  : null,
            ),
            const SizedBox(width: WebTheme.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
*/
