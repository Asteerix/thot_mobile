import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:thot/core/connectivity/connectivity_service.dart';
import 'package:thot/core/themes/app_colors.dart';

/// Widget d'indicateur de statut de connexion avec animations et gestion automatique.
///
/// Affiche une bannière animée en haut de l'écran pour indiquer l'état de la connexion :
/// - Rouge : Pas de connexion internet (offline)
/// - Orange : Serveur inaccessible (noBackend)
/// - Vert : Connexion restaurée (succès temporaire)
///
/// Fonctionnalités :
/// - Animations de fade in/out et pulse pour attirer l'attention
/// - Masquage automatique après 3 secondes quand la connexion est restaurée
/// - Bouton "Réessayer" pour forcer une vérification de connectivité
/// - Bouton de fermeture avec réinitialisation après 30 secondes
/// - Mode bannière persistante avec options avancées (mode hors ligne)
///
/// Différence avec ConnectivityIndicator (widgets/connectivity_indicator.dart) :
/// - ConnectionStatusIndicator : Widget stateful avec animations complexes, auto-hide,
///   gestion d'état utilisateur (dismiss), idéal pour affichage global persistant
/// - ConnectivityIndicator : Widget stateless simple basé sur StreamBuilder,
///   plus léger et modulaire, idéal pour icônes de statut ou écrans d'erreur
///
/// Usage typique :
/// ```dart
/// // Dans un Scaffold ou en overlay global
/// ConnectionStatusIndicator(
///   showPersistentBanner: false,  // true pour bannière enrichie
///   showRetryButton: true,
/// )
/// ```
class ConnectionStatusIndicator extends StatefulWidget {
  /// Si true, affiche une bannière enrichie avec plus d'options
  final bool showPersistentBanner;

  /// Si true, affiche le bouton "Réessayer"
  final bool showRetryButton;

  const ConnectionStatusIndicator({
    super.key,
    this.showPersistentBanner = false,
    this.showRetryButton = true,
  });

  @override
  State<ConnectionStatusIndicator> createState() =>
      _ConnectionStatusIndicatorState();
}

class _ConnectionStatusIndicatorState extends State<ConnectionStatusIndicator>
    with TickerProviderStateMixin {
  late final AnimationController _animationController;
  late final AnimationController _pulseController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _pulseAnimation;

  ConnectivityStatus _currentStatus = ConnectivityStatus.unknown;
  ConnectivityStatus? _previousStatus;
  Timer? _autoHideTimer;
  bool _userDismissed = false;

  // Constantes pour la configuration
  static const Duration _animationDuration = Duration(milliseconds: 300);
  static const Duration _pulseDuration = Duration(seconds: 2);
  static const Duration _autoHideDuration = Duration(seconds: 3);
  static const Duration _dismissResetDuration = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _listenToConnectivity();
    _setInitialStatus();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: _animationDuration,
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: _pulseDuration,
      vsync: this,
    )..repeat();

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
  }

  void _listenToConnectivity() {
    ConnectivityService.instance.statusStream.listen((status) {
      if (!mounted || _userDismissed) return;

      setState(() {
        _previousStatus = _currentStatus;
        _currentStatus = status;
      });

      _handleStatusChange(status);
    });
  }

  void _handleStatusChange(ConnectivityStatus status) {
    final isOfflineOrNoBackend = status == ConnectivityStatus.offline ||
        status == ConnectivityStatus.noBackend;
    final wasOfflineOrNoBackend =
        _previousStatus == ConnectivityStatus.offline ||
            _previousStatus == ConnectivityStatus.noBackend;

    if (isOfflineOrNoBackend) {
      // Afficher immédiatement en cas de problème
      _animationController.forward();
      _autoHideTimer?.cancel();
    } else if (wasOfflineOrNoBackend) {
      // Afficher brièvement le message de succès
      _animationController.forward();
      _scheduleAutoHide();
    } else {
      _animationController.reverse();
    }
  }

  void _setInitialStatus() {
    _currentStatus = ConnectivityService.instance.status;
    if (_currentStatus == ConnectivityStatus.offline ||
        _currentStatus == ConnectivityStatus.noBackend) {
      _animationController.forward();
    }
  }

  void _scheduleAutoHide() {
    _autoHideTimer?.cancel();
    _autoHideTimer = Timer(_autoHideDuration, () {
      if (mounted && !_userDismissed) {
        _animationController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    _autoHideTimer?.cancel();
    super.dispose();
  }

  void _handleDismiss() {
    setState(() => _userDismissed = true);
    _animationController.reverse();
    // Reset after 30 seconds
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        setState(() => _userDismissed = false);
      }
    });
  }

  void _handleRetry() {
    // Force a connectivity check
    ConnectivityService.instance.initialize();
  }

  @override
  Widget build(BuildContext context) {
    final isReconnected = _currentStatus == ConnectivityStatus.online &&
        (_previousStatus == ConnectivityStatus.offline ||
            _previousStatus == ConnectivityStatus.noBackend);

    Color backgroundColor;
    IconData icon;
    String message;
    String? subMessage;

    if (isReconnected) {
      backgroundColor = Colors.green[900]!;
      icon = Icons.check_circle;
      message = 'Connexion restaurée';
    } else if (_currentStatus == ConnectivityStatus.offline) {
      backgroundColor = Colors.red[900]!;
      icon = Icons.wifi_off;
      message = 'Pas de connexion internet';
      subMessage = 'Vérifiez votre Wi-Fi ou données mobiles';
    } else if (_currentStatus == ConnectivityStatus.noBackend) {
      backgroundColor = Colors.orange[900]!;
      icon = Icons.cloud_off;
      message = 'Serveur inaccessible';
      subMessage = 'Veuillez patienter ou réessayer';
    } else {
      return const SizedBox.shrink();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: widget.showPersistentBanner
          ? _buildPersistentBanner(backgroundColor, icon, message, subMessage)
          : _buildCompactIndicator(backgroundColor, icon, message, subMessage),
    );
  }

  Widget _buildCompactIndicator(
    Color backgroundColor,
    IconData icon,
    String message,
    String? subMessage,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _currentStatus != ConnectivityStatus.online
                    ? _pulseAnimation.value
                    : 1.0,
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 16,
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (widget.showRetryButton &&
              _currentStatus != ConnectivityStatus.online)
            TextButton(
              onPressed: _handleRetry,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 0),
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Réessayer',
                style: TextStyle(fontSize: 12),
              ),
            ),
          if (!widget.showPersistentBanner)
            IconButton(
              icon: const Icon(Icons.close, size: 16),
              color: Colors.white70,
              onPressed: _handleDismiss,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  Widget _buildPersistentBanner(
    Color backgroundColor,
    IconData icon,
    String message,
    String? subMessage,
  ) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _currentStatus != ConnectivityStatus.online
                        ? _pulseAnimation.value
                        : 1.0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (subMessage != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subMessage,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                color: Colors.white70,
                onPressed: _handleDismiss,
              ),
            ],
          ),
          if (_currentStatus != ConnectivityStatus.online) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (widget.showRetryButton)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _handleRetry,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Réessayer'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/saved'),
                    icon: const Icon(Icons.offline_pin, size: 16),
                    label: const Text('Mode hors ligne'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
