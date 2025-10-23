// lib/core/widgets/safe_network_image.dart
//
// Objectifs:
// - UX plus fluide: shimmer squelettique, fade-in contrôlé, états d'erreur propres.
// - Accessibilité: libellés sémantiques corrects.
// - Performance: memCacheWidth/Height calculés selon le devicePixelRatio, FilterQuality.
// - Intégration UI: bordures, ombre, fond, rayon, et décorations optionnelles sans renommer les classes.
//
// Dépendances: cached_network_image (déjà présent). Aucun package supplémentaire requis.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:thot/core/constants/asset_paths.dart';

bool _hasUrl(String? url) {
  if (url == null) return false;
  final u = url.trim();
  if (u.isEmpty) return false;
  if (u.toLowerCase() == 'null') return false;
  if (u == 'undefined') return false;
  // Fichiers locaux sans chemin réel
  if (u.startsWith('file:///') && u.length <= 8) return false;
  // Schémas non supportés explicitement
  if (u.startsWith('data:')) return false;
  return true;
}

/// Image réseau sûre avec fallback local + skeleton + fade-in.
/// API compatible, classes inchangées.
class SafeNetworkImage extends StatelessWidget {
  const SafeNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.clipBehavior = Clip.hardEdge,
    this.placeholderAsset = AssetPaths.defaultPostImage,
    this.alignment = Alignment.center,
    this.semanticLabel,
    this.backgroundColor = Colors.transparent,
    this.border,
    this.boxShadow,
    this.fadeInDuration = const Duration(milliseconds: 280),
    this.fadeOutDuration = const Duration(milliseconds: 100),
    this.showProgressShimmer = true,
    this.filterQuality = FilterQuality.high,
    this.memCacheWidth,
    this.memCacheHeight,
    this.showErrorBadge = true,
    this.errorBadgeIcon = Icons.image_not_supported_outlined,
  });

  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Clip clipBehavior;
  final String placeholderAsset;
  final AlignmentGeometry alignment;
  final String? semanticLabel;

  // Améliorations UI/Perf
  final Color backgroundColor;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;
  final Duration fadeInDuration;
  final Duration fadeOutDuration;
  final bool showProgressShimmer;
  final FilterQuality filterQuality;
  final int? memCacheWidth; // en pixels (non dp)
  final int? memCacheHeight; // en pixels (non dp)
  final bool showErrorBadge;
  final IconData errorBadgeIcon;

  int? _effectiveCacheW(BuildContext context) {
    if (memCacheWidth != null) return memCacheWidth;
    if (width == null) return null;
    final dpr = MediaQuery.of(context).devicePixelRatio;
    return (width! * dpr).round();
    // NB: volontairement pas de min/max; laissez le backend adapter.
  }

  int? _effectiveCacheH(BuildContext context) {
    if (memCacheHeight != null) return memCacheHeight;
    if (height == null) return null;
    final dpr = MediaQuery.of(context).devicePixelRatio;
    return (height! * dpr).round();
  }

  @override
  Widget build(BuildContext context) {
    final skeleton = _SkeletonShimmer(
      width: width,
      height: height,
      borderRadius: borderRadius,
    );

    final placeholder = Stack(
      fit: StackFit.passthrough,
      children: [
        // Fond neutre pour éviter les artefacts d'alpha sur les coins arrondis
        if (backgroundColor != Colors.transparent)
          DecoratedBox(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: borderRadius,
            ),
          ),
        // Asset de secours
        Image.asset(
          placeholderAsset,
          width: width,
          height: height,
          fit: fit,
          alignment: alignment,
          filterQuality: filterQuality,
          semanticLabel: semanticLabel,
        ),
        if (showProgressShimmer) skeleton,
      ],
    );

    Widget imageChild;
    if (!_hasUrl(url)) {
      imageChild = placeholder;
    } else {
      imageChild = CachedNetworkImage(
        imageUrl: url!,
        width: width,
        height: height,
        fit: fit,
        alignment: alignment as Alignment,
        fadeInDuration: fadeInDuration,
        fadeOutDuration: fadeOutDuration,
        memCacheWidth: _effectiveCacheW(context),
        memCacheHeight: _effectiveCacheH(context),
        filterQuality: filterQuality,
        // Skeleton pendant le chargement
        placeholder: (_, __) => placeholder,
        // Fallback propre en cas d'erreur
        errorWidget: (_, __, ___) => _ErrorFallback(
          width: width,
          height: height,
          fit: fit,
          alignment: alignment,
          placeholderAsset: placeholderAsset,
          borderRadius: borderRadius,
          showBadge: showErrorBadge,
          badgeIcon: errorBadgeIcon,
          backgroundColor: backgroundColor,
          filterQuality: filterQuality,
        ),
      );
    }

    // Clip si rayon fourni
    if (borderRadius != null) {
      imageChild = ClipRRect(
        borderRadius: borderRadius!,
        clipBehavior: clipBehavior,
        child: imageChild,
      );
    }

    // Décoration externe (fond, bordure, ombre)
    Widget decorated = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
        border: border,
        boxShadow: boxShadow,
      ),
      clipBehavior: borderRadius != null ? clipBehavior : Clip.none,
      child: imageChild,
    );

    // Accessibilité
    return Semantics(
      image: true,
      label: semanticLabel,
      child: decorated,
    );
  }
}

/// Variante "décorée" destinée à remplacer un Container avec DecorationImage.
/// Ajouts: skeleton, gradient overlay facultatif, fade-in, perf/UX accrues.
class DecoratedSafeNetworkImage extends StatelessWidget {
  const DecoratedSafeNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholderAsset = AssetPaths.defaultPostImage,
    this.alignment = Alignment.center,
    this.backgroundColor = Colors.transparent,
    this.child,
    this.border,
    this.boxShadow,
    this.fadeInDuration = const Duration(milliseconds: 280),
    this.fadeOutDuration = const Duration(milliseconds: 100),
    this.showProgressShimmer = true,
    this.filterQuality = FilterQuality.high,
    this.memCacheWidth,
    this.memCacheHeight,
    this.overlayGradient,
    this.overlayBlendMode = BlendMode.srcOver,
    this.semanticLabel,
  });

  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final String placeholderAsset;
  final AlignmentGeometry alignment;
  final Color backgroundColor;
  final Widget? child;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;
  final Duration fadeInDuration;
  final Duration fadeOutDuration;
  final bool showProgressShimmer;
  final FilterQuality filterQuality;
  final int? memCacheWidth; // en pixels
  final int? memCacheHeight; // en pixels
  final Gradient? overlayGradient;
  final BlendMode overlayBlendMode;
  final String? semanticLabel;

  int? _effectiveCacheW(BuildContext context) {
    if (memCacheWidth != null) return memCacheWidth;
    if (width == null) return null;
    final dpr = MediaQuery.of(context).devicePixelRatio;
    return (width! * dpr).round();
  }

  int? _effectiveCacheH(BuildContext context) {
    if (memCacheHeight != null) return memCacheHeight;
    if (height == null) return null;
    final dpr = MediaQuery.of(context).devicePixelRatio;
    return (height! * dpr).round();
  }

  @override
  Widget build(BuildContext context) {
    final skeleton = _SkeletonShimmer(
      width: width,
      height: height,
      borderRadius: borderRadius,
    );

    if (!_hasUrl(url)) {
      return _buildContainerWithAsset(
          skeleton: showProgressShimmer ? skeleton : null);
    }

    return CachedNetworkImage(
      imageUrl: url!,
      memCacheWidth: _effectiveCacheW(context),
      memCacheHeight: _effectiveCacheH(context),
      fadeInDuration: fadeInDuration,
      fadeOutDuration: fadeOutDuration,
      filterQuality: filterQuality,
      imageBuilder: (_, provider) => _buildContainerWithProvider(provider),
      placeholder: (_, __) => _buildContainerWithAsset(
          skeleton: showProgressShimmer ? skeleton : null),
      errorWidget: (_, __, ___) =>
          _buildContainerWithAsset(showErrorBadge: true),
    );
  }

  Widget _buildContainerWithProvider(ImageProvider provider) {
    final imageDecoration = DecorationImage(
      image: provider,
      fit: fit,
      alignment: alignment,
      filterQuality: filterQuality,
    );

    final content = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
        border: border,
        boxShadow: boxShadow,
        image: imageDecoration,
      ),
      clipBehavior: borderRadius != null ? Clip.hardEdge : Clip.none,
      child: child,
    );

    if (overlayGradient == null) {
      return Semantics(image: true, label: semanticLabel, child: content);
    }

    // Overlay gradient optionnel
    return Semantics(
      image: true,
      label: semanticLabel,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          content,
          IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: borderRadius,
                gradient: overlayGradient,
                // Le blend se fait au-dessus de l'image
                backgroundBlendMode: overlayBlendMode,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContainerWithAsset(
      {Widget? skeleton, bool showErrorBadge = false}) {
    final base = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
        border: border,
        boxShadow: boxShadow,
        image: DecorationImage(
          image: AssetImage(placeholderAsset),
          fit: fit,
          alignment: alignment,
          filterQuality: filterQuality,
        ),
      ),
      clipBehavior: borderRadius != null ? Clip.hardEdge : Clip.none,
      child: child,
    );

    if (skeleton == null && !showErrorBadge) return base;

    return Stack(
      fit: StackFit.passthrough,
      children: [
        base,
        if (skeleton != null) skeleton,
        if (showErrorBadge)
          Positioned(
            right: 8,
            top: 8,
            child: _Badge(icon: Icons.image_not_supported_outlined),
          ),
      ],
    );
  }
}

/// Skeleton shimmer sans dépendances externes.
class _SkeletonShimmer extends StatefulWidget {
  const _SkeletonShimmer({
    required this.width,
    required this.height,
    required this.borderRadius,
  });

  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  @override
  State<_SkeletonShimmer> createState() => _SkeletonShimmerState();
}

class _SkeletonShimmerState extends State<_SkeletonShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200))
    ..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base =
        Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.35);
    final highlight =
        Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.70);

    return ClipRRect(
      borderRadius: widget.borderRadius ?? BorderRadius.zero,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (_, __) {
            final t = _controller.value; // 0..1
            // Bande lumineuse qui parcourt horizontalement
            final alignment = Alignment(-1.0 + 2.0 * t, 0);
            return Stack(
              children: [
                Container(
                  width: widget.width,
                  height: widget.height,
                  color: base,
                ),
                Positioned.fill(
                  child: FractionallySizedBox(
                    widthFactor: 0.35,
                    alignment: alignment,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [base, highlight, base],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Fallback d'erreur avec asset + badge discret.
class _ErrorFallback extends StatelessWidget {
  const _ErrorFallback({
    required this.width,
    required this.height,
    required this.fit,
    required this.alignment,
    required this.placeholderAsset,
    required this.borderRadius,
    required this.showBadge,
    required this.badgeIcon,
    required this.backgroundColor,
    required this.filterQuality,
  });

  final double? width;
  final double? height;
  final BoxFit fit;
  final AlignmentGeometry alignment;
  final String placeholderAsset;
  final BorderRadius? borderRadius;
  final bool showBadge;
  final IconData badgeIcon;
  final Color backgroundColor;
  final FilterQuality filterQuality;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      children: [
        if (backgroundColor != Colors.transparent)
          DecoratedBox(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: borderRadius,
            ),
          ),
        Image.asset(
          placeholderAsset,
          width: width,
          height: height,
          fit: fit,
          alignment: alignment,
          filterQuality: filterQuality,
        ),
        if (showBadge)
          Positioned(
            right: 8,
            top: 8,
            child: _Badge(icon: badgeIcon),
          ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).colorScheme.surface.withOpacity(0.85);
    final fg = Theme.of(context).colorScheme.onSurface.withOpacity(0.70);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
              blurRadius: 6,
              spreadRadius: 0,
              offset: Offset(0, 2),
              color: Color(0x33000000)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 16, color: fg),
      ),
    );
  }
}
