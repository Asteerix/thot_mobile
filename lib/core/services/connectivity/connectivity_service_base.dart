library;
import 'dart:async';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';
import 'package:thot/core/services/network/api_config.dart';
import 'package:thot/core/services/logging/logger_service.dart';
import 'package:thot/core/services/connectivity/connectivity_service.dart';
@immutable
class BackendHealthConfig {
  final String healthPath;
  final Duration timeout;
  final Set<int> okStatusCodes;
  @Deprecated('Non utilisé dans le code actuel')
  final String? jsonHealthyKey;
  @Deprecated('Non utilisé dans le code actuel')
  final Map<String, String>? jsonStatusValueEquals;
  const BackendHealthConfig({
    this.healthPath = '/health',
    this.timeout = const Duration(seconds: 5),
    this.okStatusCodes = const {200},
    @Deprecated('Non utilisé') this.jsonHealthyKey,
    @Deprecated('Non utilisé') this.jsonStatusValueEquals,
  });
  static const BackendHealthConfig defaults = BackendHealthConfig();
}
@immutable
class ConnectivityPollingConfig {
  final Duration interval;
  final Duration maxJitter;
  @Deprecated('Non utilisé - le backoff n\'est pas implémenté')
  final Duration backoffInterval;
  const ConnectivityPollingConfig({
    this.interval = const Duration(minutes: 5),
    this.maxJitter = const Duration(seconds: 10),
    @Deprecated('Non utilisé') this.backoffInterval = const Duration(minutes: 10),
  });
  static const ConnectivityPollingConfig standard = ConnectivityPollingConfig();
}
abstract class BaseConnectivityService implements ConnectivityService {
  @protected
  final logger = LoggerService.instance;
  final http.Client _httpClient = http.Client();
  late final StreamController<ConnectivityStatus> _controller;
  ConnectivityStatus _status = ConnectivityStatus.unknown;
  Timer? _backendCheckTimer;
  bool _isBackendAvailable = false;
  bool _checkInProgress = false;
  final math.Random _rng = math.Random();
  BackendHealthConfig _healthConfig = BackendHealthConfig.defaults;
  ConnectivityPollingConfig _pollingConfig = ConnectivityPollingConfig.standard;
  BaseConnectivityService({
    BackendHealthConfig healthConfig = BackendHealthConfig.defaults,
    ConnectivityPollingConfig pollingConfig =
        ConnectivityPollingConfig.standard,
  }) {
    _healthConfig = healthConfig;
    _pollingConfig = pollingConfig;
    _controller = StreamController<ConnectivityStatus>.broadcast(
      onListen: () {
        if (!_controller.isClosed) {
          _controller.add(_status);
        }
      },
    );
  }
  @override
  Stream<ConnectivityStatus> get statusStream => _controller.stream;
  @override
  ConnectivityStatus get status => _status;
  @override
  bool get isBackendAvailable => _isBackendAvailable;
  @override
  bool get hasInternetConnection => _status == ConnectivityStatus.online;
  @override
  Future<void> initialize() async {
    logger.info('[Connectivity] Initializing BaseConnectivityService');
    if (_status != ConnectivityStatus.offline) {
      await checkBackendAvailability();
    }
    startBackendHealthPolling(immediate: false);
  }
  @protected
  StreamController<ConnectivityStatus> get controller => _controller;
  @protected
  set status(ConnectivityStatus value) => _status = value;
  @protected
  set isBackendAvailable(bool value) => _isBackendAvailable = value;
  @protected
  void updateStatus(ConnectivityStatus newStatus) {
    if (_status == newStatus) return;
    final old = _status;
    _status = newStatus;
    if (!_controller.isClosed) {
      _controller.add(newStatus);
    }
    logger.info('[Connectivity] Status changed: $old -> $newStatus');
  }
  @protected
  void startBackendHealthPolling({bool immediate = true}) {
    _cancelPolling();
    if (immediate) {
      checkBackendAvailability();
    }
    _scheduleNextPoll();
  }
  void _scheduleNextPoll() {
    _backendCheckTimer?.cancel();
    final jitterMs = _rng.nextInt(_pollingConfig.maxJitter.inMilliseconds + 1);
    final delay = _pollingConfig.interval + Duration(milliseconds: jitterMs);
    _backendCheckTimer = Timer(delay, () async {
      await checkBackendAvailability();
      _scheduleNextPoll();
    });
  }
  void _cancelPolling() {
    _backendCheckTimer?.cancel();
    _backendCheckTimer = null;
  }
  @protected
  Future<Uri> buildHealthUri() async {
    final baseUrl = await ApiConfigService.getApiBaseUrl();
    final base = Uri.parse(baseUrl);
    final segments = List<String>.from(base.pathSegments);
    if (segments.isNotEmpty && segments.last == 'api') {
      segments.removeLast();
    }
    segments.addAll(_normalizePathSegments(_healthConfig.healthPath));
    return base.replace(pathSegments: segments);
  }
  List<String> _normalizePathSegments(String path) {
    return path.split('/').where((s) => s.isNotEmpty).toList();
  }
  @protected
  @mustCallSuper
  Future<void> checkBackendAvailability() async {
    if (_checkInProgress) return;
    _checkInProgress = true;
    try {
      final healthUri = await buildHealthUri();
      final response = await _httpClient
          .get(
            healthUri,
            headers: const {
              'Cache-Control': 'no-cache',
              'Accept': 'application/json,text/plain,*/*',
            },
          );
      _isBackendAvailable = response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      _isBackendAvailable = false;
    } finally {
      _checkInProgress = false;
    }
  }
}