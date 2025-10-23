enum ConnectivityStatus {
  unknown,
  offline,
  online,
  noBackend,
}
extension ConnectivityStatusExtension on ConnectivityStatus {
  String get label {
    switch (this) {
      case ConnectivityStatus.unknown:
        return 'Vérification...';
      case ConnectivityStatus.offline:
        return 'Hors ligne';
      case ConnectivityStatus.online:
        return 'En ligne';
      case ConnectivityStatus.noBackend:
        return 'Serveur indisponible';
    }
  }
  String get description {
    switch (this) {
      case ConnectivityStatus.unknown:
        return 'Vérification de la connexion...';
      case ConnectivityStatus.offline:
        return 'Aucune connexion internet';
      case ConnectivityStatus.online:
        return 'Connecté';
      case ConnectivityStatus.noBackend:
        return 'Serveur temporairement indisponible';
    }
  }
}
class ConnectivityException implements Exception {
  final String message;
  const ConnectivityException(this.message);
  @override
  String toString() => message;
}
abstract class ConnectivityService {
  static ConnectivityService? _instance;
  static ConnectivityService get instance {
    if (_instance == null) {
      throw StateError(
        'ConnectivityService not initialized. Call ServiceLocator.initialize() first',
      );
    }
    return _instance!;
  }
  static void setInstance(ConnectivityService service) {
    _instance = service;
  }
  Stream<ConnectivityStatus> get statusStream;
  ConnectivityStatus get status;
  bool get isBackendAvailable;
  bool get hasInternetConnection;
  Future<void> initialize();
  Future<bool> waitForConnection({Duration? timeout});
  Future<void> checkConnectivityAndThrow();
  void dispose();
}
mixin ConnectivityAware {
  ConnectivityService get _connectivityService => ConnectivityService.instance;
  Future<T> withConnectivity<T>(Future<T> Function() operation) async {
    await _connectivityService.checkConnectivityAndThrow();
    try {
      return await operation();
    } on ConnectivityException {
      rethrow;
    } catch (e) {
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('socketexception')) {
        throw ConnectivityException(
          errorString.contains('timeout')
              ? 'La connexion est trop lente. Veuillez réessayer.'
              : 'Problème de connexion. Vérifiez votre connexion internet.',
        );
      }
      if (errorString.contains('connection refused')) {
        throw ConnectivityException(
          'Impossible de se connecter au serveur. Réessayez plus tard.',
        );
      }
      if (errorString.contains('dio') && errorString.contains('timeout')) {
        throw ConnectivityException(
          'La connexion est trop lente. Veuillez réessayer.',
        );
      }
      rethrow;
    }
  }
}
ConnectivityService createConnectivityService() {
  throw UnsupportedError(
    'Aucune implémentation de ConnectivityService disponible pour cette plateforme',
  );
}