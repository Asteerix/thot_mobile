import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:thot/core/constants/app_config.dart';
import 'package:thot/features/media/utils/url_helper.dart';

/// Widget avatar intelligent gérant les images réseau et les avatars par défaut locaux.
///
/// Gère automatiquement :
/// - Les URLs nulles ou vides → avatar par défaut
/// - Les chemins d'assets locaux → AssetImage
/// - Les URLs réseau → CachedNetworkImage avec fallback
/// - Les URLs de défaut du backend → avatar par défaut local
class AppAvatar extends StatelessWidget {
  /// URL de l'avatar (peut être null, un chemin d'asset, ou une URL réseau)
  final String? avatarUrl;

  /// Rayon du CircleAvatar
  final double radius;

  /// Détermine quel avatar par défaut utiliser (journaliste vs utilisateur)
  final bool isJournalist;

  /// Couleur de fond du CircleAvatar (par défaut: Colors.grey[800])
  final Color? backgroundColor;

  // PARAMÈTRES INUTILISÉS - Gardés pour rétrocompatibilité
  // TODO: Supprimer dans une prochaine version si toujours inutilisés
  // Ces paramètres ne sont jamais utilisés dans la codebase actuelle
  @Deprecated('Non utilisé dans la codebase - sera supprimé')
  final Widget? placeholder;

  @Deprecated('Non utilisé dans la codebase - sera supprimé')
  final Widget? errorWidget;

  const AppAvatar({
    super.key,
    required this.avatarUrl,
    this.radius = 20,
    this.isJournalist = false,
    this.backgroundColor,
    @Deprecated('Non utilisé') this.placeholder,
    @Deprecated('Non utilisé') this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    final defaultAvatarPath = isJournalist
        ? AppConfig.defaultJournalistAvatarPath
        : AppConfig.defaultUserAvatarPath;

    final url = avatarUrl?.trim();

    // Cas 1: URL nulle ou vide → avatar par défaut
    if (url == null || url.isEmpty) {
      return _buildDefaultAvatar(defaultAvatarPath);
    }

    // Cas 2: Chemin d'asset local → AssetImage
    if (url.startsWith('assets/')) {
      return _buildDefaultAvatar(url);
    }

    // Cas 3: URL réseau → traitement et chargement
    final processedUrl = UrlHelper.buildMediaUrl(url);

    // Si le traitement échoue → avatar par défaut
    if (processedUrl == null || processedUrl.isEmpty) {
      return _buildDefaultAvatar(defaultAvatarPath);
    }

    // Si l'URL pointe vers les avatars par défaut du backend → utiliser l'asset local
    if (_isBackendDefaultAvatar(processedUrl)) {
      return _buildDefaultAvatar(defaultAvatarPath);
    }

    // Chargement de l'image réseau avec cache
    return _buildNetworkAvatar(processedUrl, defaultAvatarPath);
  }

  /// Vérifie si l'URL pointe vers un avatar par défaut du backend
  bool _isBackendDefaultAvatar(String url) {
    return url.contains('/assets/images/defaults/default_user_avatar.png') ||
        url.contains('/assets/images/defaults/default_journalist_avatar.png');
  }

  /// Construit un avatar réseau avec CachedNetworkImage
  Widget _buildNetworkAvatar(String url, String fallbackAssetPath) {
    return CachedNetworkImage(
      key: ValueKey(url),
      imageUrl: url,
      httpHeaders: const {
        'ngrok-skip-browser-warning': 'true',
      },
      cacheKey: url,
      imageBuilder: (context, imageProvider) => CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor ?? Colors.grey[800],
        backgroundImage: imageProvider,
      ),
      placeholder: (context, url) => _buildLoadingAvatar(),
      errorWidget: (context, url, error) =>
          _buildDefaultAvatar(fallbackAssetPath),
    );
  }

  /// Construit un avatar par défaut à partir d'un asset local
  Widget _buildDefaultAvatar(String assetPath) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? Colors.grey[800],
      backgroundImage: AssetImage(assetPath),
      onBackgroundImageError: (exception, stackTrace) {
        // Gestion silencieuse des erreurs de chargement d'assets
      },
    );
  }

  /// Construit un avatar de chargement avec indicateur de progression
  Widget _buildLoadingAvatar() {
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? Colors.grey[800],
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: Colors.grey[400],
      ),
    );
  }
}
