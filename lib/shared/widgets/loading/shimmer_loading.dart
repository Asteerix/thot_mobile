import 'package:flutter/material.dart';

/// Widget affichant un effet shimmer animé pour les placeholders de chargement.
///
/// Utilisé principalement comme placeholder pour les images réseau en cours de chargement.
/// Usage actuel: ProfileAvatar (placeholder CachedNetworkImage).
///
/// Exemple:
/// ```dart
/// ShimmerLoading(
///   width: 100,
///   height: 100,
///   borderRadius: 50, // Pour un cercle
/// )
/// ```
class ShimmerLoading extends StatefulWidget {
  /// Largeur du shimmer
  final double width;

  /// Hauteur du shimmer
  final double height;

  /// Rayon de bordure (0 = carré, width/2 = cercle)
  final double borderRadius;

  const ShimmerLoading({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 0,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutSine,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          gradient: LinearGradient(
            begin: Alignment(_animation.value, 0),
            end: const Alignment(2, 0),
            colors: [
              Colors.grey[800]!,
              Colors.grey[600]!,
              Colors.grey[800]!,
            ],
          ),
        ),
      ),
    );
  }
}
