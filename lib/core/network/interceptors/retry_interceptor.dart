import 'package:dio/dio.dart';

class RetryInterceptor extends Interceptor {
  RetryInterceptor({
    required this.dio,
    this.maxRetries = 3,
  });
  final Dio dio;
  final int maxRetries;
  static const List<int> _retryableStatuses = [
    408,
    429,
    500,
    502,
    503,
    504,
  ];
  final Map<String, int> _retryCount = {};
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      handler.next(err);
      return;
    }
    if (_shouldRetryError(err)) {
      await _handleRetryableError(err, handler);
      return;
    }
    handler.next(err);
  }

  bool _shouldRetryError(DioException err) {
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError ||
        (err.type == DioExceptionType.unknown &&
            err.error.toString().contains('SocketException'))) {
      return true;
    }
    final statusCode = err.response?.statusCode;
    if (statusCode != null && _retryableStatuses.contains(statusCode)) {
      return true;
    }
    return false;
  }

  Future<void> _handleRetryableError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final requestKey = _getRequestKey(err.requestOptions);
    final currentRetries = _retryCount[requestKey] ?? 0;
    if (currentRetries >= maxRetries) {
      _retryCount.remove(requestKey);
      print(
          '[RetryInterceptor] Max retries ($maxRetries) reached for ${err.requestOptions.method} ${err.requestOptions.uri}');
      handler.next(err);
      return;
    }
    _retryCount[requestKey] = currentRetries + 1;
    final delay = _calculateBackoffDelay(currentRetries,
        statusCode: err.response?.statusCode);
    print(
        '[RetryInterceptor] Retry ${currentRetries + 1}/$maxRetries after ${delay}ms | ${err.requestOptions.method} ${err.requestOptions.uri.path}');
    await Future.delayed(Duration(milliseconds: delay));
    try {
      final response = await dio.fetch(err.requestOptions);
      _retryCount.remove(requestKey);
      handler.resolve(response);
    } on DioException catch (retryErr) {
      if (_shouldRetryError(retryErr)) {
        await _handleRetryableError(retryErr, handler);
      } else {
        _retryCount.remove(requestKey);
        handler.next(retryErr);
      }
    } catch (e) {
      _retryCount.remove(requestKey);
      handler.next(DioException(
        requestOptions: err.requestOptions,
        error: e,
      ));
    }
  }

  int _calculateBackoffDelay(int retryAttempt, {int? statusCode}) {
    if (statusCode == 429) {
      const delays = [2000, 5000, 10000];
      return retryAttempt < delays.length ? delays[retryAttempt] : 10000;
    }
    const baseDelay = 1000;
    const maxDelay = 4000;
    final delay = baseDelay * (1 << retryAttempt);
    return delay > maxDelay ? maxDelay : delay;
  }

  String _getRequestKey(RequestOptions options) {
    return '${options.method}:${options.uri}';
  }
}
