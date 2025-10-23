import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';
class TokenException implements Exception {
  final String message;
  TokenException(this.message);
  @override
  String toString() => message;
}
class TokenService {
  static const String _tokenKey = 'auth_token';
  static const String _userTypeKey = 'user_type';
  static const String _tokenExpiryKey = 'token_expiry';
  static const Duration _refreshWindow = Duration(hours: 1);
  static const Duration _clockSkew = Duration(seconds: 30);
  static String? _cachedToken;
  static int? _cachedExpEpochSec;
  static String? _cachedUserType;
  static bool _hasLoaded = false;
  static Timer? _refreshAlarm;
  static Timer? _expiryAlarm;
  static final StreamController<AuthState> _authCtrl =
      StreamController<AuthState>.broadcast();
  static Stream<AuthState> get authChanges => _authCtrl.stream;
  static AuthState get snapshot => AuthState(
        token: _cachedToken,
        userType: _cachedUserType,
        expiresAt: _cachedExpEpochSec == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(_cachedExpEpochSec! * 1000),
        refreshWindow: _refreshWindow,
      );
  static final bool _isProduct = const bool.fromEnvironment('dart.vm.product');
  static void _log(String message, {Object? error}) {
    if (_isProduct) return;
    developer.log(message, name: 'TokenService', error: error);
  }
  static Future<void> saveToken(String token,
      [dynamic userTypeOrBool = 'user']) async {
    try {
      if (token.isEmpty) throw TokenException('Token cannot be empty');
      final String userType = userTypeOrBool is bool
          ? (userTypeOrBool ? 'journalist' : 'user')
          : userTypeOrBool as String;
      final now = DateTime.now();
      int expiryTimestamp;
      if (token.startsWith('test_token_')) {
        expiryTimestamp =
            (now.add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000);
        _log('Test token saved, expires in 1h');
      } else {
        final payload = _decodeJwtPayload(token);
        final exp = _parseExp(payload['exp']);
        final expiry = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
        if (!expiry.isAfter(now.subtract(_clockSkew))) {
          throw TokenException('Token expired');
        }
        expiryTimestamp = exp;
      }
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.setString(_tokenKey, token),
        prefs.setString(_userTypeKey, userType),
        prefs.setInt(_tokenExpiryKey, expiryTimestamp),
      ]);
      _cachedToken = token;
      _cachedUserType = userType;
      _cachedExpEpochSec = expiryTimestamp;
      _hasLoaded = true;
      _scheduleAlarms();
      _emit();
      _log('Token saved (type: $userType)');
    } catch (e) {
      _log('Failed to save token', error: e);
      if (e is TokenException) rethrow;
      throw TokenException('Save failed: $e');
    }
  }
  static Future<String?> getToken() async {
    try {
      await _ensureLoaded();
      if (_cachedToken == null || _cachedExpEpochSec == null) return null;
      final expiry =
          DateTime.fromMillisecondsSinceEpoch(_cachedExpEpochSec! * 1000);
      if (!expiry.isAfter(DateTime.now().subtract(_clockSkew))) {
        await clearToken();
        return null;
      }
      return _cachedToken;
    } catch (e) {
      _log('getToken error', error: e);
      return null;
    }
  }
  static Future<String?> getUserType() async {
    await _ensureLoaded();
    return _cachedUserType;
  }
  @Deprecated('Use getUserType() == "journalist" instead')
  static Future<bool> isJournalist() async {
    return (await getUserType()) == 'journalist';
  }
  static Future<void> clearToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.remove(_tokenKey),
        prefs.remove(_userTypeKey),
        prefs.remove(_tokenExpiryKey),
      ]);
      _cachedToken = null;
      _cachedUserType = null;
      _cachedExpEpochSec = null;
      _cancelAlarms();
      _emit();
      _log('Token cleared');
    } catch (e) {
      _log('clearToken error', error: e);
      throw TokenException('Clear failed: $e');
    }
  }
  static Future<bool> isLoggedIn() async {
    return await getToken() != null;
  }
  static Future<DateTime?> getTokenExpiration() async {
    await _ensureLoaded();
    return _cachedExpEpochSec == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(_cachedExpEpochSec! * 1000);
  }
  static Future<bool> needsRefresh() async {
    final expiry = await getTokenExpiration();
    if (expiry == null) return false;
    return expiry.difference(DateTime.now()) <= _refreshWindow;
  }
  static Future<void> _ensureLoaded() async {
    if (_hasLoaded) return;
    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString(_tokenKey);
    _cachedUserType = prefs.getString(_userTypeKey);
    _cachedExpEpochSec = prefs.getInt(_tokenExpiryKey);
    _hasLoaded = true;
    _scheduleAlarms();
    _emit();
  }
  static void _emit() {
    if (_authCtrl.hasListener) _authCtrl.add(snapshot);
  }
  static void _scheduleAlarms() {
    _cancelAlarms();
    if (_cachedExpEpochSec == null) return;
    final expiry =
        DateTime.fromMillisecondsSinceEpoch(_cachedExpEpochSec! * 1000);
    final now = DateTime.now();
    final refreshAt = expiry.subtract(_refreshWindow);
    final refreshDelay =
        refreshAt.isAfter(now) ? refreshAt.difference(now) : Duration.zero;
    _refreshAlarm = Timer(refreshDelay, _emit);
    final expireDelay =
        expiry.isAfter(now) ? expiry.difference(now) : Duration.zero;
    _expiryAlarm = Timer(expireDelay, clearToken);
  }
  static void _cancelAlarms() {
    _refreshAlarm?.cancel();
    _expiryAlarm?.cancel();
    _refreshAlarm = null;
    _expiryAlarm = null;
  }
  static Map<String, dynamic> _decodeJwtPayload(String token) {
    final parts = token.split('.');
    if (parts.length != 3) throw TokenException('Invalid JWT format');
    try {
      final normalized = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final obj = json.decode(decoded);
      if (obj is! Map<String, dynamic>) {
        throw TokenException('Invalid payload');
      }
      return obj;
    } catch (e) {
      throw TokenException('JWT decode error: $e');
    }
  }
  static int _parseExp(dynamic exp) {
    if (exp is int) return exp;
    if (exp is double) return exp.toInt();
    if (exp is String) return int.parse(exp);
    throw TokenException('Invalid exp claim');
  }
}
class AuthState {
  final String? token;
  final String? userType;
  final DateTime? expiresAt;
  final Duration refreshWindow;
  const AuthState({
    this.token,
    this.userType,
    this.expiresAt,
    this.refreshWindow = const Duration(hours: 1),
  });
  bool get isLoggedIn =>
      token != null && expiresAt != null && expiresAt!.isAfter(DateTime.now());
  bool get needsRefresh {
    if (expiresAt == null) return false;
    return expiresAt!.difference(DateTime.now()) <= refreshWindow;
  }
  bool get isJournalist => userType == 'journalist';
  Duration? get timeLeft => expiresAt == null
      ? null
      : (expiresAt!.isAfter(DateTime.now())
          ? expiresAt!.difference(DateTime.now())
          : Duration.zero);
  @override
  String toString() => 'AuthState('
      'logged=$isLoggedIn, '
      'refresh=$needsRefresh, '
      'type=$userType, '
      'exp=${expiresAt?.toIso8601String()}'
      ')';
}