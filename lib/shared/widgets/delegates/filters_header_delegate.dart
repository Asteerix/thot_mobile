import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Delegate pour le header des filtres
/// Réutilisable pour tous les écrans qui utilisent des filtres
class FiltersHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  FiltersHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox(
      height: math.max(minHeight, maxHeight - shrinkOffset),
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant FiltersHeaderDelegate oldDelegate) {
    return oldDelegate.minHeight != minHeight ||
        oldDelegate.maxHeight != maxHeight ||
        oldDelegate.child != child;
  }
}
