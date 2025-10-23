import 'package:flutter/material.dart';

/// Utilitaires pour la manipulation et l'optimisation des couleurs.
///
/// Cette classe fournit des méthodes statiques pour:
/// - Garantir le contraste d'accessibilité (WCAG 2.1)
/// - Adapter les couleurs selon le thème (clair/sombre)
/// - Assombrir/éclaircir les couleurs via HSL
///
/// Usage:
/// - [ensureContrast] : Utilisé dans les écrans admin pour les badges et textes
/// - [getSafeAccentColor] : Utilisé dans les écrans admin pour les conteneurs colorés
/// - [darken]/[lighten] : Méthodes internes pour l'ajustement HSL
class ColorUtils {
  // Constructeur privé pour empêcher l'instanciation
  ColorUtils._();

  // ==================== MÉTHODES PUBLIQUES ====================

  /// Garantit un contraste minimum entre une couleur de premier plan et d'arrière-plan.
  ///
  /// Calcule le ratio de contraste selon WCAG 2.1 et retourne:
  /// - La couleur d'origine si le contraste est suffisant
  /// - Blanc si l'arrière-plan est sombre
  /// - Noir si l'arrière-plan est clair
  ///
  /// [foreground] : Couleur du texte/icône
  /// [background] : Couleur de fond
  /// [minContrast] : Ratio minimum requis (4.5 par défaut pour AA)
  ///
  /// Usage actuel:
  /// - admin_dashboard_screen.dart:122,130,155,164,423
  /// - admin_reports_screen.dart:900,915,926,938
  static Color ensureContrast(
    Color foreground,
    Color background, {
    double minContrast = 4.5,
  }) {
    // Calculer les luminances relatives (0.0 à 1.0)
    final luminance1 = foreground.computeLuminance();
    final luminance2 = background.computeLuminance();

    // Calculer le ratio de contraste selon WCAG 2.1
    // Formule: (L1 + 0.05) / (L2 + 0.05) où L1 > L2
    final contrast = luminance1 > luminance2
        ? (luminance1 + 0.05) / (luminance2 + 0.05)
        : (luminance2 + 0.05) / (luminance1 + 0.05);

    // Contraste suffisant, retourner la couleur d'origine
    if (contrast >= minContrast) {
      return foreground;
    }

    // Ajuster pour atteindre le contraste minimum
    // Luminance < 0.5 = fond sombre → texte blanc
    // Luminance >= 0.5 = fond clair → texte noir
    return background.computeLuminance() < 0.5 ? Colors.white : Colors.black;
  }

  /// Adapte une couleur selon le thème actif pour garantir la lisibilité.
  ///
  /// Ajuste automatiquement:
  /// - En mode sombre : éclaircit les couleurs trop sombres
  /// - En mode clair : assombrit les couleurs trop claires
  ///
  /// [context] : BuildContext pour accéder au thème
  /// [baseColor] : Couleur de base à adapter
  ///
  /// Usage actuel:
  /// - admin_dashboard_screen.dart:418
  /// - admin_reports_screen.dart:890,917,928
  /// - admin_users_screen.dart:660,750,801
  static Color getSafeAccentColor(BuildContext context, Color baseColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final luminance = baseColor.computeLuminance();

    if (isDark) {
      // Mode sombre: éclaircir si trop sombre (luminance < 0.3)
      return luminance < 0.3 ? lighten(baseColor, 0.3) : baseColor;
    } else {
      // Mode clair: assombrir si trop clair (luminance > 0.7)
      return luminance > 0.7 ? darken(baseColor, 0.3) : baseColor;
    }
  }

  // ==================== MÉTHODES INTERNES ====================

  /// Assombrit une couleur via HSL.
  ///
  /// [color] : Couleur à assombrir
  /// [amount] : Quantité (0.0 à 1.0, défaut 0.1)
  ///
  /// Utilisée par [getSafeAccentColor] en mode clair.
  @visibleForTesting
  static Color darken(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1, 'amount doit être entre 0.0 et 1.0');

    final hsl = HSLColor.fromColor(color);
    final newLightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(newLightness).toColor();
  }

  /// Éclaircit une couleur via HSL.
  ///
  /// [color] : Couleur à éclaircir
  /// [amount] : Quantité (0.0 à 1.0, défaut 0.1)
  ///
  /// Utilisée par [getSafeAccentColor] en mode sombre.
  @visibleForTesting
  static Color lighten(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1, 'amount doit être entre 0.0 et 1.0');

    final hsl = HSLColor.fromColor(color);
    final newLightness = (hsl.lightness + amount).clamp(0.0, 1.0);
    return hsl.withLightness(newLightness).toColor();
  }
}
