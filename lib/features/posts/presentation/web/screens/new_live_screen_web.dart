import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/themes/web_theme.dart';
import '../../../../../shared/widgets/web/web_scaffold.dart';
class NewLiveScreenWeb extends ConsumerWidget {
  final String currentRoute;
  final Function(String route) onNavigate;
  const NewLiveScreenWeb({
    super.key,
    required this.currentRoute,
    required this.onNavigate,
  });
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    return WebScaffold(
      currentRoute: currentRoute,
      onNavigate: onNavigate,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          padding: const EdgeInsets.all(WebTheme.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.tv, size: 80, color: colorScheme.primary),
              const SizedBox(height: WebTheme.lg),
              Text(
                'Nouveau Live',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: WebTheme.md),
              Text(
                'Fonctionnalité disponible prochainement',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}