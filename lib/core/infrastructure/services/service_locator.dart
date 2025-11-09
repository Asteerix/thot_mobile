import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart'
    show kDebugMode, kProfileMode, kReleaseMode, ValueListenable, ValueNotifier, debugPrint;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:thot/core/constants/app_config.dart';
import 'package:thot/core/network/api_client.dart';
import 'package:thot/core/network/api_config.dart';
import 'package:thot/core/network/interceptors/retry_interceptor.dart';
import 'package:thot/core/connectivity/connectivity_service_factory.dart';
import 'package:thot/core/monitoring/logger_service.dart';
import 'package:thot/core/storage/token_service.dart';
import 'package:thot/core/providers/theme_provider.dart';
import 'package:thot/features/authentication/application/providers/auth_provider.dart';
import 'package:thot/features/posts/application/providers/posts_state_provider.dart'
    as posts_state;
import 'package:thot/features/authentication/data/repositories/auth_repository_impl.dart';
import 'package:thot/features/posts/data/repositories/post_repository_impl.dart';
import 'package:thot/features/comments/data/repositories/comment_repository_impl.dart';
import 'package:thot/features/admin/data/repositories/admin_repository_impl.dart';
import 'package:thot/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:thot/features/notifications/data/repositories/notification_repository_impl.dart';
enum InitPhase {
  idle,
  coreServices,
  connectivity,
  apiServices,
  dataServices,
  uiServices,
  authCheck,
  done,
  failed,
}
class ServiceLocator {
  static final ServiceLocator instance = ServiceLocator._internal();
  factory ServiceLocator() => instance;
  ServiceLocator._internal();
  SharedPreferences? _prefs;
  ApiService? _apiService;
  ConnectivityService? _connectivityService;
  GlobalKey<NavigatorState>? _navigatorKey;
  AuthRepositoryImpl? _authRepository;
  PostRepositoryImpl? _postRepository;
  CommentRepositoryImpl? _commentRepository;
  AdminRepositoryImpl? _adminRepository;
  ProfileRepositoryImpl? _profileRepository;
  NotificationRepositoryImpl? _notificationRepository;
  ThemeProvider? _themeProvider;
  AuthProvider? _authProvider;
  posts_state.PostsStateProvider? _postsStateProvider;
  String? _resolvedBaseUrl;
  int _retryCount = 0;
  static const int maxRetries = 3;
  bool _isInitialized = false;
  bool _isInitializing = false;
  Completer<void>? _initCompleter;
  final ValueNotifier<InitPhase> _initPhase = ValueNotifier(InitPhase.idle);
  final ValueNotifier<double> _initProgress = ValueNotifier(0.0);
  bool get isInitialized => _isInitialized;
  ValueListenable<InitPhase> get initPhaseListenable => _initPhase;
  ValueListenable<double> get initProgressListenable => _initProgress;
  String? get resolvedBaseUrl => _resolvedBaseUrl;
  Future<void> ensureInitialized() async {
    if (_isInitialized) return;
    if (_isInitializing && _initCompleter != null) {
      return _initCompleter!.future;
    }
    await initialize();
  }
  void dispose() {
    _initPhase.dispose();
    _initProgress.dispose();
  }
  void attachNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }
  Future<void> initialize() async {
    if (_isInitialized) {
      LoggerService.instance.info('ServiceLocator already initialized');
      return;
    }
    if (_isInitializing && _initCompleter != null) {
      LoggerService.instance
          .info('ServiceLocator initialization in progress; waiting');
      return _initCompleter!.future;
    }
    _isInitializing = true;
    _initCompleter = Completer<void>();
    _setPhase(InitPhase.idle, 0.0);
    _navigatorKey ??= GlobalKey<NavigatorState>();
    final totalSw = Stopwatch()..start();
    try {
      _setPhase(InitPhase.coreServices, 0.10);
      final prefsF = _initializeCoreServices();
      _setPhase(InitPhase.connectivity, 0.20);
      final connF = _initializeConnectivity();
      _prefs = await prefsF;
      _connectivityService = await connF;
      _setPhase(InitPhase.apiServices, 0.45);
      await _initializeApiServices();
      _setPhase(InitPhase.dataServices, 0.65);
      final dataF = _initializeDataServices();
      _setPhase(InitPhase.uiServices, 0.80);
      final uiF = _initializeUIServices();
      await Future.wait([dataF, uiF]);
      _setPhase(InitPhase.authCheck, 0.90);
      await _authProvider?.checkAuthStatus();
      _setPhase(InitPhase.done, 1.0);
      _retryCount = 0;
      _isInitialized = true;
      _isInitializing = false;
      totalSw.stop();
      _initCompleter?.complete();
      _initCompleter = null;
    } catch (e, stack) {
      _setPhase(InitPhase.failed, _initProgress.value);
      LoggerService.instance
          .error('Error initializing ServiceLocator', e, stack);
      if (_retryCount < maxRetries) {
        _retryCount++;
        final backoffMs = _retryCount * 800;
        LoggerService.instance.info(
            'Retrying initialization (attempt $_retryCount) in ${backoffMs}ms...');
        await Future.delayed(Duration(milliseconds: backoffMs));
        _isInitializing = false;
        try {
          await initialize();
          _initCompleter?.complete();
          _initCompleter = null;
          return;
        } catch (e2, s2) {
          _initCompleter?.completeError(e2, s2);
          _initCompleter = null;
          rethrow;
        }
      }
      _isInitializing = false;
      _initCompleter?.completeError(e, stack);
      _initCompleter = null;
      rethrow;
    }
  }
  void _setPhase(InitPhase phase, double progress) {
    _initPhase.value = phase;
    _initProgress.value = progress.clamp(0.0, 1.0);
  }
  static void resetForTest() {
    final instance = ServiceLocator.instance;
    instance._isInitialized = false;
    instance._isInitializing = false;
    instance._initCompleter = null;
    instance._retryCount = 0;
    instance._resolvedBaseUrl = null;
    instance._prefs = null;
    instance._apiService = null;
    instance._connectivityService = null;
    instance._navigatorKey = null;
    instance._authRepository = null;
    instance._postRepository = null;
    instance._commentRepository = null;
    instance._adminRepository = null;
    instance._profileRepository = null;
    instance._notificationRepository = null;
    instance._themeProvider = null;
    instance._authProvider = null;
    instance._postsStateProvider = null;
    instance._setPhase(InitPhase.idle, 0.0);
  }
  Future<SharedPreferences> _initializeCoreServices() async {
    final sw = Stopwatch()..start();
    final prefs = await SharedPreferences.getInstance();
    sw.stop();
    return prefs;
  }
  Future<ConnectivityService> _initializeConnectivity() async {
    final sw = Stopwatch()..start();
    final connectivityService = createConnectivityService();
    ConnectivityService.setInstance(connectivityService);
    await connectivityService.initialize();
    sw.stop();
    return connectivityService;
  }
  Future<void> _initializeApiServices() async {
    final sw = Stopwatch()..start();
    String baseUrl;
    try {
      baseUrl = await ApiConfigService.getApiBaseUrl();
    } catch (e) {
      LoggerService.instance
          .warning('Failed to detect API URL, using fallback: $e');
      baseUrl = AppConfig.apiBaseUrl;
    }
    _resolvedBaseUrl = baseUrl;
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: Duration(milliseconds: AppConfig.apiTimeout),
      receiveTimeout: Duration(milliseconds: AppConfig.apiTimeout),
      headers: {
        'Accept': 'application/json',
        'ngrok-skip-browser-warning': 'true',
      },
    ));
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        try {
          final token = await TokenService.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
            if (kDebugMode || kProfileMode) {
              LoggerService.instance.debug(
                  'Auth header attached for ${options.method} ${options.uri}');
            }
            if (_isSavedPath(options.uri.path) || _isLikeOrCommentPath(options.uri.path)) {
              debugPrint('🔑 [API_CLIENT] Authenticated request | method: ${options.method}, url: ${options.uri.toString()}, hasToken: true, tokenLength: ${token.length}, tokenPreview: ${_mask(token)}');
            }
          } else {
            if (kDebugMode || kProfileMode) {
              LoggerService.instance.debug(
                  'No token available for ${options.method} ${options.uri}');
            }
            if (_isSavedPath(options.uri.path) || _isLikeOrCommentPath(options.uri.path)) {
              debugPrint('⚠️ [API_CLIENT] Unauthenticated request | method: ${options.method}, url: ${options.uri.toString()}, hasToken: false');
            }
          }
        } catch (e) {
          LoggerService.instance.error('Failed to get token for request: $e');
        }
        if (!options.headers.containsKey('Content-Type') &&
            options.data != null &&
            options.data is! FormData) {
          options.headers['Content-Type'] = 'application/json';
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        if (_isSavedPath(response.requestOptions.uri.path)) {
          developer.log(
            'API Response',
            name: 'ServiceLocator',
            error: {
              'url': response.requestOptions.uri.toString(),
              'statusCode': response.statusCode?.toString() ?? 'unknown',
              'dataType': response.data?.runtimeType.toString() ?? 'null',
              'timestamp': DateTime.now().toIso8601String(),
            },
          );
        }
        if (response.data is String) {
          final trimmed = (response.data as String).trim();
          if (trimmed.isNotEmpty &&
              ((trimmed.startsWith('{') && trimmed.endsWith('}')) ||
                  (trimmed.startsWith('[') && trimmed.endsWith(']')))) {
            try {
              response.data = jsonDecode(trimmed);
              if (kDebugMode) {
                LoggerService.instance.info('Parsed JSON string response');
              }
            } catch (_) {
            }
          }
        }
        handler.next(response);
      },
      onError: (error, handler) {
        if (_isSavedPath(error.requestOptions.uri.path)) {
          developer.log(
            'API Error',
            name: 'ServiceLocator',
            error: {
              'url': error.requestOptions.uri.toString(),
              'type': error.type.toString(),
              'statusCode': error.response?.statusCode?.toString() ?? 'none',
              'message': error.message ?? 'no message',
              'timestamp': DateTime.now().toIso8601String(),
            },
          );
        }
        LoggerService.instance
            .error('API Error: ${error.message}', error.error);
        final resp = error.response;
        if (resp?.data is String) {
          final str = (resp!.data as String).trim();
          if (str.startsWith('{') || str.startsWith('[')) {
            try {
              resp.data = jsonDecode(str);
            } catch (_) {
              resp.data = {'success': false, 'message': str};
            }
          } else {
            resp.data = {'success': false, 'message': str};
          }
        }
        handler.next(error);
      },
    ));
    dio.interceptors.add(RetryInterceptor(dio: dio));
    if (!kReleaseMode) {
      dio.interceptors.add(
        LogInterceptor(
          request: false,
          requestHeader: false,
          requestBody: false,
          responseHeader: false,
          responseBody: false,
          error: true,
          logPrint: (obj) {
            final safe = obj.toString().replaceAllMapped(
                  RegExp(r'Bearer\s+([A-Za-z0-9\-_.]+)'),
                  (m) => 'Bearer ${_mask(m.group(1) ?? '')}',
                );
            if (safe.contains('DioException') || safe.contains('Error:')) {
              LoggerService.instance.error('API Error: $safe');
            }
          },
        ),
      );
    }
    _apiService = ApiService(dio);
    try {
      _authRepository = AuthRepositoryImpl(apiService: _apiService!);
      _authProvider = AuthProvider();
    } catch (e, stack) {
      LoggerService.instance.error('Error initializing API services', e, stack);
      rethrow;
    }
    sw.stop();
  }
  Future<void> _initializeDataServices() async {
    final sw = Stopwatch()..start();
    try {
      _postRepository = PostRepositoryImpl(_apiService!);
      _commentRepository = CommentRepositoryImpl(_apiService!);
      _adminRepository = AdminRepositoryImpl(_apiService!);
      _profileRepository = ProfileRepositoryImpl(_apiService!);
      _notificationRepository = NotificationRepositoryImpl(_apiService!);
      if (kDebugMode) {
        LoggerService.instance.debug('Data repositories initialized');
      }
    } catch (e, stack) {
      LoggerService.instance
          .error('Error initializing data services', e, stack);
      rethrow;
    } finally {
      sw.stop();
      if (kDebugMode) {
        LoggerService.instance.debug('Data services ready in ${sw.elapsedMilliseconds}ms');
      }
    }
  }
  Future<void> _initializeUIServices() async {
    final sw = Stopwatch()..start();
    try {
      _themeProvider = ThemeProvider();
      _postsStateProvider = posts_state.PostsStateProvider();
      if (kDebugMode) {
        LoggerService.instance.debug('UI providers initialized');
      }
    } catch (e, stack) {
      LoggerService.instance.error('Error initializing UI services', e, stack);
      rethrow;
    } finally {
      sw.stop();
      if (kDebugMode) {
        LoggerService.instance.debug('UI services ready in ${sw.elapsedMilliseconds}ms');
      }
    }
  }
  ApiService get apiService =>
      _apiService ?? (throw StateError('ApiService not initialized'));
  SharedPreferences get prefs =>
      _prefs ?? (throw StateError('SharedPreferences not initialized'));
  ConnectivityService get connectivityService =>
      _connectivityService ??
      (throw StateError('ConnectivityService not initialized'));
  GlobalKey<NavigatorState> get navigatorKey =>
      _navigatorKey ?? (throw StateError('NavigatorKey not initialized'));
  AuthRepositoryImpl get authRepository =>
      _authRepository ?? (throw StateError('AuthRepository not initialized'));
  PostRepositoryImpl get postRepository =>
      _postRepository ?? (throw StateError('PostRepository not initialized'));
  CommentRepositoryImpl get commentRepository =>
      _commentRepository ??
      (throw StateError('CommentRepository not initialized'));
  AdminRepositoryImpl get adminRepository =>
      _adminRepository ?? (throw StateError('AdminRepository not initialized'));
  ProfileRepositoryImpl get profileRepository =>
      _profileRepository ??
      (throw StateError('ProfileRepository not initialized'));
  NotificationRepositoryImpl get notificationRepository =>
      _notificationRepository ??
      (throw StateError('NotificationRepository not initialized'));
  ThemeProvider get themeProvider =>
      _themeProvider ?? (throw StateError('ThemeProvider not initialized'));
  AuthProvider get authProvider =>
      _authProvider ?? (throw StateError('AuthProvider not initialized'));
  posts_state.PostsStateProvider get postsStateProvider =>
      _postsStateProvider ??
      (throw StateError('PostsStateProvider not initialized'));
  static List<SingleChildWidget> get providers {
    assert(instance.isInitialized,
        'ServiceLocator must be initialized before accessing providers');
    return [
      Provider<GlobalKey<NavigatorState>>.value(value: instance.navigatorKey),
      ChangeNotifierProvider<ThemeProvider>(
        create: (_) => instance.themeProvider,
      ),
      ChangeNotifierProvider<AuthProvider>.value(
        value: instance.authProvider,
      ),
      ChangeNotifierProvider<posts_state.PostsStateProvider>.value(
        value: instance.postsStateProvider,
      ),
    ];
  }
  static Widget wrapWithProviders(Widget child) {
    return MultiProvider(
      providers: instance.isInitialized
          ? providers
          : <SingleChildWidget>[
              Provider<GlobalKey<NavigatorState>>.value(
                  value: instance._navigatorKey ?? GlobalKey<NavigatorState>()),
            ],
      child: child,
    );
  }
  static bool _isSavedPath(String path) =>
      path.contains('saved-posts') || path.contains('saved-shorts');
  static bool _isLikeOrCommentPath(String path) =>
      path.contains('/like') || path.contains('/unlike') ||
      path.contains('/comments') || path.contains('/comment');
  static String _mask(String value,
      {int visiblePrefix = 4, int visibleSuffix = 4}) {
    if (value.isEmpty) return '';
    if (value.length <= visiblePrefix + visibleSuffix) {
      return '*' * value.length;
    }
    final prefix = value.substring(0, visiblePrefix);
    final suffix = value.substring(value.length - visibleSuffix);
    return '$prefix****$suffix';
  }
}