// ============================================================================
// FICHIER INUTILISÉ - COMMENTÉ LE 2025-10-03
// ============================================================================
//
// RAISON DE LA MISE EN COMMENTAIRE :
// ----------------------------------
// Ce fichier est totalement inutilisé dans la codebase. Analyse effectuée :
//
// 1. IMPORTS TROUVÉS (3 fichiers) :
//    - features/authentication/presentation/mobile/screens/registration_form.dart
//    - features/authentication/presentation/mobile/screens/verification_pending_screen.dart
//    - features/posts/presentation/mobile/screens/other/journalist_question.dart
//
// 2. USAGES RÉELS : Aucun
//    - Aucune utilisation de la classe Responsive() comme widget
//    - Aucune utilisation des méthodes statiques Responsive.isMobile/isTablet/isDesktop
//
// 3. DUPLICATION AVEC responsive_utils.dart :
//    - ResponsiveUtils offre les mêmes méthodes isMobile/isTablet/isDesktop
//    - ResponsiveUtils ajoute des utilitaires supplémentaires (padding, spacing, etc.)
//    - Tous les fichiers utilisent ResponsiveUtils, jamais Responsive
//
// RECOMMANDATION :
// ---------------
// Ce fichier peut être supprimé en toute sécurité après avoir retiré les
// imports inutilisés dans les 3 fichiers mentionnés ci-dessus.
// Utiliser exclusivement ResponsiveUtils pour la gestion du responsive.
//
// ============================================================================

// import 'package:flutter/material.dart';
//
// class Responsive extends StatelessWidget {
//   final Widget mobile;
//   final Widget? tablet;
//   final Widget? desktop;
//
//   const Responsive({
//     super.key,
//     required this.mobile,
//     this.tablet,
//     this.desktop,
//   });
//
//   static bool isMobile(BuildContext context) =>
//       MediaQuery.of(context).size.width < 768;
//
//   static bool isTablet(BuildContext context) =>
//       MediaQuery.of(context).size.width >= 768 &&
//       MediaQuery.of(context).size.width < 1024;
//
//   static bool isDesktop(BuildContext context) =>
//       MediaQuery.of(context).size.width >= 1024;
//
//   @override
//   Widget build(BuildContext context) {
//     if (isDesktop(context)) {
//       return desktop ?? tablet ?? mobile;
//     } else if (isTablet(context)) {
//       return tablet ?? mobile;
//     }
//     return mobile;
//   }
// }
