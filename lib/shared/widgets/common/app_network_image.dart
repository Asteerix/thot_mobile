// ⚠️ FICHIER OBSOLÈTE - NE PAS UTILISER ⚠️
//
// Ce fichier n'est plus utilisé dans la codebase et a été remplacé par des alternatives plus robustes.
//
// ÉTAT: Non utilisé (0 références dans mobile/lib/)
//
// RAISONS DE L'OBSOLESCENCE:
// 1. AppNetworkImage → Remplacé par:
//    - SafeNetworkImage (safe_network_image.dart): Gestion avancée avec shimmer skeleton,
//      fade-in, optimisation mémoire (memCacheWidth/Height), FilterQuality, accessibilité
//    - CachedNetworkImageWidget (cached_network_image_widget.dart): Support borderRadius,
//      assets par défaut, états d'erreur enrichis
//
// 2. AppCircleAvatar → Remplacé par:
//    - AppAvatar (app_avatar.dart): Gestion intelligente des avatars avec détection
//      automatique user/journalist, fallback assets locaux, logs de debug détaillés
//
// AVANTAGES DES ALTERNATIVES:
// - Performance optimisée (cache mémoire basé sur devicePixelRatio)
// - UX améliorée (shimmer skeleton, transitions fluides)
// - Accessibilité (labels sémantiques)
// - Gestion d'erreurs plus robuste
// - Architecture cohérente avec le reste de l'app
//
// ACTION RECOMMANDÉE:
// - Supprimer ce fichier après validation que l'export dans widgets.dart n'est pas utilisé
// - Retirer l'export correspondant de shared/widgets/widgets.dart:5
//
// Date d'analyse: 2025-10-03

import 'package:thot/core/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:thot/features/media/utils/url_helper.dart';

// ❌ OBSOLÈTE: Utiliser SafeNetworkImage ou CachedNetworkImageWidget à la place
class AppNetworkImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Map<String, String>? httpHeaders;

  const AppNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.httpHeaders,
  });

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    if (url == null || url.isEmpty) {
      return _buildErrorWidget();
    }

    // Convert relative URL to absolute URL
    final fullUrl = UrlHelper.buildMediaUrl(url);

    if (fullUrl == null || fullUrl.isEmpty) {
      return _buildErrorWidget();
    }

    return CachedNetworkImage(
      imageUrl: fullUrl,
      width: width,
      height: height,
      fit: fit,
      httpHeaders: httpHeaders ??
          {
            'ngrok-skip-browser-warning': 'true',
          },
      placeholder: (context, url) => placeholder ?? _buildPlaceholder(),
      errorWidget: (context, url, error) => errorWidget ?? _buildErrorWidget(),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: const Icon(
        Icons.error_outline,
        color: Colors.grey,
      ),
    );
  }
}

// ❌ OBSOLÈTE: Utiliser AppAvatar à la place
class AppCircleAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final Widget? placeholder;
  final Widget? errorWidget;

  const AppCircleAvatar({
    super.key,
    required this.imageUrl,
    this.radius = 20,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    if (url == null || url.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey[300],
        child: Icon(
          Icons.person,
          size: radius,
          color: Colors.grey[600],
        ),
      );
    }

    final fullUrl = UrlHelper.buildMediaUrl(imageUrl!);

    return CachedNetworkImage(
      imageUrl: fullUrl,
      httpHeaders: {
        'ngrok-skip-browser-warning': 'true',
      },
      imageBuilder: (context, imageProvider) => CircleAvatar(
        radius: radius,
        backgroundImage: imageProvider,
      ),
      placeholder: (context, url) => CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey[300],
        child: const CircularProgressIndicator(
          strokeWidth: 2,
        ),
      ),
      errorWidget: (context, url, error) => CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey[300],
        child: Icon(
          Icons.person,
          size: radius,
          color: Colors.grey[600],
        ),
      ),
    );
  }
}
