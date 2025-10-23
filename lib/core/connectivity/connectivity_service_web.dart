import 'dart:async';
import 'dart:js_interop';
import 'package:web/web.dart' as web;
import 'package:thot/core/connectivity/connectivity_service.dart';
import 'package:thot/core/connectivity/connectivity_service_base.dart';
class WebConnectivityService extends BaseConnectivityService {
  static final WebConnectivityService _instance =
      WebConnectivityService._internal();
  factory WebConnectivityService() => _instance;
  WebConnectivityService._internal() {
    _attachEventListeners();
  }
  bool _isChecking = false;
  DateTime? _lastCheckAt;
  static const Duration _minCheckSpacing = Duration(seconds: 2);
  late final web.EventListener _onOnlineListener;
  late final web.EventListener _onOfflineListener;
  late final web.EventListener _onFocusListener;
  late final web.EventListener _onPageShowListener;
  late final web.EventListener _onVisibilityChangeListener;
  web.EventListener? _onConnectionChangeListener;
  @override
  Future<void> initialize() async {
    super.logger.info('[Connectivity] Initializing WebConnectivityService');
    if (web.window.navigator.onLine) {
      await _triggerCheck(reason: 'initialize');
    } else {
      updateStatus(ConnectivityStatus.offline);
    }
    startBackendHealthPolling(immediate: false);
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
    _detachListeners();
    controller.close();
  }
  Future<void> _triggerCheck({required String reason}) async {
    if (!web.window.navigator.onLine) return;
    if (_isChecking) return;
    final now = DateTime.now();
    if (_lastCheckAt != null &&
        now.difference(_lastCheckAt!) < _minCheckSpacing) {
      return;
    }
    _isChecking = true;
    _lastCheckAt = now;
    try {
      super.logger.info('[Connectivity] Check triggered: $reason');
      await checkBackendAvailability();
    } catch (e) {
      super.logger.error('[Connectivity] Check failed: $e');
    } finally {
      _isChecking = false;
    }
  }
  void _attachEventListeners() {
    _onOnlineListener = ((web.Event _) {
      _triggerCheck(reason: 'online');
    }).toJS;
    _onOfflineListener = ((web.Event _) {
      updateStatus(ConnectivityStatus.offline);
    }).toJS;
    _onFocusListener = ((web.Event _) {
      _triggerCheck(reason: 'focus');
    }).toJS;
    _onPageShowListener = ((web.Event _) {
      _triggerCheck(reason: 'pageshow');
    }).toJS;
    _onVisibilityChangeListener = ((web.Event _) {
      if (_isDocumentVisible) {
        _triggerCheck(reason: 'visibilitychange');
      }
    }).toJS;
    final w = web.window;
    final d = web.document;
    w.addEventListener('online', _onOnlineListener);
    w.addEventListener('offline', _onOfflineListener);
    w.addEventListener('focus', _onFocusListener);
    w.addEventListener('pageshow', _onPageShowListener);
    d.addEventListener('visibilitychange', _onVisibilityChangeListener);
    _attachConnectionChangeIfAvailable();
  }
  void _detachListeners() {
    final w = web.window;
    final d = web.document;
    w.removeEventListener('online', _onOnlineListener);
    w.removeEventListener('offline', _onOfflineListener);
    w.removeEventListener('focus', _onFocusListener);
    w.removeEventListener('pageshow', _onPageShowListener);
    d.removeEventListener('visibilitychange', _onVisibilityChangeListener);
    if (_onConnectionChangeListener != null) {
      try {
        final dynamic nav = w.navigator as dynamic;
        final dynamic connection = nav.connection;
        if (connection != null) {
          (connection as dynamic)
              .removeEventListener('change', _onConnectionChangeListener);
        }
      } catch (_) {
      }
    }
  }
  void _attachConnectionChangeIfAvailable() {
    try {
      final dynamic nav = web.window.navigator as dynamic;
      final dynamic connection = nav.connection;
      if (connection != null) {
        _onConnectionChangeListener =
            ((web.Event _) => _triggerCheck(reason: 'connection-change')).toJS;
        (connection as dynamic)
            .addEventListener('change', _onConnectionChangeListener);
      }
    } catch (_) {
    }
  }
  bool get _isDocumentVisible {
    try {
      final dynamic doc = web.document as dynamic;
      return doc.visibilityState == 'visible';
    } catch (_) {
      return true;
    }
  }
}
ConnectivityService createConnectivityService() => WebConnectivityService();