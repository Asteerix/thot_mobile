import 'package:flutter/material.dart';

// ============================================================================
// FICHIER OBSOLÈTE - À SUPPRIMER APRÈS MIGRATION
// ============================================================================
//
// Ce fichier est un doublon de empty_state.dart avec moins de fonctionnalités.
//
// PROBLÈME:
// - Duplication de code et de logique avec EmptyState
// - Fonctionnalités limitées (pas d'animation, pas de personnalisation avancée)
// - Moins flexible (pas de factory constructors, pas de custom styles)
// - Maintenance double nécessaire pour des besoins identiques
//
// MIGRATION RECOMMANDÉE:
// Remplacer tous les usages de EmptyContentView par EmptyState:
//
// AVANT:
// EmptyContentView(
//   icon: Icons.inbox,
//   title: 'Aucun contenu',
//   subtitle: 'Description',
//   actionLabel: 'Actualiser',
//   onAction: () => _refresh(),
// )
//
// APRÈS:
// EmptyState(
//   icon: Icons.inbox,
//   title: 'Aucun contenu',
//   subtitle: 'Description',
//   action: ElevatedButton.icon(
//     onPressed: _refresh,
//     icon: Icon(Icons.refresh),
//     label: Text('Actualiser'),
//   ),
// )
//
// FICHIERS À MIGRER (4 usages):
// 1. mobile/lib/features/profile/presentation/mobile/screens/profile_screen.dart
// 2. mobile/lib/features/posts/presentation/mobile/screens/feed/feed_screen.dart
// 3. mobile/lib/features/posts/presentation/mobile/screens/other/shorts_screen.dart
// 4. mobile/lib/features/settings/presentation/mobile/screens/subscriptions_screen.dart
//
// AVANTAGES DE EmptyState:
// - Animation d'entrée fluide (TweenAnimationBuilder)
// - Personnalisation complète (iconColor, titleStyle, subtitleStyle)
// - Factory constructors pour cas communs (.search(), .favorites(), .notifications())
// - Container décoré autour de l'icône pour meilleur design
// - Widget action flexible (accepte n'importe quel Widget)
// - Padding et spacing optimisés
//
// ============================================================================

/// Vue vide réutilisable avec icône, message et bouton d'action
/// Supporte automatiquement le mode sombre/clair
///
/// ⚠️ OBSOLÈTE: Utiliser EmptyState à la place
class EmptyContentView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyContentView({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            // Thème sombre: icône blanche, thème clair: icône grise
            color: isDark ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              // Thème sombre: texte blanc, thème clair: texte gris foncé
              color: isDark ? Colors.white.withOpacity(0.6) : Colors.black.withOpacity(0.6),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: TextStyle(
                // Thème sombre: texte blanc, thème clair: texte gris
                color: isDark ? Colors.white.withOpacity(0.38) : Colors.black.withOpacity(0.38),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (onAction != null && actionLabel != null) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onAction,
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark ? Colors.white : null,
                side: BorderSide(
                  color: isDark ? Colors.white.withOpacity(0.5) : cs.outline,
                ),
              ),
              icon: Icon(Icons.refresh),
              label: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
