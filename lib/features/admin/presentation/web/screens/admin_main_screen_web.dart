import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../features/authentication/application/providers/auth_provider.dart';
import '../../../../../core/navigation/route_names.dart';
import '../../../../../core/themes/web_theme.dart';
import 'admin_dashboard_screen_web.dart';
import 'admin_journalists_screen_web.dart';
import 'admin_users_screen_web.dart';
import 'admin_reports_screen_web.dart';
class AdminMainScreenWeb extends StatefulWidget {
  const AdminMainScreenWeb({super.key});
  @override
  State<AdminMainScreenWeb> createState() => _AdminMainScreenWebState();
}
class _AdminMainScreenWebState extends State<AdminMainScreenWeb> {
  String _currentRoute = '/admin/dashboard';
  final Map<String, Widget Function(String, Function(String))> _screens = {
    '/admin/dashboard': (route, onNavigate) => AdminDashboardScreenWeb(
          currentRoute: route,
          onNavigate: onNavigate,
        ),
    '/admin/journalists': (route, onNavigate) => AdminJournalistsScreenWeb(
          currentRoute: route,
          onNavigate: onNavigate,
        ),
    '/admin/users': (route, onNavigate) => AdminUsersScreenWeb(
          currentRoute: route,
          onNavigate: onNavigate,
        ),
    '/admin/reports': (route, onNavigate) => AdminReportsScreenWeb(
          currentRoute: route,
          onNavigate: onNavigate,
        ),
  };
  void _onNavigate(String route) {
    setState(() => _currentRoute = route);
  }
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
    final colorScheme = Theme.of(context).colorScheme;
    if (!authProvider.isAuthenticated ||
        authProvider.userProfile?.role != 'admin') {
      return Scaffold(
        backgroundColor: colorScheme.background,
        body: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(WebTheme.xxl),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(WebTheme.xxl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.block,
                        size: 80, color: colorScheme.error.withOpacity(0.8)),
                    const SizedBox(height: WebTheme.xl),
                    Text(
                      'Accès non autorisé',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: WebTheme.md),
                    Text(
                      'Vous devez être administrateur pour accéder à cette page',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: WebTheme.xl),
                    FilledButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Retour'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    final screenBuilder = _screens[_currentRoute];
    if (screenBuilder == null) {
      return Scaffold(
        body: Center(
          child: Text('Screen not found: $_currentRoute'),
        ),
      );
    }
    return Scaffold(
      backgroundColor: colorScheme.background,
      body: Row(
        children: [
          Container(
            width: 280,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                right: BorderSide(color: colorScheme.outlineVariant),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(WebTheme.lg),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: colorScheme.outlineVariant),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.admin_panel_settings,
                          color: colorScheme.primary, size: 28),
                      const SizedBox(width: WebTheme.sm),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Administration',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Mode admin',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: WebTheme.sm),
                    children: [
                      _buildNavItem(
                        context,
                        icon: Icons.dashboard,
                        label: 'Tableau de bord',
                        route: '/admin/dashboard',
                        colorScheme: colorScheme,
                      ),
                      _buildNavItem(
                        context,
                        icon: Icons.badge,
                        label: 'Journalistes',
                        route: '/admin/journalists',
                        colorScheme: colorScheme,
                      ),
                      _buildNavItem(
                        context,
                        icon: Icons.people,
                        label: 'Utilisateurs',
                        route: '/admin/users',
                        colorScheme: colorScheme,
                      ),
                      _buildNavItem(
                        context,
                        icon: Icons.flag,
                        label: 'Signalements',
                        route: '/admin/reports',
                        colorScheme: colorScheme,
                      ),
                      const Divider(height: 32),
                      _buildNavItem(
                        context,
                        icon: Icons.swap_horiz,
                        label: 'Mode normal',
                        onTap: () => _switchToUserMode(context),
                        colorScheme: colorScheme,
                      ),
                      _buildNavItem(
                        context,
                        icon: Icons.logout,
                        label: 'Déconnexion',
                        onTap: () => _showLogoutDialog(context),
                        colorScheme: colorScheme,
                        isDestructive: true,
                      ),
                    ],
                  ),
                ),
                if (authProvider.userProfile != null)
                  Container(
                    padding: const EdgeInsets.all(WebTheme.md),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: colorScheme.outlineVariant),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: colorScheme.primaryContainer,
                          child: Text(
                            authProvider.userProfile!.username[0].toUpperCase(),
                            style: TextStyle(
                              color: colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: WebTheme.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                authProvider.userProfile!.name ??
                                    authProvider.userProfile!.username,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '@${authProvider.userProfile!.username}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: screenBuilder(_currentRoute, _onNavigate),
          ),
        ],
      ),
    );
  }
  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    String? route,
    VoidCallback? onTap,
    required ColorScheme colorScheme,
    bool isDestructive = false,
  }) {
    final isSelected = route != null && _currentRoute == route;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: WebTheme.sm,
        vertical: 2,
      ),
      child: Material(
        color: isSelected
            ? colorScheme.primaryContainer
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap ?? (route != null ? () => _onNavigate(route) : null),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: WebTheme.md,
              vertical: WebTheme.sm,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: isSelected
                      ? colorScheme.onPrimaryContainer
                      : isDestructive
                          ? colorScheme.error
                          : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: WebTheme.md),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? colorScheme.onPrimaryContainer
                        : isDestructive
                            ? colorScheme.error
                            : colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  void _showLogoutDialog(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
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
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
  }
}