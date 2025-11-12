import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:thot/core/services/connectivity/connectivity_service.dart';
import 'package:thot/core/services/connectivity/connectivity_service_base.dart';
class IOConnectivityService extends BaseConnectivityService {
  static final IOConnectivityService _instance =
      IOConnectivityService._internal();
  factory IOConnectivityService() => _instance;
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  List<ConnectivityResult>? _lastKnownResults;
  IOConnectivityService._internal();
  @override
  Future<void> initialize() async {
    final initialResult = await _connectivity.checkConnectivity();
    _lastKnownResults = initialResult;
    final isOffline = _isOfflineResult(initialResult);
    if (isOffline) {
      updateStatus(ConnectivityStatus.offline);
    }
    await super.initialize();
    _connectivitySubscription = _connectivity.onConnectivityChanged
        .skip(1)
        .listen(_handleConnectivityChange);
  }
  Future<void> _handleConnectivityChange(List<ConnectivityResult> results) async {
    if (_areResultsEqual(results, _lastKnownResults)) {
      return;
    }
    _lastKnownResults = results;
    if (_isOfflineResult(results)) {
      updateStatus(ConnectivityStatus.offline);
    } else {
      await checkBackendAvailability();
    }
  }
  bool _isOfflineResult(List<ConnectivityResult> results) {
    return results.isEmpty || results.contains(ConnectivityResult.none);
  }
  bool _areResultsEqual(
    List<ConnectivityResult>? a,
    List<ConnectivityResult>? b,
  ) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    final setA = a.toSet();
    final setB = b.toSet();
    return setA.difference(setB).isEmpty;
  }
  @override
  Future<bool> waitForConnection({Duration? timeout}) async {
    if (status == ConnectivityStatus.online) {
      return true;
    }
    final completer = Completer<bool>();
    StreamSubscription<ConnectivityStatus>? subscription;
    Timer? timeoutTimer;
    subscription = statusStream.listen((status) {
      if (status == ConnectivityStatus.online) {
        if (!completer.isCompleted) {
          completer.complete(true);
          timeoutTimer?.cancel();
          subscription?.cancel();
        }
      }
    });
    if (timeout != null) {
      timeoutTimer = Timer(timeout, () {
        if (!completer.isCompleted) {
          completer.complete(false);
          subscription?.cancel();
        }
      });
    }
    return completer.future;
  }

  @override
  Future<void> checkConnectivityAndThrow() async {
    if (status == ConnectivityStatus.offline) {
      throw const ConnectivityException(
        'Aucune connexion internet. Veuillez vérifier votre connexion.',
      );
    }
    if (!isBackendAvailable) {
      throw const ConnectivityException(
        'Le serveur est temporairement indisponible. Veuillez réessayer plus tard.',
      );
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    controller.close();
  }
}
ConnectivityService createConnectivityService() => IOConnectivityService();