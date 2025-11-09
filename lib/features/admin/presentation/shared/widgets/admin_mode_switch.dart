import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:thot/features/authentication/application/providers/auth_provider.dart';
import 'package:thot/core/navigation/route_names.dart';
class AdminModeSwitch extends StatelessWidget {
  const AdminModeSwitch({super.key});
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    if (!authProvider.isAdmin) return const SizedBox.shrink();
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.security,
        color: authProvider.isAdminMode ? Colors.amber : Colors.white,
      ),
      onSelected: (value) async {
        if (value == 'toggle') {
          final newMode = !authProvider.isAdminMode;
          await authProvider.setAdminMode(newMode);
          if (context.mounted) {
            if (newMode) {
              context.go(RouteNames.adminDashboard);
            } else {
              context.go(RouteNames.feed);
            }
          }
        }
      },
      itemBuilder: (BuildContext context) => [
        PopupMenuItem<String>(
          value: 'toggle',
          child: Row(
            children: [
              Icon(
                authProvider.isAdminMode
                    ? Icons.person
                    : Icons.security,
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                authProvider.isAdminMode
                    ? 'Switch to Normal Mode'
                    : 'Switch to Admin Mode',
                style: const TextStyle(fontFamily: 'Tailwind'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}