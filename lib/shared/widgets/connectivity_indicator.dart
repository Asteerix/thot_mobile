import 'package:thot/core/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:thot/core/connectivity/connectivity_service.dart';

/// Widget indicateur de connectivité affichant l'état de la connexion.
class ConnectivityIndicator extends StatelessWidget {
  final Widget? child;
  final bool showBanner;
  final bool showIcon;

  const ConnectivityIndicator({
    super.key,
    this.child,
    this.showBanner = true,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ConnectivityStatus>(
      stream: ConnectivityService.instance.statusStream,
      initialData: ConnectivityService.instance.status,
      builder: (context, snapshot) {
        final status = snapshot.data ?? ConnectivityStatus.unknown;

        if (child != null) {
          return Stack(
            children: [
              child!,
              if (showBanner && status != ConnectivityStatus.online)
                _buildBanner(context, status),
              if (showIcon)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  right: 16,
                  child: _buildIcon(status),
                ),
            ],
          );
        }

        return _buildIcon(status);
      },
    );
  }

  Widget _buildBanner(BuildContext context, ConnectivityStatus status) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    Color backgroundColor;
    Color textColor = colorScheme.onSurface;

    switch (status) {
      case ConnectivityStatus.offline:
        backgroundColor = colorScheme.error;
        break;
      case ConnectivityStatus.noBackend:
        backgroundColor = AppColors.warning;
        break;
      case ConnectivityStatus.unknown:
        backgroundColor = colorScheme.outline.withOpacity(0.7);
        break;
      case ConnectivityStatus.online:
        backgroundColor = AppColors.success;
        break;
    }

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Material(
        color: backgroundColor,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(
                  _getIconForStatus(status),
                  color: textColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    status.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (status == ConnectivityStatus.unknown)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(textColor),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(ConnectivityStatus status) {
    return Builder(builder: (context) {
      final colorScheme = Theme.of(context).colorScheme;
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _getColorForStatus(status, context),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: colorScheme.surface.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          _getIconForStatus(status),
          color: colorScheme.onSurface,
          size: 20,
        ),
      );
    });
  }

  IconData _getIconForStatus(ConnectivityStatus status) {
    switch (status) {
      case ConnectivityStatus.online:
        return Icons.wifi;
      case ConnectivityStatus.offline:
        return Icons.wifi_off;
      case ConnectivityStatus.noBackend:
        return Icons.cloud_off;
      case ConnectivityStatus.unknown:
        return Icons.help_outline;
    }
  }

  Color _getColorForStatus(ConnectivityStatus status, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (status) {
      case ConnectivityStatus.online:
        return AppColors.success;
      case ConnectivityStatus.offline:
        return colorScheme.error;
      case ConnectivityStatus.noBackend:
        return AppColors.warning;
      case ConnectivityStatus.unknown:
        return colorScheme.outline;
    }
  }
}

/// Bouton de retry pour les erreurs de connexion.
class ConnectivityRetryButton extends StatefulWidget {
  final VoidCallback onRetry;
  final String? label;

  const ConnectivityRetryButton({
    super.key,
    required this.onRetry,
    this.label,
  });

  @override
  State<ConnectivityRetryButton> createState() =>
      _ConnectivityRetryButtonState();
}

class _ConnectivityRetryButtonState extends State<ConnectivityRetryButton> {
  bool _isRetrying = false;

  Future<void> _handleRetry() async {
    setState(() {
      _isRetrying = true;
    });

    try {
      await ConnectivityService.instance.checkConnectivityAndThrow();
      widget.onRetry();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRetrying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _isRetrying ? null : _handleRetry,
      child: _isRetrying
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(widget.label ?? 'Réessayer'),
    );
  }
}

/// Widget pour afficher un écran d'erreur de connexion.
class ConnectivityErrorScreen extends StatelessWidget {
  final ConnectivityStatus status;
  final VoidCallback? onRetry;

  const ConnectivityErrorScreen({
    super.key,
    required this.status,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getIcon(),
                  size: 80,
                  color: _getColor(),
                ),
                const SizedBox(height: 24),
                Text(
                  status.label,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  status.description,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(height: 32),
                if (onRetry != null) ConnectivityRetryButton(onRetry: onRetry!),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIcon() {
    switch (status) {
      case ConnectivityStatus.offline:
        return Icons.wifi_off;
      case ConnectivityStatus.noBackend:
        return Icons.cloud_off;
      case ConnectivityStatus.unknown:
        return Icons.help_outline;
      case ConnectivityStatus.online:
        return Icons.check_circle;
    }
  }

  Color _getColor() {
    return switch (status) {
      ConnectivityStatus.offline => AppColors.error,
      ConnectivityStatus.noBackend => AppColors.warning,
      ConnectivityStatus.unknown => AppColors.grey,
      ConnectivityStatus.online => AppColors.success,
    };
  }
}
