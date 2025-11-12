import 'package:dio/dio.dart';
import 'package:thot/core/di/api_exception.dart';
class ApiService {
  final Dio _dio;
  ApiService(this._dio);
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
  Future<Response> post(String path, {dynamic data}) async {
    try {
      return await _dio.post(path, data: data);
    } on DioException catch (e) {
      if ((e.response?.statusCode == 401 || e.response?.statusCode == 403) &&
          path.contains('/auth/')) {
        if (e.response != null) {
          return e.response!;
        }
      }
      throw ApiException.fromDioError(e);
    }
  }
  Future<Response> put(String path, {dynamic data}) async {
    try {
      return await _dio.put(path, data: data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
  Future<Response> patch(String path, {dynamic data}) async {
    try {
      return await _dio.patch(path, data: data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
  Future<Response> delete(String path, {dynamic data}) async {
    try {
      return await _dio.delete(path, data: data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
  Dio get dio => _dio;
}
typedef ApiClient = ApiService;