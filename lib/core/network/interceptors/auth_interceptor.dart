import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:thot/core/storage/token_service.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    List<Pattern>? skipAuthFor,
    this.onUnauthorized,
    this.onForbidden,
  }) : _skipAuthFor = skipAuthFor ?? const <Pattern>[];
  final List<Pattern> _skipAuthFor;
  final void Function(DioException err)? onUnauthorized;
  final void Function(DioException err, Map<String, dynamic>? responseData)?
      onForbidden;
  static const _productMode = bool.fromEnvironment('dart.vm.product');
  static const _logName = 'AuthInterceptor';
  final Random _random = Random();
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!options.headers.containsKey('X-Request-Id')) {
      options.headers['X-Request-Id'] = _generateRequestId();
    }
    if (_shouldSkipAuth(options)) {
      _log('Skip auth: ${options.method} ${options.path}', level: 800);
      handler.next(options);
      return;
    }
    try {
      final token = await TokenService.getToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
        _log(
          'Auth header set: ${options.method} ${options.path} | Token: ${_maskToken(token)}',
          level: 500,
        );
      } else {
        _log(
          'No token available: ${options.method} ${options.path}',
          level: 900,
        );
      }
    } catch (e, stackTrace) {
      _log(
        'Error attaching token: ${options.method} ${options.path}',
        level: 1000,
        error: e,
        stackTrace: stackTrace,
      );
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final statusCode = err.response?.statusCode;
    switch (statusCode) {
      case 401:
        _handleUnauthorized(err);
        break;
      case 403:
        _handleForbidden(err);
        break;
    }
    handler.next(err);
  }

  void _handleUnauthorized(DioException err) {
    _log(
      '401 Unauthorized: ${err.requestOptions.method} ${err.requestOptions.uri.path}',
      level: 900,
    );
    onUnauthorized?.call(err);
  }

  void _handleForbidden(DioException err) {
    final responseData = err.response?.data;
    final message = _extractMessage(responseData);
    final isSuspended = message.contains('suspend');
    _log(
      isSuspended
          ? '403 Account Suspended: ${err.requestOptions.uri.path}'
          : '403 Forbidden: ${err.requestOptions.uri.path}',
      level: 900,
    );
    onForbidden?.call(
      err,
      responseData is Map<String, dynamic> ? responseData : null,
    );
  }

  bool _shouldSkipAuth(RequestOptions options) {
    if (options.extra['skipAuth'] == true) return true;
    final path = options.path;
    for (final pattern in _skipAuthFor) {
      if (pattern is RegExp && pattern.hasMatch(path)) return true;
      if (pattern is String && path.contains(pattern)) return true;
    }
    return false;
  }

  String _generateRequestId() {
    final timestamp = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final randomPart =
        _random.nextInt(1 << 32).toRadixString(36).padLeft(7, '0');
    return '$timestamp-$randomPart';
  }

  String _maskToken(String token) {
    if (token.isEmpty) return 'empty';
    if (token.length <= 6) return '${token.substring(0, 2)}…(${token.length})';
    final prefix = token.substring(0, 4);
    final suffix = token.substring(token.length - 4);
    return '$prefix…$suffix(${token.length})';
  }

  String _extractMessage(dynamic data) {
    try {
      if (data is Map) {
        final msg = data['message'] ?? data['error'] ?? data['detail'];
        return msg is String ? msg.toLowerCase() : '';
      }
      if (data is String) return data.toLowerCase();
    } catch (_) {}
    return '';
  }

  void _log(
    String message, {
    int level = 800,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (_productMode && level < 900) return;
    print(message);
  }
}
