// ============================================================================
// FICHIER INUTILISÉ - CODE COMMENTÉ
// ============================================================================
// Date: 2025-10-03
// Raison: Ce widget n'est jamais utilisé dans la codebase mobile/lib/
// Analyse: Recherche exhaustive effectuée - aucun import ni usage détecté
// Action recommandée: Supprimer ce fichier et son export de widgets.dart
// ============================================================================

import 'package:flutter/material.dart';

/// Widget d'animation de compteur avec formatage automatique (K, M).
///
/// **STATUT: INUTILISÉ - Code commenté car aucun usage détecté dans la codebase.**
///
/// Fonctionnalités:
/// - Animation fluide lors du changement de valeur
/// - Formatage automatique (1000 → 1.0K, 1000000 → 1.0M)
/// - Personnalisation du style et durée d'animation
///
/// Exemple d'utilisation (si réactivé):
/// ```dart
/// AnimatedCount(
///   count: followerCount,
///   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
///   duration: Duration(milliseconds: 300),
/// )
/// ```
// class AnimatedCount extends StatefulWidget {
//   final int count;
//   final TextStyle? style;
//   final Duration duration;
//
//   const AnimatedCount({
//     super.key,
//     required this.count,
//     this.style,
//     this.duration = const Duration(milliseconds: 500),
//   });
//
//   @override
//   State<AnimatedCount> createState() => _AnimatedCountState();
// }
//
// class _AnimatedCountState extends State<AnimatedCount>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<double> _animation;
//   late int _oldCount;
//   late int _newCount;
//
//   @override
//   void initState() {
//     super.initState();
//     _oldCount = widget.count;
//     _newCount = widget.count;
//     _controller = AnimationController(
//       vsync: this,
//       duration: widget.duration,
//     );
//     _animation = Tween<double>(begin: 0, end: 1).animate(
//       CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
//     );
//   }
//
//   @override
//   void didUpdateWidget(AnimatedCount oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     if (oldWidget.count != widget.count) {
//       _oldCount = oldWidget.count;
//       _newCount = widget.count;
//       _controller.forward(from: 0);
//     }
//   }
//
//   String _formatNumber(int number) {
//     if (number >= 1000000) {
//       return '${(number / 1000000).toStringAsFixed(1)}M';
//     } else if (number >= 1000) {
//       return '${(number / 1000).toStringAsFixed(1)}K';
//     }
//     return number.toString();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return AnimatedBuilder(
//       animation: _animation,
//       builder: (context, child) {
//         final value = _oldCount + (_newCount - _oldCount) * _animation.value;
//         return Text(
//           _formatNumber(value.round()),
//           style: widget.style,
//         );
//       },
//     );
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
// }
