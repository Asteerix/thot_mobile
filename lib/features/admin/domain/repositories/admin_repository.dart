import 'package:thot/features/admin/domain/entities/report.dart';
abstract class AdminRepository {
  Future<List<Report>> getReports({
    String status = 'pending',
    String? targetType,
    int page = 1,
    int limit = 20,
  });
  Future<void> moderateContent(String contentId, String action);
  Future<void> banUser(String userId, Duration duration);
  Future<void> unbanUser(String userId);
  Future<Map<String, dynamic>> getAnalytics();
}