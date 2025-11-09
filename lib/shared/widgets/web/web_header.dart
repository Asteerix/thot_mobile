import 'package:flutter/material.dart';
import '../../../core/themes/web_theme.dart';

/// Web header with search bar and user menu
class WebHeader extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final TextEditingController? searchController;
  final Function(String)? onSearch;
  final VoidCallback? onSearchSubmit;
  final String? searchHint;
  final int notificationCount;
  final VoidCallback? onNotificationTap;
  final String? userAvatarUrl;
  final String? userName;
  final VoidCallback? onProfileTap;
  final List<PopupMenuEntry<String>>? profileMenuItems;
  final Function(String)? onProfileMenuSelected;
  final bool showSearchBar;
  final Widget? leading;
  final List<Widget>? actions;

  const WebHeader({
    super.key,
    this.title,
    this.searchController,
    this.onSearch,
    this.onSearchSubmit,
    this.searchHint = 'Search...',
    this.notificationCount = 0,
    this.onNotificationTap,
    this.userAvatarUrl,
    this.userName,
    this.onProfileTap,
    this.profileMenuItems,
    this.onProfileMenuSelected,
    this.showSearchBar = true,
    this.leading,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(WebTheme.headerHeight);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: WebTheme.headerHeight,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: WebTheme.lg),
      child: Row(
        children: [
          // Leading or Logo
          if (leading != null) leading! else _buildLogo(context, colorScheme),

          const SizedBox(width: WebTheme.lg),

          // Search bar (center)
          if (showSearchBar) ...[
            Expanded(
              child: Center(
                child: _buildSearchBar(context, colorScheme),
              ),
            ),
          ] else ...[
            if (title != null)
              Expanded(
                child: Text(
                  title!,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                ),
              )
            else
              const Spacer(),
          ],

          const SizedBox(width: WebTheme.lg),

          // Actions (right side)
          if (actions != null) ...actions!,

          // Notification icon
          if (onNotificationTap != null)
            _buildNotificationButton(context, colorScheme),

          const SizedBox(width: WebTheme.md),

          // Profile menu
          _buildProfileMenu(context, colorScheme),
        ],
      ),
    );
  }

  Widget _buildLogo(BuildContext context, ColorScheme colorScheme) {
    return Text(
      'THOT',
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: colorScheme.primary,
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, ColorScheme colorScheme) {
    return Container(
      constraints: const BoxConstraints(
        maxWidth: WebTheme.searchBarWidth,
      ),
      height: WebTheme.searchBarHeight,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(WebTheme.borderRadiusLarge),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: TextField(
        controller: searchController,
        onChanged: onSearch,
        onSubmitted: (_) => onSearchSubmit?.call(),
        style: TextStyle(
          fontSize: 14,
          color: colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          hintText: searchHint,
          hintStyle: TextStyle(
            color: colorScheme.onSurface.withOpacity(0.5),
          ),
          prefixIcon: Icon(
            Icons.search,
            color: colorScheme.onSurface.withOpacity(0.5),
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: WebTheme.md,
            vertical: WebTheme.sm,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationButton(
      BuildContext context, ColorScheme colorScheme) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: Icon(
            Icons.notifications,
            color: colorScheme.onSurface,
          ),
          onPressed: onNotificationTap,
          tooltip: 'Notifications',
        ),
        if (notificationCount > 0)
          Positioned(
            right: 8,
            top: 8,
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
                notificationCount > 9 ? '9+' : '$notificationCount',
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

  Widget _buildProfileMenu(BuildContext context, ColorScheme colorScheme) {
    if (profileMenuItems == null || profileMenuItems!.isEmpty) {
      return _buildSimpleProfileButton(context, colorScheme);
    }

    return PopupMenuButton<String>(
      onSelected: onProfileMenuSelected,
      offset: const Offset(0, 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(WebTheme.borderRadiusMedium),
      ),
      itemBuilder: (context) => profileMenuItems!,
      child: _buildProfileButton(context, colorScheme),
    );
  }

  Widget _buildSimpleProfileButton(
      BuildContext context, ColorScheme colorScheme) {
    return InkWell(
      onTap: onProfileTap,
      borderRadius: BorderRadius.circular(WebTheme.avatarSizeSmall / 2),
      child: _buildProfileButton(context, colorScheme),
    );
  }

  Widget _buildProfileButton(BuildContext context, ColorScheme colorScheme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: WebTheme.avatarSizeSmall / 2,
          backgroundColor: colorScheme.primaryContainer,
          backgroundImage:
              userAvatarUrl != null ? NetworkImage(userAvatarUrl!) : null,
          child: userAvatarUrl == null
              ? Icon(
                  Icons.person,
                  size: WebTheme.avatarSizeSmall / 2,
                  color: colorScheme.onPrimaryContainer,
                )
              : null,
        ),
        if (userName != null) ...[
          const SizedBox(width: WebTheme.sm),
          Text(
            userName!,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: WebTheme.xs),
          Icon(
            Icons.keyboard_arrow_down,
            size: 20,
            color: colorScheme.onSurface.withOpacity(0.5),
          ),
        ],
      ],
    );
  }
}

/// Simple sticky header wrapper
class StickyWebHeader extends StatelessWidget {
  final PreferredSizeWidget header;
  final Widget body;

  const StickyWebHeader({
    super.key,
    required this.header,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        header,
        Expanded(child: body),
      ],
    );
  }
}
