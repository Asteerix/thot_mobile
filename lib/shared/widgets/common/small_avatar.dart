import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:thot/core/constants/app_config.dart';
import 'package:thot/core/constants/app_constants.dart';

/// Widget avatar simple avec taille personnalisable et bordure.
///
/// ⚠️ DÉPRÉCIÉ - Utiliser [AppAvatar] à la place
///
/// Ce widget est un doublon de [AppAvatar] avec une API légèrement différente.
/// Il est conservé temporairement pour compatibilité avec [FeedItem] mais devrait
/// être remplacé par [AppAvatar] dans une future refactorisation.
///
/// Différences avec [AppAvatar]:
/// - Utilise [size] (diamètre) au lieu de [radius]
/// - Ajoute une bordure par défaut autour de l'avatar
/// - Logique de traitement d'URL dupliquée (devrait utiliser [UrlHelper])
/// - Logs de debug verbeux (non nécessaires en production)
///
/// Migration vers [AppAvatar]:
/// ```dart
/// // Avant:
/// SmallAvatar(
///   avatarUrl: url,
///   size: 32,
///   isJournalist: true,
/// )
///
/// // Après:
/// AppAvatar(
///   avatarUrl: url,
///   radius: 16, // size / 2
///   isJournalist: true,
/// )
/// ```
@Deprecated('Utiliser AppAvatar à la place - sera supprimé dans v2.0')
class SmallAvatar extends StatelessWidget {
  /// URL de l'avatar (réseau ou asset local)
  final String? avatarUrl;

  /// Diamètre de l'avatar (pas le rayon contrairement à [AppAvatar])
  final double size;

  /// Détermine l'avatar par défaut (journaliste vs utilisateur)
  final bool isJournalist;

  const SmallAvatar({
    super.key,
    this.avatarUrl,
    this.size = 28,
    this.isJournalist = false,
  });

  @override
  Widget build(BuildContext context) {
    final defaultAvatar = isJournalist
        ? UIConstants.defaultJournalistAvatarPath
        : UIConstants.defaultUserAvatarPath;

    final url = avatarUrl?.trim();

    // Cas 1: URL nulle ou vide → avatar par défaut
    if (url == null || url.isEmpty) {
      return _buildDefaultAvatar(defaultAvatar);
    }

    // Cas 2: Chemin d'asset local → AssetImage
    if (url.startsWith('assets/')) {
      return _buildDefaultAvatar(url);
    }

    // Cas 3: URL réseau → traitement et chargement
    final processedUrl = _processNetworkUrl(url);

    // Si l'URL pointe vers un avatar par défaut du backend → utiliser l'asset local
    if (processedUrl.contains('/assets/images/defaults/')) {
      return _buildDefaultAvatar(defaultAvatar);
    }

    // Chargement de l'image réseau avec cache
    return _buildNetworkAvatar(processedUrl, defaultAvatar);
  }

  /// Traite l'URL réseau pour remplacer localhost par l'URL de base de l'API
  String _processNetworkUrl(String url) {
    // Remplacer localhost par l'URL de base pour mobile
    if (url.contains('localhost:3000') || url.contains('127.0.0.1:3000')) {
      final baseUrl = AppConfig.apiBaseUrl.endsWith('/api')
          ? AppConfig.apiBaseUrl.substring(0, AppConfig.apiBaseUrl.length - 4)
          : AppConfig.apiBaseUrl;

      return url
          .replaceAll('http://localhost:3000', baseUrl)
          .replaceAll('http://127.0.0.1:3000', baseUrl);
    }

    return url;
  }

  /// Construit un avatar réseau avec [CachedNetworkImage]
  Widget _buildNetworkAvatar(String url, String fallbackAssetPath) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey[800]!, width: 1),
      ),
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          width: size,
          height: size,
          httpHeaders: const {
            'ngrok-skip-browser-warning': 'true',
          },
          placeholder: (context, url) => _buildLoadingAvatar(),
          errorWidget: (context, url, error) =>
              _buildDefaultAvatar(fallbackAssetPath),
        ),
      ),
    );
  }

  /// Construit un avatar par défaut à partir d'un asset local
  Widget _buildDefaultAvatar(String assetPath) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey[800],
        border: Border.all(color: Colors.grey[700]!, width: 1),
      ),
      child: ClipOval(
        child: Image.asset(
          assetPath,
          fit: BoxFit.cover,
          width: size,
          height: size,
          errorBuilder: (context, error, stackTrace) => _buildFallbackIcon(),
        ),
      ),
    );
  }

  /// Construit un avatar de chargement avec indicateur de progression
  Widget _buildLoadingAvatar() {
    return Container(
      color: Colors.grey[800],
      child: Center(
        child: SizedBox(
          width: size * 0.5,
          height: size * 0.5,
          child: CircularProgressIndicator(
            strokeWidth: 1,
            color: Colors.grey[600],
          ),
        ),
      ),
    );
  }

  /// Construit une icône de secours si le chargement de l'asset échoue
  Widget _buildFallbackIcon() {
    return Container(
      color: Colors.grey[800],
      child: Icon(
        isJournalist ? Icons.verified_user : Icons.person,
        size: size * 0.6,
        color: Colors.grey[600],
      ),
    );
  }
}
