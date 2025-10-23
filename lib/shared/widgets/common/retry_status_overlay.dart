// ============================================================================
// FICHIER INUTILISÉ - Code mort
// ============================================================================
//
// Raisons de la désactivation :
// 1. Widget jamais instancié dans la codebase (0 usage)
// 2. Event RetryAttemptEvent jamais déclenché (EventBus.fire non trouvé)
// 3. Propriétés event incompatibles :
//    - Widget attend : event.attempt, event.error
//    - Event définit : event.attemptNumber (pas de .error)
// 4. Import retry_interceptor déjà commenté (ligne 6)
// 5. Fonctionnalité redondante avec ConnectionStatusIndicator
//
// Action recommandée : Supprimer ce fichier et retirer l'export de widgets.dart
// ============================================================================

import 'package:thot/core/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:thot/core/realtime/event_bus.dart';

/// Widget d'overlay affichant le statut des tentatives de retry réseau.
///
/// ⚠️ WIDGET MORT - Jamais utilisé dans l'application
///
/// Affiche une notification en haut de l'écran lors de tentatives de reconnexion.
/// Écoute les événements [RetryAttemptEvent] via [EventBus] pour afficher
/// une animation de slide avec indicateur de progression.
class RetryStatusOverlay extends StatefulWidget {
  /// Widget enfant wrappé par l'overlay
  final Widget child;

  const RetryStatusOverlay({
    super.key,
    required this.child,
  });

  @override
  State<RetryStatusOverlay> createState() => _RetryStatusOverlayState();
}

class _RetryStatusOverlayState extends State<RetryStatusOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  StreamSubscription<RetryAttemptEvent>? _retrySubscription;
  RetryAttemptEvent? _currentRetry;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: -1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    // ⚠️ CODE MORT : RetryAttemptEvent jamais émis dans la codebase
    _retrySubscription = EventBus().on<RetryAttemptEvent>().listen((event) {
      setState(() => _currentRetry = event);
      _animationController.forward();

      _hideTimer?.cancel();
      _hideTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          _animationController.reverse().then((_) {
            if (mounted) {
              setState(() => _currentRetry = null);
            }
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _retrySubscription?.cancel();
    _animationController.dispose();
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_currentRetry != null)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: SlideTransition(
              position: _slideAnimation.drive(
                Tween(
                  begin: const Offset(0, -1),
                  end: Offset.zero,
                ),
              ),
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange[900],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orange[700]!,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.orange[300]!,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ⚠️ BUG : event.attempt n'existe pas
                            // RetryAttemptEvent définit attemptNumber, pas attempt
                            Text(
                              'Nouvelle tentative (${_currentRetry!.attemptNumber}/${_currentRetry!.maxAttempts})',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            // ⚠️ BUG : event.error n'existe pas
                            // RetryAttemptEvent ne définit pas de propriété error
                            const Text(
                              'Connexion instable',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: Colors.orange[300],
                          size: 20,
                        ),
                        onPressed: () {
                          _animationController.reverse().then((_) {
                            setState(() => _currentRetry = null);
                          });
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
