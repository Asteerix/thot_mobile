import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/themes/web_theme.dart';
import '../../../../../shared/widgets/web/web_scaffold.dart';
class FollowingScreenWeb extends ConsumerWidget {
  final String currentRoute;
  final Function(String route) onNavigate;
  final String userId;
  const FollowingScreenWeb({
    super.key,
    required this.currentRoute,
    required this.onNavigate,
    required this.userId,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back),
                    onPressed: () => onNavigate('/profile/$userId'),
                  ),
                  const SizedBox(width: WebTheme.md),
                  Text(
                    'Abonnements',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: WebTheme.xl),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.group,
                          size: 64, color: colorScheme.outline),
                      const SizedBox(height: WebTheme.md),
                      Text(
                        'Aucun abonnement',
                        style: TextStyle(
                          fontSize: 18,
                          color: colorScheme.onSurfaceVariant,
                        ),
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