import '../../domain/entities/analytics_stats.dart';
class AnalyticsStatsDto {
  final int totalViews;
  final int totalPosts;
  final int totalLikes;
  final int totalComments;
  final double engagementRate;
  final List<Map<String, dynamic>> viewsTimeseries;
  final List<Map<String, dynamic>> likesTimeseries;
  const AnalyticsStatsDto({
    required this.totalViews,
    required this.totalPosts,
    required this.totalLikes,
    required this.totalComments,
    required this.engagementRate,
    required this.viewsTimeseries,
    required this.likesTimeseries,
  });
  factory AnalyticsStatsDto.fromJson(Map<String, dynamic> json) {
    return AnalyticsStatsDto(
      totalViews: json['totalViews'] ?? 0,
      totalPosts: json['totalPosts'] ?? 0,
      totalLikes: json['totalLikes'] ?? 0,
      totalComments: json['totalComments'] ?? 0,
      engagementRate: (json['engagementRate'] ?? 0.0).toDouble(),
      viewsTimeseries: (json['viewsTimeseries'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
      likesTimeseries: (json['likesTimeseries'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
    );
  }
  AnalyticsStats toEntity() {
    return AnalyticsStats(
      totalViews: totalViews,
      totalPosts: totalPosts,
      totalLikes: totalLikes,
      totalComments: totalComments,
      engagementRate: engagementRate,
      viewsTimeseries: viewsTimeseries
          .map((e) => TimeSeriesData.fromJson(e))
          .toList(),
      likesTimeseries: likesTimeseries
          .map((e) => TimeSeriesData.fromJson(e))
          .toList(),
    );
  }
}