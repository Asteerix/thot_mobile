import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Bottom navigation bar with animated icons and theme-aware styling.
///
/// Displays different navigation items based on authentication status:
/// - Authenticated: Home, Subscriptions, Shorts, Explore, Profile
/// - Unauthenticated: Home, Shorts, Explore, Login
class BottomNavBar extends StatefulWidget {
  /// Current selected tab index
  final int currentIndex;

  /// Callback when a tab is tapped
  final void Function(int) onTap;

  /// Whether user is authenticated (affects displayed tabs)
  final bool isAuthenticated;

  // DEAD CODE: Parameter 'isJournalist' never used in implementation
  // final bool isJournalist;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.isAuthenticated = true,
  });

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

// ============================================================================
// PRIVATE STATE
// ============================================================================

class _BottomNavBarState extends State<BottomNavBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _scaleAnimation;

  // Constants
  static const _animationDuration = Duration(milliseconds: 200);
  static const _scaleBegin = 0.95;
  static const _scaleEnd = 1.0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  @override
  void didUpdateWidget(BottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _animationController.forward(from: 0);
      HapticFeedback.lightImpact();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ============================================================================
  // INITIALIZATION
  // ============================================================================

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: _animationDuration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: _scaleBegin,
      end: _scaleEnd,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
  }

  // ============================================================================
  // UI BUILDERS
  // ============================================================================

  /// Builds a single navigation item with icon and label
  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final isSelected = widget.currentIndex == index;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Theme-aware color selection
    final iconColor = _getIconColor(isDarkMode, isSelected);

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, _) => Transform.scale(
        scale: isSelected ? _scaleAnimation.value : 1.0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildIcon(icon, activeIcon, isSelected, index, iconColor),
            const SizedBox(height: 2),
            _buildLabel(label, isSelected, iconColor),
          ],
        ),
      ),
    );
  }

  /// Builds the animated icon
  Widget _buildIcon(
    IconData icon,
    IconData activeIcon,
    bool isSelected,
    int index,
    Color iconColor,
  ) {
    return AnimatedSwitcher(
      duration: _animationDuration,
      child: Icon(
        isSelected ? activeIcon : icon,
        key: ValueKey('icon-$index-${isSelected ? activeIcon.codePoint : icon.codePoint}'),
        size: 22,
        color: iconColor,
      ),
    );
  }

  /// Builds the label text
  Widget _buildLabel(String label, bool isSelected, Color iconColor) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        label,
        style: TextStyle(
          fontSize: isSelected ? 10 : 9,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          color: iconColor,
        ),
        maxLines: 1,
        overflow: TextOverflow.visible,
      ),
    );
  }

  // ============================================================================
  // HELPERS
  // ============================================================================

  /// Returns appropriate icon color based on theme and selection state
  Color _getIconColor(bool isDarkMode, bool isSelected) {
    if (isDarkMode) {
      return isSelected ? Colors.white : Colors.white.withOpacity(0.6);
    }
    return isSelected ? Colors.black : Colors.black.withOpacity(0.6);
  }

  // ============================================================================
  // BUILD
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    final items = _getNavigationItems();

    return Container(
      decoration: _buildNavBarDecoration(isDarkMode),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: SizedBox(
          height: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: _buildNavigationButtons(items, isDarkMode),
          ),
        ),
      ),
    );
  }

  /// Returns list of navigation items based on authentication status
  List<Widget> _getNavigationItems() {
    final items = <Widget>[];
    var itemIndex = 0;

    // Home (always visible)
    items.add(_buildNavItem(
      icon: Icons.feed,
      activeIcon: Icons.dynamic_feed,
      label: 'Publications',
      index: itemIndex++,
    ));

    if (widget.isAuthenticated) {
      items.addAll(_buildAuthenticatedItems(itemIndex));
    } else {
      items.addAll(_buildUnauthenticatedItems(itemIndex));
    }

    return items;
  }

  /// Builds items for authenticated users
  List<Widget> _buildAuthenticatedItems(int startIndex) {
    var index = startIndex;
    return [
      _buildNavItem(
        icon: Icons.subscriptions,
        activeIcon: Icons.subscriptions,
        label: 'Abonnés',
        index: index++,
      ),
      _buildNavItem(
        icon: Icons.play_circle_outline,
        activeIcon: Icons.play_circle_filled,
        label: 'Shorts',
        index: index++,
      ),
      _buildNavItem(
        icon: Icons.search,
        activeIcon: Icons.search,
        label: 'Explorer',
        index: index++,
      ),
      _buildNavItem(
        icon: Icons.person,
        activeIcon: Icons.person,
        label: 'Profil',
        index: index++,
      ),
    ];
  }

  /// Builds items for unauthenticated users
  List<Widget> _buildUnauthenticatedItems(int startIndex) {
    var index = startIndex;
    return [
      _buildNavItem(
        icon: Icons.play_circle_outline,
        activeIcon: Icons.play_circle_filled,
        label: 'Shorts',
        index: index++,
      ),
      _buildNavItem(
        icon: Icons.search,
        activeIcon: Icons.search,
        label: 'Explorer',
        index: index++,
      ),
      _buildNavItem(
        icon: Icons.person,
        activeIcon: Icons.person,
        label: 'Connexion',
        index: index++,
      ),
    ];
  }

  /// Builds the navigation bar decoration with border
  BoxDecoration _buildNavBarDecoration(bool isDarkMode) {
    return BoxDecoration(
      color: isDarkMode ? Colors.black : Colors.white,
      border: Border(
        top: BorderSide(
          color: isDarkMode
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.1),
          width: 0.5,
        ),
      ),
    );
  }

  /// Builds interactive navigation buttons
  List<Widget> _buildNavigationButtons(List<Widget> items, bool isDarkMode) {
    return items.asMap().entries.map((entry) {
      final actualIndex = entry.key;
      final item = entry.value;

      return Expanded(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => widget.onTap(actualIndex),
            splashColor: isDarkMode
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.1),
            highlightColor: isDarkMode
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.05),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: item,
              ),
            ),
          ),
        ),
      );
    }).toList();
  }
}
