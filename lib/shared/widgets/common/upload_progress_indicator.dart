// ============================================================================
// FICHIER INUTILISÉ - MARQUÉ POUR SUPPRESSION FUTURE
// ============================================================================
//
// RAISON: Ce fichier n'est utilisé nulle part dans la codebase.
//
// REMPLACEMENT: Utiliser `UploadProgressDialog` (upload_progress_dialog.dart)
// qui offre une solution plus complète avec:
//   - Gestion d'erreurs intégrée
//   - Mécanisme de retry
//   - Animations et feedback visuel améliorés
//   - API statique show() pour affichage simplifié
//   - Support des streams de progression
//
// HISTORIQUE:
//   - Créé initialement pour afficher la progression d'upload
//   - Remplacé par UploadProgressDialog qui centralise la logique
//   - Aucune référence trouvée dans la codebase (vérifié le 2025-10-03)
//
// TODO: Supprimer ce fichier et sa référence dans widgets.dart après
//       validation qu'aucun code externe ne l'utilise
//
// ============================================================================

import 'package:flutter/material.dart';

/// Widget inline d'affichage de progression d'upload
///
/// ⚠️ DEPRECATED - Utiliser [UploadProgressDialog] à la place
///
/// Cette classe n'est plus utilisée. Elle a été remplacée par
/// [UploadProgressDialog] qui offre une meilleure UX et gestion d'état.
@Deprecated('Utiliser UploadProgressDialog à la place')
class UploadProgressIndicator extends StatelessWidget {
  final double progress;
  final String? label;
  final VoidCallback? onCancel;
  final Color? progressColor;
  final Color? backgroundColor;

  const UploadProgressIndicator({
    super.key,
    required this.progress,
    this.label,
    this.onCancel,
    this.progressColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percentComplete = (progress * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label ?? 'Téléchargement en cours...',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$percentComplete%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              if (onCancel != null)
                IconButton(
                  onPressed: onCancel,
                  icon: const Icon(Icons.close),
                  iconSize: 20,
                ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: backgroundColor ??
                  theme.colorScheme.onSurface.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                progressColor ?? theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Overlay de progression d'upload superposé à un widget
///
/// ⚠️ DEPRECATED - Utiliser [UploadProgressDialog] à la place
///
/// Cette classe n'est plus utilisée. Elle a été remplacée par
/// [UploadProgressDialog] qui gère mieux les états et erreurs.
@Deprecated('Utiliser UploadProgressDialog à la place')
class UploadProgressOverlay extends StatelessWidget {
  final double progress;
  final String? label;
  final VoidCallback? onCancel;
  final Widget child;
  final bool showOverlay;

  const UploadProgressOverlay({
    super.key,
    required this.progress,
    required this.child,
    this.showOverlay = true,
    this.label,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (showOverlay)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: UploadProgressIndicator(
                    progress: progress,
                    label: label,
                    onCancel: onCancel,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
