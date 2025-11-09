import 'package:flutter/material.dart';
import 'package:thot/core/monitoring/logger_service.dart';
import 'package:thot/core/themes/app_colors.dart';
import 'package:thot/core/utils/error_message_helper.dart';
import 'package:thot/core/utils/safe_navigation.dart';

/// Dialog modal affichant la progression d'un téléchargement (upload).
///
/// Utilisé dans les écrans de création de posts (articles, podcasts, vidéos, shorts)
/// pour afficher visuellement l'état d'avancement du téléchargement de fichiers.
///
/// Fonctionnalités :
/// - Indicateur de progression circulaire animé
/// - Pourcentage de progression
/// - Gestion d'erreurs avec retry
/// - Détection de connexion lente
/// - Annulation optionnelle
class UploadProgressDialog extends StatelessWidget {
  static final _logger = LoggerService.instance;

  final double progress;
  final String message;
  final VoidCallback? onCancel;
  final String? error;
  final VoidCallback? onRetry;

  const UploadProgressDialog({
    super.key,
    required this.progress,
    this.message = 'Téléchargement en cours...',
    this.onCancel,
    this.error,
    this.onRetry,
  });

  /// Affiche un dialog modal de progression d'upload.
  ///
  /// Cette méthode statique gère tout le cycle de vie du dialog :
  /// - Affiche le dialog avec un StreamBuilder écoutant [progressStream]
  /// - Attend la fin de [uploadFuture]
  /// - Ferme le dialog automatiquement
  /// - Affiche un dialog d'erreur en cas d'échec
  /// - Retourne le résultat de l'upload
  ///
  /// Paramètres :
  /// - [context] : BuildContext pour afficher le dialog
  /// - [progressStream] : Stream émettant la progression (0.0 à 1.0)
  /// - [uploadFuture] : Future de l'upload à attendre
  /// - [message] : Message affiché pendant l'upload
  /// - [barrierDismissible] : Si true, permet de fermer le dialog en cliquant hors de celui-ci
  ///
  /// Retourne le résultat de [uploadFuture] ou null en cas d'erreur.
  static Future<T?> show<T>({
    required BuildContext context,
    required Stream<double> progressStream,
    required Future<T> uploadFuture,
    String message = 'Téléchargement en cours...',
    bool barrierDismissible = false,
  }) async {
    _logger.info('UploadProgressDialog show() called with message: $message');

    bool dialogClosed = false;

    SafeNavigation.showDialog<T?>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (dialogContext) => StreamBuilder<double>(
        stream: progressStream,
        initialData: 0.0,
        builder: (context, snapshot) {
          return UploadProgressDialog(
            progress: snapshot.data ?? 0.0,
            message: message,
            onCancel: barrierDismissible
                ? () {
                    if (!dialogClosed) {
                      dialogClosed = true;
                      SafeNavigation.pop(dialogContext);
                    }
                  }
                : null,
          );
        },
      ),
    );

    try {
      _logger.debug('Waiting for upload future to complete...');
      final result = await uploadFuture;
      _logger.info('Upload future completed with result: $result');

      if (context.mounted && !dialogClosed) {
        _logger.debug('Closing dialog and returning result');
        dialogClosed = true;
        SafeNavigation.pop(context, result);
      } else {
        _logger.warning('Context not mounted or dialog already closed');
      }

      return result;
    } catch (error) {
      _logger.error('Error in upload: $error');

      if (context.mounted && !dialogClosed) {
        _logger.debug('Closing dialog due to error');
        dialogClosed = true;
        SafeNavigation.pop(context);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            final errorMessage =
                ErrorMessageHelper.getUserFriendlyMessage(error);
            _logger.info('Showing error dialog: $errorMessage');
            _showErrorDialog(context, errorMessage);
          }
        });
      } else {
        _logger.warning('Context not mounted, cannot show error dialog');
      }

      rethrow;
    }
  }

  /// Affiche un AlertDialog d'erreur.
  ///
  /// Note: Le bouton "Réessayer" ferme simplement le dialog.
  /// La logique de retry doit être gérée par l'appelant en réessayant l'upload.
  static void _showErrorDialog(BuildContext context, String error) {
    SafeNavigation.showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: Colors.white.withOpacity(0.3),
            width: 2,
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Icon(Icons.error_outline, color: Colors.red.shade300, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Erreur de téléchargement',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          error,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => SafeNavigation.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withOpacity(0.3)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => SafeNavigation.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isComplete = progress >= 1.0;
    final isSlowConnection = progress > 0 && progress < 0.1;
    final percentComplete = (progress * 100).toInt();

    return Dialog(
      backgroundColor: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildProgressIndicator(isComplete),
            const SizedBox(height: 24),
            _buildMessage(isComplete),
            const SizedBox(height: 8),
            _buildPercentage(percentComplete),
            if (error != null) _buildErrorBanner(),
            if (!isComplete && error == null && isSlowConnection)
              _buildSlowConnectionWarning(),
            if (_shouldShowActionButtons(isComplete))
              _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  /// Construit l'indicateur circulaire de progression avec icône.
  Widget _buildProgressIndicator(bool isComplete) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      tween: Tween(begin: 0.0, end: progress),
      builder: (context, value, child) {
        final color = isComplete ? Colors.green : Colors.white;
        final icon = isComplete ? Icons.check_circle : Icons.cloud_upload;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  value: value,
                  strokeWidth: 6,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              Icon(icon, size: 40, color: color),
            ],
          ),
        );
      },
    );
  }

  /// Construit le message principal.
  Widget _buildMessage(bool isComplete) {
    return Text(
      isComplete ? 'Téléchargement terminé!' : message,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      textAlign: TextAlign.center,
    );
  }

  /// Construit le pourcentage de progression.
  Widget _buildPercentage(int percentComplete) {
    return Text(
      '$percentComplete%',
      style: TextStyle(
        color: Colors.white.withOpacity(0.6),
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  /// Construit la bannière d'erreur.
  Widget _buildErrorBanner() {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 24, color: Colors.red.shade300),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                error!,
                style: TextStyle(
                  color: Colors.red.shade300,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construit l'avertissement de connexion lente.
  Widget _buildSlowConnectionWarning() {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off,
              size: 20,
              color: Colors.orange.shade300,
            ),
            const SizedBox(width: 12),
            Text(
              'Connexion lente détectée',
              style: TextStyle(
                color: Colors.orange.shade300,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Détermine si les boutons d'action doivent être affichés.
  bool _shouldShowActionButtons(bool isComplete) {
    return (onCancel != null || (onRetry != null && error != null)) &&
        !isComplete;
  }

  /// Construit les boutons d'action (Annuler/Réessayer).
  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (onCancel != null)
            OutlinedButton(
              onPressed: onCancel,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withOpacity(0.3)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Annuler'),
            ),
          if (onRetry != null && error != null) ...[
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Réessayer'),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// NOTE: Les paramètres 'error' et 'onRetry' du constructeur ne sont jamais
// utilisés par la méthode statique show() (elle passe toujours error: null).
// Ces paramètres sont conservés pour permettre une utilisation standalone
// du widget si nécessaire dans le futur.
// ============================================================================
