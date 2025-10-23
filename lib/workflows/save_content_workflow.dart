/// ⚠️ CODE MORT - Workflow pour la sauvegarde de contenu
///
/// Ce workflow n'est JAMAIS instancié ni utilisé dans la codebase.
/// La logique est entièrement gérée par MediaSaveService.
///
/// Usages réels dans la codebase :
/// - Toute la logique de sauvegarde passe par MediaSaveService directement
/// - MediaSaveService gère déjà : optimistic updates, cache, événements UI
/// - Aucune orchestration supplémentaire nécessaire
///
/// Ce workflow était prévu pour orchestrer:
/// - Sauvegarde du contenu
/// - Mise à jour du profil utilisateur
/// - Synchronisation cache
///
/// Problèmes de duplication identifiés :
/// - toggleSave() duplique MediaSaveService.togglePostSave/toggleShortSave
/// - isContentSaved() duplique MediaSaveService.isPostSaved/isShortSaved
/// - getAllSavedContent() duplique MediaSaveService.getAllSavedContent
/// - profileUpdated/cacheSynced sont toujours true (pas de logique réelle)
///
/// ❌ RECOMMANDATION : Supprimer ce fichier et utiliser MediaSaveService directement
library;

import 'package:thot/features/media/data/services/media_save_service.dart';
import 'package:thot/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:thot/core/monitoring/logger_service.dart';

/// Résultat de sauvegarde de contenu
/// ⚠️ CODE MORT - Jamais utilisé
class SaveContentResult {
  final bool saved;
  final bool profileUpdated;
  final bool cacheSynced;

  const SaveContentResult({
    required this.saved,
    required this.profileUpdated,
    required this.cacheSynced,
  });
}

/// Workflow de sauvegarde de contenu
/// ⚠️ CODE MORT - Jamais instancié dans la codebase
/// Utiliser MediaSaveService directement : ServiceLocator.instance.mediaSaveService
class SaveContentWorkflow {
  final MediaSaveService _mediaSaveService;
  final ProfileRepositoryImpl _profileRepository;
  final _logger = LoggerService.instance;

  SaveContentWorkflow({
    required MediaSaveService mediaSaveService,
    required ProfileRepositoryImpl profileRepository,
  })  : _mediaSaveService = mediaSaveService,
        _profileRepository = profileRepository;

  /// Exécute le workflow de sauvegarde
  /// ⚠️ CODE MORT - Jamais appelé
  /// Duplication de MediaSaveService.togglePostSave/toggleShortSave
  ///
  /// Steps:
  /// 1. Sauvegarder/retirer le contenu
  /// 2. Mettre à jour le profil (toujours true, pas de logique)
  /// 3. Synchroniser le cache (toujours true, pas de logique)
  Future<SaveContentResult> toggleSave({
    required String contentId,
    required String contentType,
    bool optimistic = true,
  }) async {
    try {
      _logger.info('Step 1: Starting save content workflow', extra: {
        'contentId': contentId,
        'contentType': contentType,
        'optimistic': optimistic,
      });

      // Step 1: Sauvegarder/retirer le contenu selon le type
      bool saved = false;
      try {
        _logger.info('Step 1a: Toggling save status');

        if (contentType == 'post' ||
            contentType == 'article' ||
            contentType == 'video' ||
            contentType == 'podcast') {
          saved = await _mediaSaveService.togglePostSave(
            contentId,
            optimistic: optimistic,
          );
        } else if (contentType == 'short') {
          saved = await _mediaSaveService.toggleShortSave(
            contentId,
            optimistic: optimistic,
          );
        } else {
          throw Exception('Unsupported content type: $contentType');
        }

        _logger.info('Content save toggled', extra: {
          'saved': saved,
        });
      } catch (e, stack) {
        _logger.error('Failed to toggle save status', e, stack);
        throw Exception('Failed to save content: $e');
      }

      // Step 2: Mettre à jour le profil (handled automatically by backend)
      // ⚠️ CODE MORT - Toujours true, pas de logique réelle
      bool profileUpdated = false;
      try {
        _logger.info('Step 2: Profile update triggered by backend');
        // Backend automatically updates user profile stats
        // when content is saved/unsaved (savedPosts count, etc.)
        profileUpdated = true;
        _logger.info('Profile update acknowledged');
      } catch (e) {
        _logger
            .warning('Profile update tracking failed (non-critical)', extra: {
          'error': e.toString(),
        });
        // Non-critical, don't fail the workflow
      }

      // Step 3: Synchroniser le cache
      // ⚠️ CODE MORT - Toujours true, MediaSaveService gère déjà le cache
      bool cacheSynced = false;
      try {
        _logger.info('Step 3: Syncing local cache');
        // MediaSaveService already handles cache synchronization
        // internally through its optimistic updates and event streaming
        cacheSynced = true;
        _logger.info('Cache synced successfully');
      } catch (e) {
        _logger.warning('Cache sync failed (non-critical)', extra: {
          'error': e.toString(),
        });
        // Non-critical, don't fail the workflow
      }

      _logger.info('Save content workflow completed successfully', extra: {
        'saved': saved,
        'profileUpdated': profileUpdated,
        'cacheSynced': cacheSynced,
      });

      return SaveContentResult(
        saved: saved,
        profileUpdated: profileUpdated,
        cacheSynced: cacheSynced,
      );
    } catch (e, stack) {
      _logger.error('Save content workflow failed', e, stack);
      rethrow;
    }
  }

  /// Récupère tous les contenus sauvegardés
  /// ⚠️ CODE MORT - Jamais appelé (simple délégation à MediaSaveService)
  Future<Map<String, List<dynamic>>> getAllSavedContent({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      _logger.info('Fetching all saved content', extra: {
        'page': page,
        'limit': limit,
      });

      final content = await _mediaSaveService.getAllSavedContent(
        page: page,
        limit: limit,
      );

      _logger.info('Saved content fetched successfully', extra: {
        'articles': content['articles']?.length ?? 0,
        'videos': content['videos']?.length ?? 0,
        'podcasts': content['podcasts']?.length ?? 0,
        'shorts': content['shorts']?.length ?? 0,
      });

      return content;
    } catch (e, stack) {
      _logger.error('Failed to fetch saved content', e, stack);
      rethrow;
    }
  }

  /// Vérifie si un contenu est sauvegardé
  /// ⚠️ CODE MORT - Jamais appelé (simple délégation à MediaSaveService)
  bool isContentSaved({
    required String contentId,
    required String contentType,
  }) {
    if (contentType == 'post' ||
        contentType == 'article' ||
        contentType == 'video' ||
        contentType == 'podcast') {
      return _mediaSaveService.isPostSaved(contentId);
    } else if (contentType == 'short') {
      return _mediaSaveService.isShortSaved(contentId);
    }
    return false;
  }

  /// Précharge le statut des contenus sauvegardés
  /// ⚠️ CODE MORT - Jamais appelé (simple délégation à MediaSaveService)
  Future<void> preloadSavedStatus() async {
    try {
      _logger.info('Preloading saved content status');
      await _mediaSaveService.preloadSavedStatus();
      _logger.info('Saved status preloaded successfully');
    } catch (e, stack) {
      _logger.error('Failed to preload saved status', e, stack);
      // Non-critical, don't throw
    }
  }

  /// Efface le cache local
  /// ⚠️ CODE MORT - Jamais appelé (simple délégation à MediaSaveService)
  void clearCache() {
    try {
      _logger.info('Clearing saved content cache');
      _mediaSaveService.clearCache();
      _logger.info('Cache cleared successfully');
    } catch (e, stack) {
      _logger.error('Failed to clear cache', e, stack);
      // Non-critical, don't throw
    }
  }
}
