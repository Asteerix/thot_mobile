import 'package:flutter/material.dart';

/// Logo blanc de l'application avec effet d'ombre
///
/// Utilisé principalement dans [AppHeader] pour l'affichage sur fond sombre.
/// Pour un logo noir/adaptable au thème, voir [LogoBlack].
///
/// **Utilisation :**
/// - `app_header.dart` : Logo blanc dans l'en-tête de l'application
class LogoWhite extends StatelessWidget {
  /// Taille de la police du mot-clé "thot"
  final double fontSize;

  /// Espacement entre les lettres du mot-clé
  final double letterSpacing;

  /// Afficher ou non le sous-titre "MANUFACTURING KNOWLEDGE"
  final bool showSubtitle;

  /// Padding autour du logo
  final EdgeInsetsGeometry padding;

  /// Label sémantique personnalisé pour l'accessibilité
  final String? semanticsLabel;

  const LogoWhite({
    super.key,
    this.fontSize = 90,
    this.letterSpacing = 4,
    this.showSubtitle = true,
    this.padding = EdgeInsets.zero,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    // Gestion du text scaling pour l'accessibilité
    // Le wordmark reste fixe, le tagline peut s'adapter
    final double textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final double taglineScale = textScale.clamp(1.0, 1.6);

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
            color: Colors.white,
            fontSize: fontSize,
            fontFamily: 'Tailwind',
            fontWeight: FontWeight.w900,
            letterSpacing: letterSpacing,
            height: 1.0,
            shadows: const [
              Shadow(blurRadius: 20, color: Color(0x40FFFFFF)),
              Shadow(blurRadius: 40, color: Color(0x20FFFFFF)),
            ],
          ),
        ),

        // Sous-titre optionnel
        if (showSubtitle) ...[
          const SizedBox(height: 10),
          Text(
            'MANUFACTURING KNOWLEDGE',
            textScaler: TextScaler.linear(taglineScale),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withOpacity(0.92),
              fontSize: (fontSize * 0.15).clamp(10.0, 22.0),
              fontFamily: 'Tailwind',
              fontWeight: FontWeight.w900,
              letterSpacing: fontSize * 0.02,
              height: 1.05,
            ),
          ),
        ],
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
