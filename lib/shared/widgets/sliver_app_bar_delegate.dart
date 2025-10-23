// ============================================================================
// FICHIER INUTILISÉ - CODE MORT
// ============================================================================
//
// Raison: Ce delegate n'est jamais utilisé dans la codebase.
//
// Analyse des usages:
// - Exporté dans shared/widgets/widgets.dart (ligne 29)
// - AUCUNE importation dans le reste du code
//
// Les écrans profile_screen.dart et user_profile_screen.dart définissent
// leurs propres classes privées _SliverAppBarDelegate au lieu d'utiliser
// cette implémentation partagée.
//
// Alternative disponible:
// - FiltersHeaderDelegate (shared/widgets/common/filters_header_delegate.dart)
//   Delegate générique réutilisable pour tout type de header persistant
//
// Actions recommandées:
// 1. Supprimer ce fichier
// 2. Retirer l'export de widgets.dart (ligne 29)
// 3. Utiliser FiltersHeaderDelegate pour les besoins génériques
// 4. Garder les implémentations privées _SliverAppBarDelegate dans les
//    écrans qui nécessitent une logique spécifique
//
// ============================================================================

import 'dart:ui' show ImageFilter, lerpDouble;
import 'package:flutter/material.dart';

/// Delegate pour afficher une TabBar dans un SliverPersistentHeader avec
/// effets visuels (blur, elevation) lors du scroll.
///
/// ⚠️ ATTENTION: Cette classe n'est actuellement utilisée nulle part dans
/// la codebase. Les écrans qui pourraient l'utiliser ont implémenté leurs
/// propres versions privées.
class SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final double minHeight;
  final double maxHeight;
  final Color? background;

  SliverAppBarDelegate(
    this.tabBar, {
    this.minHeight = 56,
    this.maxHeight = 72,
    this.background,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    final t = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final scheme = Theme.of(context).colorScheme;
    final surface = (background ?? scheme.surface).withOpacity(0.90);
    final indicatorThickness = lerpDouble(4, 2, t)!;
    final elevation = lerpDouble(0, 2, t)!;

    return Material(
      color: Colors.transparent,
      elevation: elevation,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10 * t, sigmaY: 10 * t),
          child: Container(
            color: surface,
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  DefaultTextStyle(
                    style: Theme.of(context).textTheme.titleMedium!,
                    child: TabBar(
                      isScrollable: true,
                      tabs: tabBar.tabs,
                      controller: tabBar.controller,
                      indicatorSize: TabBarIndicatorSize.label,
                      indicator: UnderlineTabIndicator(
                        borderSide: BorderSide(
                          width: indicatorThickness,
                          color: scheme.primary,
                        ),
                        insets: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      labelColor: scheme.onSurface,
                      unselectedLabelColor: scheme.onSurfaceVariant,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 16),
                      dividerColor: Colors.transparent,
                    ),
                  ),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: scheme.outlineVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant SliverAppBarDelegate old) {
    return tabBar != old.tabBar ||
        minHeight != old.minHeight ||
        maxHeight != old.maxHeight ||
        background != old.background;
  }
}
