import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/themes/web_theme.dart';
import '../../../../../shared/widgets/web/web_scaffold.dart';
class SavedContentScreenWeb extends ConsumerWidget {
  final String currentRoute;
  final Function(String route) onNavigate;
  const SavedContentScreenWeb({
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
          constraints: const BoxConstraints(maxWidth: WebTheme.maxContentWidth),
          padding: const EdgeInsets.all(WebTheme.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Contenu sauvegardé',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: WebTheme.xl),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bookmark, size: 64, color: colorScheme.outline),
                      const SizedBox(height: WebTheme.md),
                      Text(
                        'Aucun contenu sauvegardé',
                        style: TextStyle(fontSize: 18, color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}