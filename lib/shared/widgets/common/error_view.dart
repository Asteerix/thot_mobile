import 'package:flutter/material.dart';
import 'package:thot/core/themes/app_colors.dart';
import 'package:thot/core/utils/error_message_helper.dart';
import 'package:thot/core/connectivity/connectivity_service.dart';

/// Widget d'affichage d'erreur avec possibilité de réessayer
///
/// Affiche un message d'erreur convivial avec :
/// - Message traduit via ErrorMessageHelper
/// - Icône et couleur adaptées au type d'erreur
/// - Bouton de réessai avec état de chargement
/// - Conseils pour problèmes de connexion
/// - Support hors ligne avec suggestion de contenu sauvegardé
class ErrorView extends StatefulWidget {
  /// Message d'erreur brut (sera traduit automatiquement)
  final String error;

  /// Callback déclenché lors du clic sur "Réessayer"
  final VoidCallback onRetry;

  const ErrorView({
    super.key,
    required this.error,
    required this.onRetry,
  });

  @override
  State<ErrorView> createState() => _ErrorViewState();
}

class _ErrorViewState extends State<ErrorView> {
  bool _isRetrying = false;

  Future<void> _handleRetry() async {
    setState(() => _isRetrying = true);
    await Future.delayed(const Duration(milliseconds: 300));
    widget.onRetry();
    if (mounted) {
      setState(() => _isRetrying = false);
    }
  }

  /// Détermine l'icône appropriée selon le type d'erreur
  IconData _getErrorIcon(String error) {
    final errorStr = error.toLowerCase();
    if (errorStr.contains('connexion') || errorStr.contains('network')) {
      return Icons.wifi_off;
    } else if (errorStr.contains('serveur')) {
      return Icons.cloud_off;
    } else if (errorStr.contains('timeout')) {
      return Icons.schedule;
    } else if (errorStr.contains('permission') || errorStr.contains('refusé')) {
      return Icons.lock;
    } else if (errorStr.contains('introuvable')) {
      return Icons.search_off;
    }
    return Icons.error_outline;
  }

  /// Détermine la couleur selon la sévérité de l'erreur
  Color _getErrorColor(String error) {
    final errorStr = error.toLowerCase();
    if (errorStr.contains('connexion') ||
        errorStr.contains('network') ||
        errorStr.contains('permission') ||
        errorStr.contains('refusé')) {
      return AppColors.warning;
    }
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final errorMessage =
        ErrorMessageHelper.getUserFriendlyMessage(widget.error);
    final errorColor = _getErrorColor(errorMessage);
    final isOffline =
        ConnectivityService.instance.status == ConnectivityStatus.offline;

    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: errorColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: errorColor.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: errorColor.withOpacity(0.1),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icône principale
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: errorColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getErrorIcon(errorMessage),
                color: errorColor,
                size: 48,
              ),
            ),

            const SizedBox(height: 16),

            // Titre
            Text(
              isOffline ? 'Hors ligne' : 'Oups!',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // Message d'erreur
            Text(
              errorMessage,
              style: TextStyle(
                color: colorScheme.outline.withOpacity(0.3),
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            // Conseils pour problèmes de connexion
            if (isOffline || errorMessage.contains('connexion'))
              _buildConnectionTips(colorScheme),

            const SizedBox(height: 24),

            // Bouton réessayer
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isRetrying ? null : _handleRetry,
                icon: _isRetrying
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              colorScheme.onError),
                        ),
                      )
                    : Icon(Icons.refresh),
                label: const Text('Réessayer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: errorColor,
                  foregroundColor: colorScheme.onError,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget des conseils de connexion (extrait pour clarté)
  Widget _buildConnectionTips(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lightbulb_outline,
                    color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Conseils',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '• Vérifiez votre connexion Wi-Fi ou données mobiles\n'
              '• Rapprochez-vous de votre routeur\n'
              '• Désactivez le mode avion',
              style: TextStyle(
                color: colorScheme.outline.withOpacity(0.6),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
