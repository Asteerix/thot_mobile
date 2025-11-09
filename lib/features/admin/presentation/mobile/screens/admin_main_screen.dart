import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thot/features/authentication/application/providers/auth_provider.dart';
import 'package:thot/core/navigation/route_names.dart';
import 'package:thot/core/utils/safe_navigation.dart';
import 'admin_dashboard_screen.dart';
import 'admin_journalists_screen.dart';
import 'admin_users_screen.dart';
import 'admin_reports_screen.dart';
typedef ScreenBuilder = Widget Function();
class AdminNavItem {
  final String id;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final ScreenBuilder builder;
  const AdminNavItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.builder,
  });
}
class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});
  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}
class _AdminMainScreenState extends State<AdminMainScreen>
    with RestorationMixin {
  final RestorableInt _currentIndex = RestorableInt(0);
  final PageStorageBucket _bucket = PageStorageBucket();
  static const List<AdminNavItem> _items = [
    AdminNavItem(
      id: 'dashboard',
      label: 'Tableau de bord',
      icon: Icons.dashboard,
      selectedIcon: Icons.dashboard,
      builder: AdminDashboardScreen.new,
    ),
    AdminNavItem(
      id: 'journalists',
      label: 'Journalistes',
      icon: Icons.verified,
      selectedIcon: Icons.verified,
      builder: AdminJournalistsScreen.new,
    ),
    AdminNavItem(
      id: 'reports',
      label: 'Signalements',
      icon: Icons.flag,
      selectedIcon: Icons.flag,
      builder: AdminReportsScreen.new,
    ),
    AdminNavItem(
      id: 'users',
      label: 'Utilisateurs',
      icon: Icons.group,
      selectedIcon: Icons.group,
      builder: AdminUsersScreen.new,
    ),
  ];
  List<Widget> get _screens => _items
      .map((e) => KeyedSubtree(
            key: PageStorageKey('admin_${e.id}'),
            child: e.builder(),
          ))
      .toList();
  @override
  String? get restorationId => 'admin_panel_screen';
  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_currentIndex, 'admin_current_index');
  }
  void _onSelect(int index) => setState(() => _currentIndex.value = index);
  Future<void> _switchToUserMode(BuildContext context) async {
    final navigator = Navigator.of(context);
    await context.read<AuthProvider>().setAdminMode(false);
    if (!mounted) return;
    navigator.pushNamedAndRemoveUntil(RouteNames.feed, (route) => false);
  }
  Future<void> _logout(BuildContext context) async {
    final navigator = Navigator.of(context);
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    navigator.pushNamedAndRemoveUntil(RouteNames.login, (route) => false);
  }
  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    if (!authProvider.isAuthenticated ||
        authProvider.userProfile?.role != 'admin') {
      return Scaffold(
        appBar: AppBar(title: Text('Administration')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              margin: const EdgeInsets.all(24),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.block,
                        size: 56, color: Theme.of(context).colorScheme.error),
                    const SizedBox(height: 16),
                    const Text('Accès non autorisé',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    const Text(
                        'Vous devez être administrateur pour accéder à cette page',
                        textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: () => SafeNavigation.pop(context),
                      child: const Text('Retour'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final isMedium = w >= 840 && w < 1200;
        final isExpanded = w >= 1200;
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final appBar = AppBar(
          titleSpacing: 12,
          backgroundColor: colorScheme.surface,
          surfaceTintColor: colorScheme.surfaceTint,
          title: Row(
            children: [
              Icon(Icons.security),
              const SizedBox(width: 8),
              const Text('Administration'),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Mode admin',
                  style: TextStyle(
                    color: colorScheme.onSecondaryContainer,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            Tooltip(
              message: 'Mode normal',
              child: IconButton(
                icon: Icon(Icons.swap_horiz),
                onPressed: () => _switchToUserMode(context),
              ),
            ),
            Tooltip(
              message: 'Déconnexion',
              child: IconButton(
                icon: Icon(Icons.logout),
                onPressed: () => _showLogoutDialog(context),
              ),
            ),
          ],
        );
        final content = SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1400),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: PageStorage(
                  bucket: _bucket,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: IndexedStack(
                      key: ValueKey(_currentIndex.value),
                      index: _currentIndex.value,
                      children: _screens,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        if (isExpanded) {
          return Scaffold(
            appBar: appBar,
            body: Row(
              children: [
                SafeArea(
                  right: false,
                  child: SizedBox(
                    width: 280,
                    child: NavigationDrawer(
                      backgroundColor: colorScheme.surfaceContainerLow,
                      selectedIndex: _currentIndex.value,
                      onDestinationSelected: _onSelect,
                      children: [
                        const SizedBox(height: 8),
                        ..._items.map(
                          (e) => NavigationDrawerDestination(
                            icon: Tooltip(
                              message: e.label,
                              child: Icon(e.icon),
                            ),
                            selectedIcon: Icon(e.selectedIcon),
                            label: Text(e.label),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: content),
              ],
            ),
          );
        } else if (isMedium) {
          return Scaffold(
            appBar: appBar,
            body: Row(
              children: [
                SafeArea(
                  right: false,
                  child: NavigationRail(
                    backgroundColor: colorScheme.surface,
                    selectedIndex: _currentIndex.value,
                    onDestinationSelected: _onSelect,
                    labelType: NavigationRailLabelType.all,
                    groupAlignment: -1.0,
                    destinations: _items
                        .map((e) => NavigationRailDestination(
                              icon: Tooltip(
                                message: e.label,
                                child: Icon(e.icon),
                              ),
                              selectedIcon: Icon(e.selectedIcon),
                              label: Text(e.label),
                            ))
                        .toList(),
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: content),
              ],
            ),
          );
        } else {
          return Scaffold(
            appBar: appBar,
            body: content,
            bottomNavigationBar: NavigationBar(
              backgroundColor: colorScheme.surface,
              selectedIndex: _currentIndex.value,
              onDestinationSelected: _onSelect,
              destinations: _items
                  .map((e) => NavigationDestination(
                        icon: Icon(e.icon),
                        selectedIcon: Icon(e.selectedIcon),
                        label: e.label,
                        tooltip: e.label,
                      ))
                  .toList(),
              labelBehavior: w < 360
                  ? NavigationDestinationLabelBehavior.alwaysHide
                  : NavigationDestinationLabelBehavior.alwaysShow,
            ),
          );
        }
      },
    );
  }
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _logout(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
  }
  @override
  void dispose() {
    _currentIndex.dispose();
    super.dispose();
  }
}