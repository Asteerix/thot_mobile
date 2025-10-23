// ============================================================================
// FICHIER INUTILISÉ - Conservé pour référence historique
// ============================================================================
//
// ANALYSE D'USAGE (Octobre 2025):
// ❌ Aucune importation de ce fichier dans le codebase mobile/lib/
// ❌ Aucune instanciation de SmartLoadingIndicator() dans le projet
// ❌ Aucune instanciation de ShimmerLoadingList() dans le projet
// ✓ Exporté dans widgets.dart mais jamais utilisé
//
// RAISON DE NON-USAGE:
// Le projet utilise LoadingIndicator (loading_indicator.dart) qui est plus
// simple et suffisant pour tous les besoins actuels. SmartLoadingIndicator
// offre des fonctionnalités avancées (détection connexion lente, mode offline)
// qui n'ont jamais été nécessaires dans l'application.
//
// ALTERNATIVE ACTIVE:
// → Utiliser LoadingIndicator (loading_indicator.dart)
//   Activement utilisé dans: profile_screen, following_screen, feed_screen_web,
//   shorts_feed_screen_web, user_search.dart
//
// RECOMMANDATION:
// Ce fichier peut être supprimé en toute sécurité si nécessaire.
// Conservé temporairement au cas où les fonctionnalités avancées
// (détection connexion lente, shimmer loading) seraient utiles à l'avenir.
//
// ============================================================================

import 'package:thot/core/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:thot/core/connectivity/connectivity_service.dart';

/// Widget d'indicateur de chargement avancé avec détection de connexion lente.
///
/// ⚠️ WIDGET INUTILISÉ - Considérer LoadingIndicator à la place.
///
/// Fonctionnalités:
/// - Animation personnalisée de rotation avec dégradé
/// - Détection automatique de connexion lente après [slowConnectionThreshold]
/// - Affichage du statut hors ligne avec icône
/// - Bouton d'annulation optionnel
/// - Message personnalisable
///
/// Alternative recommandée: LoadingIndicator (plus simple, actuellement utilisé)
class SmartLoadingIndicator extends StatefulWidget {
  /// Message affiché sous l'indicateur
  final String? message;

  /// Active l'affichage du warning de connexion lente
  final bool showSlowConnectionWarning;

  /// Délai avant d'afficher le warning de connexion lente
  final Duration slowConnectionThreshold;

  /// Callback appelé quand l'utilisateur clique sur "Annuler"
  final VoidCallback? onCancel;

  const SmartLoadingIndicator({
    super.key,
    this.message,
    this.showSlowConnectionWarning = true,
    this.slowConnectionThreshold = const Duration(seconds: 5),
    this.onCancel,
  });

  @override
  State<SmartLoadingIndicator> createState() => _SmartLoadingIndicatorState();
}

class _SmartLoadingIndicatorState extends State<SmartLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;
  Timer? _slowConnectionTimer;
  bool _showSlowWarning = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * 3.14159,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.linear,
    ));

    if (widget.showSlowConnectionWarning) {
      _slowConnectionTimer = Timer(widget.slowConnectionThreshold, () {
        if (mounted) {
          setState(() => _showSlowWarning = true);
        }
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _slowConnectionTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOffline =
        ConnectivityService.instance.status == ConnectivityStatus.offline;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animation de chargement personnalisée avec dégradé circulaire
          Stack(
            alignment: Alignment.center,
            children: [
              // Cercle de fond
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.grey[800]!,
                    width: 3,
                  ),
                ),
              ),
              // Dégradé rotatif
              AnimatedBuilder(
                animation: _rotationAnimation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotationAnimation.value,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SweepGradient(
                          colors: [
                            Colors.blue.withOpacity(0),
                            Colors.blue,
                            Colors.blue.withOpacity(0),
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  );
                },
              ),
              // Icône mode hors ligne
              if (isOffline)
                Icon(
                  Icons.cloud_off,
                  color: Colors.orange[400],
                  size: 24,
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Message de chargement
          Text(
            widget.message ?? 'Chargement...',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),

          // Warning connexion lente (apparaît après le délai défini)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _showSlowWarning ? null : 0,
            child: _showSlowWarning
                ? Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.signal_wifi_statusbar_connected_no_internet_4,
                            color: Colors.orange[400],
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Connexion lente',
                            style: TextStyle(
                              color: Colors.orange[400],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // Warning mode hors ligne
          if (isOffline) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.red.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.wifi_off,
                    color: AppColors.error,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Mode hors ligne',
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Bouton d'annulation (visible si connexion lente ou hors ligne)
          if (widget.onCancel != null && (_showSlowWarning || isOffline)) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: widget.onCancel,
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[400],
              ),
              child: const Text('Annuler'),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================================

/// Widget de liste avec effet shimmer pour les placeholders de contenu.
///
/// ⚠️ WIDGET INUTILISÉ - Jamais instancié dans le codebase.
///
/// Affiche une liste de placeholders animés avec effet shimmer pour
/// indiquer le chargement de contenu. Personnalisable via:
/// - [itemCount]: Nombre d'items à afficher
/// - [itemHeight]: Hauteur de chaque item
/// - [padding]: Padding autour de la liste
///
/// Note: Le projet n'utilise actuellement pas d'effet shimmer pour
/// les états de chargement, préférant le simple LoadingIndicator.
class ShimmerLoadingList extends StatefulWidget {
  /// Nombre d'items placeholder à afficher
  final int itemCount;

  /// Hauteur de chaque item en pixels
  final double itemHeight;

  /// Padding autour de la liste
  final EdgeInsets padding;

  const ShimmerLoadingList({
    super.key,
    this.itemCount = 3,
    this.itemHeight = 120,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  State<ShimmerLoadingList> createState() => _ShimmerLoadingListState();
}

class _ShimmerLoadingListState extends State<ShimmerLoadingList>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.linear,
    ));
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: widget.padding,
      itemCount: widget.itemCount,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: AnimatedBuilder(
            animation: _shimmerAnimation,
            builder: (context, child) {
              return Container(
                height: widget.itemHeight,
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      // Placeholder de contenu de base
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Titre placeholder
                            Container(
                              width: 120,
                              height: 16,
                              decoration: BoxDecoration(
                                color: Colors.grey[800],
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Ligne de texte 1
                            Container(
                              width: double.infinity,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.grey[850],
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Ligne de texte 2
                            Container(
                              width: 200,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.grey[850],
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Effet shimmer animé
                      Positioned.fill(
                        child: ShaderMask(
                          shaderCallback: (rect) {
                            return LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Colors.transparent,
                                Colors.white.withOpacity(0.1),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.5, 1.0],
                              transform:
                                  GradientRotation(_shimmerAnimation.value),
                            ).createShader(rect);
                          },
                          blendMode: BlendMode.srcOver,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withOpacity(0.05),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
