// ❌ FICHIER INUTILISÉ - CODE COMMENTÉ
//
// Ce fichier n'est JAMAIS utilisé dans la codebase mobile/lib/
//
// Raison de conservation : Exporté dans widgets.dart mais aucune utilisation trouvée
// Date d'analyse : 2025-10-03
//
// Alternatives existantes :
// - LogoWhite : Logo blanc avec ombres, utilisé dans app_header.dart
// - Logo : Container coloré avec texte "THOT", utilisé dans auth screens
//
// LogoBlack serait une variante adaptative au thème (noir/blanc selon le contexte)
// mais cette fonctionnalité n'est actuellement pas nécessaire dans l'application.
//
// Action recommandée : Supprimer ce fichier et retirer l'export de widgets.dart:27
//
// Si vous avez besoin d'un logo adaptatif au thème, décommentez ce code :

/*
import 'package:flutter/material.dart';

/// Logo adaptatif au thème de l'application
///
/// Widget de logo qui s'adapte automatiquement à la couleur du thème.
/// Contrairement à [LogoWhite] (blanc fixe) et [Logo] (container coloré),
/// ce widget utilise la couleur onSurface du thème actuel.
///
/// **Caractéristiques :**
/// - Taille par défaut : 28dp (vs 90dp pour LogoWhite)
/// - Couleur adaptative selon le thème (clair/sombre)
/// - Accessibilité : textScaler limité, semantics
/// - Sous-titre optionnel "MANUFACTURING KNOWLEDGE"
///
/// **Utilisation :**
/// ```dart
/// LogoBlack(
///   wordmarkSize: 32.0,
///   showSubtitle: true,
///   color: Colors.black, // optionnel, override la couleur du thème
/// )
/// ```
class LogoBlack extends StatelessWidget {
  /// Taille de la police du mot-clé "thot"
  final double wordmarkSize;

  /// Afficher ou non le sous-titre "MANUFACTURING KNOWLEDGE"
  final bool showSubtitle;

  /// Couleur du logo. Si null, utilise la couleur onSurface du thème
  final Color? color;

  /// Padding autour du logo
  final EdgeInsetsGeometry padding;

  /// Label sémantique personnalisé pour l'accessibilité
  final String? semanticsLabel;

  const LogoBlack({
    super.key,
    this.wordmarkSize = 28.0,
    this.showSubtitle = false,
    this.color,
    this.padding = EdgeInsets.zero,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    final Color effectiveColor =
        color ?? Theme.of(context).colorScheme.onSurface;

    // Gestion du text scaling pour l'accessibilité
    // Le wordmark reste fixe, le tagline peut s'adapter jusqu'à 1.6x
    final double scale = MediaQuery.textScalerOf(context).scale(1.0);
    final double taglineScale = scale.clamp(1.0, 1.6);

    final Widget logo = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Wordmark principal
        Text(
          'thot',
          textScaler: const TextScaler.linear(1.0),
          maxLines: 1,
          style: TextStyle(
            color: effectiveColor,
            fontSize: wordmarkSize,
            fontFamily: 'Tailwind',
            fontWeight: FontWeight.w900,
            letterSpacing: 0.0,
            height: 1.0,
          ),
        ),

        // Sous-titre optionnel
        if (showSubtitle)
          Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Text(
              'MANUFACTURING KNOWLEDGE',
              textScaler: TextScaler.linear(taglineScale),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: effectiveColor.withOpacity(0.72),
                fontSize: wordmarkSize * 0.16,
                fontFamily: 'Tailwind',
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
                height: 1.0,
              ),
            ),
          ),
      ],
    );

    // Wrapper sémantique pour l'accessibilité
    return Padding(
      padding: padding,
      child: Semantics(
        header: true,
        label: semanticsLabel ?? 'thot — Manufacturing knowledge',
        child: ExcludeSemantics(child: logo),
      ),
    );
  }
}
*/
