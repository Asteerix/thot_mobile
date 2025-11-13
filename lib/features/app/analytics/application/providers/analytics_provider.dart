import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/analytics_stats.dart';
import '../../domain/repositories/analytics_repository.dart';
import 'package:thot/core/di/service_locator.dart';
final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return ServiceLocator.instance.analyticsRepository;
});
final analyticsStatsProvider = FutureProvider.family<AnalyticsStats?, ({DateTime start, DateTime end})>(
  (ref, params) async {
    final repository = ref.watch(analyticsRepositoryProvider);
    final result = await repository.getStats(
      startDate: params.start,
      endDate: params.end,
    );
    return result.fold(
      (failure) => null,
      (stats) => stats,
    );
  },
);
final topPostsProvider = FutureProvider.family<List<Map<String, dynamic>>, ({DateTime start, DateTime end, int limit})>(
  (ref, params) async {
    final repository = ref.watch(analyticsRepositoryProvider);
    final result = await repository.getTopPosts(
      startDate: params.start,
      endDate: params.end,
      limit: params.limit,
    );
    return result.fold(
      (failure) => [],
      (posts) => posts,
    );
  },
);