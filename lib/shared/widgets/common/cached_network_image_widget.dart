// lib/shared/widgets/common/cached_network_image_widget.dart
//
// Widget simple de mise en cache d'images réseau avec fallback local.
//
// ÉTAT: Utilisé activement (2 références dans mobile/lib/)
// - notifications_screen.dart: Avatars utilisateurs et thumbnails de posts
// - question_card_with_voting.dart: Images de questions
//
// ARCHITECTURE:
// - Widget léger sans dépendances lourdes
// - Gestion basique du cache via CachedNetworkImage
// - Fallback vers assets locaux en cas d'erreur
// - Support BorderRadius via ClipRRect
//
// ALTERNATIVE AVANCÉE:
// Pour des besoins plus sophistiqués (shimmer, optimisation mémoire avancée,
// accessibilité renforcée), voir SafeNetworkImage (safe_network_image.dart)

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:thot/features/media/utils/url_helper.dart';

/// Widget de mise en cache d'images réseau avec gestion d'erreurs.
///
/// Fonctionnalités:
/// - Cache automatique des images réseau
/// - Fallback vers asset local si URL invalide/erreur
/// - Support borderRadius optionnel
/// - Transitions fade-in/fade-out fluides
/// - États de chargement et d'erreur personnalisables
class CachedNetworkImageWidget extends StatelessWidget {
  const CachedNetworkImageWidget({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.showDefaultOnError = true,
    this.defaultAssetPath = 'assets/images/default_cover.png',
  });

  /// URL de l'image à charger (peut être relative ou absolue)
  final String? imageUrl;

  /// Mode d'ajustement de l'image dans son conteneur
  final BoxFit fit;

  /// Largeur du widget (null = non contrainte)
  final double? width;

  /// Hauteur du widget (null = non contrainte)
  final double? height;

  /// Widget affiché pendant le chargement (null = placeholder par défaut)
  final Widget? placeholder;

  /// Widget affiché en cas d'erreur (null = errorWidget par défaut)
  final Widget? errorWidget;

  /// Rayon des coins arrondis (null = coins carrés)
  final BorderRadius? borderRadius;

  /// Si true, affiche l'asset par défaut en cas d'erreur
  /// Si false, affiche errorWidget
  final bool showDefaultOnError;

  /// Chemin de l'asset utilisé comme fallback
  final String defaultAssetPath;

  // Durées des transitions fade (constantes pour éviter la duplication)
  static const Duration _fadeInDuration = Duration(milliseconds: 300);
  static const Duration _fadeOutDuration = Duration(milliseconds: 300);

  @override
  Widget build(BuildContext context) {
    // Validation et normalisation de l'URL
    final processedUrl = _validateAndProcessUrl(imageUrl);

    // Si URL invalide, afficher directement l'image par défaut
    if (processedUrl == null) {
      return _buildDefaultImage();
    }

    // Construction de l'image mise en cache
    final imageWidget = CachedNetworkImage(
      imageUrl: processedUrl,
      fit: fit,
      width: width,
      height: height,
      placeholder: (_, __) => placeholder ?? _buildPlaceholder(context),
      errorWidget: (_, __, ___) => _buildErrorFallback(),
      fadeInDuration: _fadeInDuration,
      fadeOutDuration: _fadeOutDuration,
    );

    // Appliquer le borderRadius si spécifié
    return _applyBorderRadius(imageWidget);
  }

  /// Valide et traite l'URL d'entrée.
  /// Retourne null si l'URL est invalide.
  String? _validateAndProcessUrl(String? url) {
    if (url == null || url.isEmpty) return null;

    final processedUrl = UrlHelper.buildMediaUrl(url);

    // Vérifier que l'URL est valide (commence par http:// ou https://)
    if (processedUrl == null ||
        processedUrl.isEmpty ||
        (!processedUrl.startsWith('http://') &&
            !processedUrl.startsWith('https://'))) {
      return null;
    }

    return processedUrl;
  }

  /// Construit le widget de chargement (placeholder).
  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: Theme.of(context).colorScheme.surface.withOpacity(0.1),
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
        ),
      ),
    );
  }

  /// Construit le widget d'erreur par défaut.
  Widget _buildErrorWidget(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: width,
      height: height,
      color: colorScheme.surface.withOpacity(0.1),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image_rounded,
            color: colorScheme.onSurface.withOpacity(0.3),
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            'Image non disponible',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.5),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Construit l'image par défaut (asset local).
  Widget _buildDefaultImage() {
    final imageWidget = Image.asset(
      defaultAssetPath,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (context, _, __) => _buildErrorWidget(context),
    );

    return _applyBorderRadius(imageWidget);
  }

  /// Construit le fallback en cas d'erreur de chargement.
  Widget _buildErrorFallback() {
    return showDefaultOnError
        ? _buildDefaultImage()
        : Builder(
            builder: (context) => errorWidget ?? _buildErrorWidget(context),
          );
  }

  /// Applique le borderRadius au widget si spécifié.
  Widget _applyBorderRadius(Widget child) {
    if (borderRadius == null) return child;

    return ClipRRect(
      borderRadius: borderRadius!,
      child: child,
    );
  }
}
