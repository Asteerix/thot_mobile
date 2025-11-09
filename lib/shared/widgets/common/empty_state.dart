import 'package:flutter/material.dart';

/// Widget d'état vide réutilisable avec icône, titre, sous-titre et action optionnelle.
///
/// Affiche un message centré avec une icône dans un cercle de fond coloré,
/// un titre en gras, un sous-titre optionnel et un widget d'action personnalisable.
///
/// Supporte automatiquement le thème clair/sombre et inclut une animation
/// d'apparition en fondu + translation par défaut.
///
/// Utilisé dans :
/// - `followers_screen.dart` : État vide liste d'abonnés
/// - `following_screen.dart` : État vide liste d'abonnements
/// - `user_search.dart` : État vide recherche utilisateurs
/// - `saved_content_screen.dart` : État vide contenu enregistré
///
/// Exemple d'utilisation :
/// ```dart
/// EmptyState(
///   icon: Icons.bookmark,
///   title: 'Aucun contenu enregistré',
///   subtitle: 'Vos contenus enregistrés apparaîtront ici',
///   action: OutlinedButton(
///     onPressed: onRefresh,
///     child: const Text('Actualiser'),
///   ),
/// )
/// ```
class EmptyState extends StatelessWidget {
  /// Icône affichée dans un cercle de fond coloré
  final IconData icon;

  /// Titre principal en gras
  final String title;

  /// Sous-titre optionnel avec opacité réduite
  final String? subtitle;

  /// Widget d'action personnalisé (ex: bouton, lien)
  final Widget? action;

  /// Active/désactive l'animation d'apparition (défaut: true)
  final bool withAnimation;

  /// Taille de l'icône en pixels (défaut: 64)
  final double iconSize;

  /// Couleur de l'icône (défaut: blanc/noir selon thème avec opacité)
  final Color? iconColor;

  /// Style personnalisé du titre (défaut: bold 18px avec opacité selon thème)
  final TextStyle? titleStyle;

  /// Style personnalisé du sous-titre (défaut: 14px avec opacité selon thème)
  final TextStyle? subtitleStyle;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.withAnimation = true,
    this.iconSize = 64,
    this.iconColor,
    this.titleStyle,
    this.subtitleStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final content = Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIconContainer(isDark),
            const SizedBox(height: 24),
            _buildTitle(isDark),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              _buildSubtitle(isDark),
            ],
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );

    return withAnimation ? _buildAnimatedContent(content) : content;
  }

  /// Construit le conteneur circulaire avec l'icône
  Widget _buildIconContainer(bool isDark) {
    final baseColor = iconColor ?? (isDark ? Colors.white : Colors.black);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: baseColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: iconSize,
        color: iconColor ?? baseColor.withOpacity(0.5),
      ),
    );
  }

  /// Construit le titre avec style adapté au thème
  Widget _buildTitle(bool isDark) {
    return Text(
      title,
      style: titleStyle ??
          TextStyle(
            color: isDark
                ? Colors.white.withOpacity(0.9)
                : Colors.black.withOpacity(0.7),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
      textAlign: TextAlign.center,
    );
  }

  /// Construit le sous-titre avec style adapté au thème
  Widget _buildSubtitle(bool isDark) {
    return Text(
      subtitle!,
      style: subtitleStyle ??
          TextStyle(
            color: isDark
                ? Colors.white.withOpacity(0.6)
                : Colors.black.withOpacity(0.5),
            fontSize: 14,
            height: 1.5,
          ),
      textAlign: TextAlign.center,
    );
  }

  /// Enveloppe le contenu dans une animation de fondu + translation verticale
  Widget _buildAnimatedContent(Widget child) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  // ============================================================================
  // FACTORY CONSTRUCTORS INUTILISÉS - Commentés car jamais utilisés dans la codebase
  // ============================================================================
  // Les factory constructors ci-dessous ont été créés pour des cas d'usage
  // spécifiques mais ne sont actuellement utilisés nulle part dans le projet.
  // Ils sont conservés commentés pour référence future ou suppression ultérieure.
  //
  // Recherche effectuée le 2025-10-03 :
  // - EmptyState.search() : 0 usage
  // - EmptyState.favorites() : 0 usage
  // - EmptyState.notifications() : 0 usage
  //
  // Les usages actuels préfèrent le constructeur principal pour plus de flexibilité.
  // ============================================================================

  /*
  /// Factory constructor pour créer un état vide de recherche
  ///
  /// INUTILISÉ - Aucune occurrence dans la codebase
  factory EmptyState.search({
    required String searchTerm,
    String? customMessage,
    Widget? action,
    bool withAnimation = true,
  }) {
    return EmptyState(
      icon: Icons.search,
      title: 'Aucun résultat',
      subtitle: customMessage ?? 'Aucun résultat trouvé pour "$searchTerm"',
      action: action,
      withAnimation: withAnimation,
      iconColor: AppColors.blue,
    );
  }

  /// Factory constructor pour créer un état vide de favoris
  ///
  /// INUTILISÉ - Aucune occurrence dans la codebase
  factory EmptyState.favorites({
    String? customMessage,
    Widget? action,
    bool withAnimation = true,
  }) {
    return EmptyState(
      icon: Icons.favorite,
      title: 'Aucun favori',
      subtitle: customMessage ?? 'Vous n\'avez pas encore ajouté de favoris',
      action: action,
      withAnimation: withAnimation,
      iconColor: AppColors.red,
    );
  }

  /// Factory constructor pour créer un état vide de notifications
  ///
  /// INUTILISÉ - Aucune occurrence dans la codebase
  factory EmptyState.notifications({
    String? customMessage,
    Widget? action,
    bool withAnimation = true,
  }) {
    return EmptyState(
      icon: Icons.notifications,
      title: 'Aucune notification',
      subtitle: customMessage ?? 'Vous n\'avez pas de nouvelles notifications',
      action: action,
      withAnimation: withAnimation,
      iconColor: AppColors.warning,
    );
  }
  */
}
