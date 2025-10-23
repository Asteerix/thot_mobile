import '../../../../core/utils/either.dart';
import '../failures/analytics_failure.dart';
import '../entities/analytics_stats.dart';
abstract class AnalyticsRepository {
  Future<Either<AnalyticsFailure, AnalyticsStats>> getStats({
    required DateTime startDate,
    required DateTime endDate,
  });
  Future<Either<AnalyticsFailure, List<Map<String, dynamic>>>> getTopPosts({
    required DateTime startDate,
    required DateTime endDate,
    int limit = 10,
  });
}