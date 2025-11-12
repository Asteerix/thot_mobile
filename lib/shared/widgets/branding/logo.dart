import 'package:flutter/material.dart';

/// Widget affichant le logo THOT dans un container coloré.
///
/// Ce widget est utilisé principalement dans les écrans d'authentification
/// et certains écrans de questions journaliste.
///
/// Utilisé dans:
/// - registration_form.dart
/// - login_screen.dart
/// - banned_account_screen.dart
/// - verification_pending_screen.dart
/// - journalist_question.dart
///
/// Note: Il existe également [LogoWhite] pour le header avec un style différent.
/// [LogoBlack] existe mais n'est jamais utilisé dans la codebase.
class Logo extends StatelessWidget {
  /// Largeur du container. Par défaut: 120
  final double? width;

  /// Hauteur du container. Par défaut: 60
  final double? height;

  /// Couleur de fond du container. Par défaut: couleur primaire du thème
  final Color? color;

  const Logo({
    super.key,
    this.width,
    this.height,
    this.color,
  });

  // Constantes pour éviter les magic numbers
  static const double _defaultWidth = 120.0;
  static const double _defaultHeight = 60.0;
  static const double _borderRadius = 8.0;
  static const double _fontSize = 24.0;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/logo.jpeg',
      width: width ?? _defaultWidth * 2,
      height: height ?? _defaultHeight,
      fit: BoxFit.contain,
    );
  }
}
