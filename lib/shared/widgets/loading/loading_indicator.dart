import 'package:flutter/material.dart';

/// Widget d'indicateur de chargement simple et réutilisable.
///
/// Affiche un CircularProgressIndicator avec options de personnalisation :
/// - [size] : Taille de l'indicateur (défaut: 40.0)
/// - [color] : Couleur de l'indicateur (défaut: theme.colorScheme.primary)
/// - [withBackground] : Affiche un fond arrondi avec ombre (défaut: false)
///
/// Usage actif dans le codebase :
/// - profile_screen.dart : Chargement des posts/shorts/questions
/// - following_screen.dart : Chargement de la liste des abonnements
/// - feed_screen_web.dart : Chargement du feed principal
/// - shorts_feed_screen_web.dart : Chargement des shorts
/// - user_search.dart : Recherche d'utilisateurs
///
/// Note : Pour un indicateur avec détection de connexion lente et mode hors ligne,
/// utiliser SmartLoadingIndicator à la place.
class LoadingIndicator extends StatelessWidget {
  /// Taille de l'indicateur en pixels
  final double size;

  /// Couleur de l'indicateur (utilise theme.colorScheme.primary si null)
  final Color? color;

  /// Affiche un conteneur avec fond et ombre autour de l'indicateur
  final bool withBackground;

  const LoadingIndicator({
    super.key,
    this.size = 40.0,
    this.color,
    this.withBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final indicator = SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 2.0,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? colorScheme.primary,
        ),
      ),
    );

    if (!withBackground) {
      return indicator;
    }

    return Container(
      width: size * 2,
      height: size * 2,
      decoration: BoxDecoration(
        color: colorScheme.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: colorScheme.surface.withOpacity(0.2),
            blurRadius: 16.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(child: indicator),
    );
  }
}
