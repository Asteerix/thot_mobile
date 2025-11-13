import 'package:dio/dio.dart';
import 'package:thot/core/services/network/api_client.dart';
import 'package:thot/core/utils/either.dart';
import '../../domain/failures/analytics_failure.dart';
import '../../domain/repositories/analytics_repository.dart';
import '../../domain/entities/analytics_stats.dart';
import '../models/analytics_dto.dart';

class AnalyticsRepositoryImpl implements AnalyticsRepository {
  final ApiClient _apiClient;
  AnalyticsRepositoryImpl(this._apiClient);
  @override
  Future<Either<AnalyticsFailure, AnalyticsStats>> getStats({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _apiClient.get(
        '/analytics/stats',
        queryParameters: {
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
        },
      );
      final dto = AnalyticsStatsDto.fromJson(response.data);
      return Right(dto.toEntity());
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return const Left(AnalyticsUnauthorizedFailure());
      }
      return Left(AnalyticsNetworkFailure(e.message ?? 'Network error'));
    } catch (e) {
      return Left(AnalyticsServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<AnalyticsFailure, List<Map<String, dynamic>>>> getTopPosts({
    required DateTime startDate,
    required DateTime endDate,
    int limit = 10,
  }) async {
    try {
      final response = await _apiClient.get(
        '/analytics/top-posts',
        queryParameters: {
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
          'limit': limit,
        },
      );
      return Right(
          List<Map<String, dynamic>>.from(response.data['posts'] ?? []));
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return const Left(AnalyticsUnauthorizedFailure());
      }
      return Left(AnalyticsNetworkFailure(e.message ?? 'Network error'));
    } catch (e) {
      return Left(AnalyticsServerFailure(e.toString()));
    }
  }
}
