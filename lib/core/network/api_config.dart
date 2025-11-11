import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
class ApiConfigService {
  static final ApiConfigService _instance = ApiConfigService._internal();
  factory ApiConfigService() => _instance;
  ApiConfigService._internal();
  String? _cachedUrl;
  DateTime? _cacheTimestamp;
  static const Duration _cacheValidity = Duration(minutes: 30);
  Future<String>? _resolutionInProgress;
  static const String _localAndroid = 'http://10.0.2.2:3000';
  static const String _localIosWeb = 'http://localhost:3000';
  static const String _production = 'http://37.59.106.113';
  static const Duration _healthTimeout = Duration(seconds: 3);
  static const Duration _ngrokTimeout = Duration(seconds: 5);
  static Future<String> getApiBaseUrl({bool forceRefresh = false}) async {
    return _instance._getApiBaseUrl(forceRefresh: forceRefresh);
  }
  Future<String> _getApiBaseUrl({bool forceRefresh = false}) async {
    if (forceRefresh) {
      _clearCache();
    }
    if (_resolutionInProgress != null) {
      return _resolutionInProgress!;
    }
    _resolutionInProgress = _resolveUrl();
    try {
      return await _resolutionInProgress!;
    } finally {
      _resolutionInProgress = null;
    }
  }
  Future<String> _resolveUrl() async {
    if (kReleaseMode) {
      _log('Using production URL');
      return _production;
    }
    final envUrl = _getEnvUrl();
    if (envUrl != null) {
      _cacheUrl(envUrl);
      _log('Using environment URL');
      return envUrl;
    }
    if (_isCacheValid()) {
      _log('Using cached URL');
      return _cachedUrl!;
    }
    _log('Starting auto-detection');
    final detected = await _autoDetect();
    if (detected != null) {
      _cacheUrl(detected);
      _log('Detected: $detected');
      return detected;
    }
    final fallback = _getPlatformFallback();
    _log('Using fallback: $fallback');
    return fallback;
  }
  Future<String?> _autoDetect() async {
    final ngrokUrl = await _detectNgrok();
    if (ngrokUrl != null) return ngrokUrl;
    final localUrl = _getPlatformFallback();
    if (await _checkHealth(localUrl)) {
      return localUrl;
    }
    return null;
  }
  Future<String?> _detectNgrok() async {
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.iOS) {
      return null;
    }
    final hosts = [
      'localhost',
      if (defaultTargetPlatform == TargetPlatform.android) '10.0.2.2',
    ];
    for (final host in hosts) {
      final url = await _queryNgrokInspector(host);
      if (url != null) return url;
    }
    return null;
  }
  Future<String?> _queryNgrokInspector(String host) async {
    final inspectorUrl = 'http://$host:4040/api/tunnels';
    try {
      final response = await http
          .get(Uri.parse(inspectorUrl),
              headers: {'Accept': 'application/json'})
          .timeout(_ngrokTimeout);
      if (response.statusCode != 200) return null;
      final data = json.decode(response.body);
      final tunnels = (data['tunnels'] as List?) ?? [];
      for (final tunnel in tunnels) {
        final publicUrl = tunnel['public_url'] as String?;
        final config = tunnel['config'] as Map?;
        final addr = config?['addr']?.toString() ?? '';
        if (publicUrl == null || !addr.contains(':3000')) continue;
        final httpsUrl = publicUrl.startsWith('https')
            ? publicUrl
            : publicUrl.replaceFirst('http:', 'https:');
        final apiUrl = _ensureApiSuffix(httpsUrl);
        if (await _checkHealth(apiUrl)) {
          return apiUrl;
        }
      }
    } catch (_) {
    }
    return null;
  }
  Future<bool> _checkHealth(String baseUrl) async {
    try {
      final healthUrl = _buildHealthUrl(baseUrl);
      final response = await http
          .get(Uri.parse(healthUrl), headers: {'Accept': 'application/json'})
          .timeout(_healthTimeout);
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }
  String? _getEnvUrl() {
    final envUrl = dotenv.env['API_BASE_URL'];
    if (envUrl != null && envUrl.isNotEmpty) {
      return _normalizeUrl(envUrl);
    }
    const dartDefine = String.fromEnvironment('API_BASE_URL');
    if (dartDefine.isNotEmpty) {
      return _normalizeUrl(dartDefine);
    }
    return null;
  }
  String _normalizeUrl(String url) {
    final cleaned = url.trim().replaceAll(RegExp(r'/+$'), '');
    return _isNgrok(cleaned) ? _ensureApiSuffix(cleaned) : cleaned;
  }
  bool _isNgrok(String url) => url.toLowerCase().contains('ngrok');
  String _ensureApiSuffix(String url) {
    final cleaned = url.trim().replaceAll(RegExp(r'/+$'), '');
    return cleaned.endsWith('/api') ? cleaned : '$cleaned/api';
  }
  String _buildHealthUrl(String baseUrl) {
    final cleaned = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    final withoutApi = cleaned.replaceFirst(RegExp(r'/api$'), '');
    return '$withoutApi/health';
  }
  String _getPlatformFallback() {
    if (kReleaseMode) return _production;
    if (kIsWeb) return _localIosWeb;
    if (defaultTargetPlatform == TargetPlatform.android) return _localAndroid;
    return _localIosWeb;
  }
  void _cacheUrl(String url) {
    _cachedUrl = url;
    _cacheTimestamp = DateTime.now();
  }
  bool _isCacheValid() {
    if (_cachedUrl == null || _cacheTimestamp == null) return false;
    final elapsed = DateTime.now().difference(_cacheTimestamp!);
    return elapsed < _cacheValidity;
  }
  void _clearCache() {
    _cachedUrl = null;
    _cacheTimestamp = null;
  }
  void _log(String message) {
    if (kDebugMode) {
      print('[ApiConfig] $message');
    }
  }
  static void clearCache() => _instance._clearCache();
  static void setApiBaseUrl(String url) {
    final normalized = _instance._normalizeUrl(url);
    _instance._cacheUrl(normalized);
    _instance._log('URL manually set: $normalized');
  }
  static String? getCurrentUrl() {
    final instance = _instance;
    return instance._getEnvUrl() ??
           (instance._isCacheValid() ? instance._cachedUrl : null);
  }
}
typedef ApiConfig = ApiConfigService;