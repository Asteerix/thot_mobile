class AnalyticsStats {
  final int totalViews;
  final int totalPosts;
  final int totalLikes;
  final int totalComments;
  final double engagementRate;
  final List<TimeSeriesData> viewsTimeseries;
  final List<TimeSeriesData> likesTimeseries;
  const AnalyticsStats({
    required this.totalViews,
    required this.totalPosts,
    required this.totalLikes,
    required this.totalComments,
    required this.engagementRate,
    required this.viewsTimeseries,
    required this.likesTimeseries,
  });
  factory AnalyticsStats.fromJson(Map<String, dynamic> json) {
    return AnalyticsStats(
      totalViews: json['totalViews'] ?? 0,
      totalPosts: json['totalPosts'] ?? 0,
      totalLikes: json['totalLikes'] ?? 0,
      totalComments: json['totalComments'] ?? 0,
      engagementRate: (json['engagementRate'] ?? 0.0).toDouble(),
      viewsTimeseries: (json['viewsTimeseries'] as List<dynamic>?)
              ?.map((e) => TimeSeriesData.fromJson(e))
              .toList() ??
          [],
      likesTimeseries: (json['likesTimeseries'] as List<dynamic>?)
              ?.map((e) => TimeSeriesData.fromJson(e))
              .toList() ??
          [],
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'totalViews': totalViews,
      'totalPosts': totalPosts,
      'totalLikes': totalLikes,
      'totalComments': totalComments,
      'engagementRate': engagementRate,
      'viewsTimeseries': viewsTimeseries.map((e) => e.toJson()).toList(),
      'likesTimeseries': likesTimeseries.map((e) => e.toJson()).toList(),
    };
  }
}
class TimeSeriesData {
  final DateTime date;
  final double value;
  const TimeSeriesData({
    required this.date,
    required this.value,
  });
  factory TimeSeriesData.fromJson(Map<String, dynamic> json) {
    return TimeSeriesData(
      date: DateTime.parse(json['date']),
      value: (json['value'] ?? 0.0).toDouble(),
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'value': value,
    };
  }
}