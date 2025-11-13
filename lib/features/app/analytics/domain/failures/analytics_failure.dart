sealed class AnalyticsFailure {
  final String message;
  const AnalyticsFailure(this.message);
}
class AnalyticsNetworkFailure extends AnalyticsFailure {
  const AnalyticsNetworkFailure([super.message = 'Network error']);
}
class AnalyticsServerFailure extends AnalyticsFailure {
  const AnalyticsServerFailure([super.message = 'Server error']);
}
class AnalyticsUnauthorizedFailure extends AnalyticsFailure {
  const AnalyticsUnauthorizedFailure(
      [super.message = 'Unauthorized access']);
}