import 'package:thot/core/config/api_routes.dart';
import 'package:thot/core/services/network/api_client.dart';
import 'package:thot/features/admin/models/report.dart';
import 'package:thot/features/admin/providers/admin_repository.dart';

class AdminRepositoryImpl implements AdminRepository {
  final ApiService _apiService;
  AdminRepositoryImpl(this._apiService);
  Future<Map<String, dynamic>> getAdminStats() async {
    final response =
        await _apiService.get(ApiRoutes.buildPath(ApiRoutes.adminStats));
    return response.data['data'] ?? {};
  }

  Future<Map<String, dynamic>> getDetailedJournalistStats({
    String? period,
    String? journalistId,
  }) async {
    final queryParams = <String, String>{};
    if (period != null) queryParams['period'] = period;
    if (journalistId != null) queryParams['journalistId'] = journalistId;
    final uri = Uri.parse(ApiRoutes.adminJournalistStatsDetailed)
        .replace(queryParameters: queryParams.isEmpty ? null : queryParams);
    final response = await _apiService.get(uri.toString());
    return response.data['data'] ?? {};
  }

  Future<Map<String, dynamic>> getJournalists({
    String? search,
    String? status,
    String? sortBy = 'createdAt',
    String? order = 'desc',
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
      'sortBy': sortBy!,
      'order': order!,
    };
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (status != null && status.isNotEmpty) queryParams['status'] = status;
    final uri = Uri.parse(ApiRoutes.buildPath(ApiRoutes.adminJournalists))
        .replace(queryParameters: queryParams);
    final response = await _apiService.get(uri.toString());
    return response.data ?? {};
  }

  Future<List<Map<String, dynamic>>> getVerifiedJournalists() async {
    final response = await _apiService
        .get(ApiRoutes.buildPath(ApiRoutes.adminJournalistsVerified));
    final journalists = response.data['data'] as List? ?? [];
    return journalists.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getPendingJournalists() async {
    final response = await _apiService
        .get(ApiRoutes.buildPath(ApiRoutes.adminJournalistsPending));
    final journalists = response.data['data'] as List? ?? [];
    return journalists.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getRejectedJournalists() async {
    final response = await _apiService
        .get(ApiRoutes.buildPath(ApiRoutes.adminJournalistsRejected));
    final journalists = response.data['data'] as List? ?? [];
    return journalists.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> approveJournalist(String journalistId,
      {String? notes}) async {
    final body = <String, dynamic>{};
    if (notes != null && notes.isNotEmpty) body['notes'] = notes;
    final response = await _apiService.put(
      ApiRoutes.buildPath(ApiRoutes.approveJournalist(journalistId)),
      data: body,
    );
    return response.data ?? {};
  }

  Future<Map<String, dynamic>> rejectJournalist(
    String journalistId, {
    required String reason,
    String? notes,
  }) async {
    final body = <String, dynamic>{'reason': reason};
    if (notes != null && notes.isNotEmpty) body['notes'] = notes;
    final response = await _apiService.put(
      ApiRoutes.buildPath(ApiRoutes.rejectJournalist(journalistId)),
      data: body,
    );
    return response.data ?? {};
  }

  Future<Map<String, dynamic>> unverifyJournalist(
    String journalistId, {
    required String reason,
    int? suspensionDuration,
  }) async {
    final body = <String, dynamic>{'reason': reason};
    if (suspensionDuration != null) {
      body['suspensionDuration'] = suspensionDuration;
    }
    final response = await _apiService.put(
      ApiRoutes.buildPath(ApiRoutes.adminUnverifyJournalist(journalistId)),
      data: body,
    );
    return response.data ?? {};
  }

  Future<Map<String, dynamic>> getPosts({
    bool? reported,
    String? type,
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (reported != null) queryParams['reported'] = reported.toString();
    if (type != null && type.isNotEmpty) queryParams['type'] = type;
    if (status != null && status.isNotEmpty) queryParams['status'] = status;
    final uri = Uri.parse(ApiRoutes.buildPath(ApiRoutes.adminPosts))
        .replace(queryParameters: queryParams);
    final response = await _apiService.get(uri.toString());
    return response.data ?? {};
  }

  Future<Map<String, dynamic>> deletePost(
    String postId, {
    required String reason,
    bool notifyAuthor = true,
    String? message,
  }) async {
    final body = <String, dynamic>{
      'reason': reason,
      'notifyAuthor': notifyAuthor,
    };
    if (message != null && message.isNotEmpty) body['message'] = message;
    final response = await _apiService.delete(
      ApiRoutes.buildPath(ApiRoutes.deletePost(postId)),
      data: body,
    );
    return response.data ?? {};
  }

  Future<Map<String, dynamic>> getUsers({
    String? search,
    String? role,
    String? status,
    String? sortBy = 'createdAt',
    String? order = 'desc',
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
      'sortBy': sortBy!,
      'order': order!,
    };
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (role != null && role.isNotEmpty) queryParams['role'] = role;
    if (status != null && status.isNotEmpty) queryParams['status'] = status;
    final uri = Uri.parse(ApiRoutes.buildPath(ApiRoutes.adminUsers))
        .replace(queryParameters: queryParams);
    final response = await _apiService.get(uri.toString());
    return response.data ?? {};
  }

  Future<Map<String, dynamic>> suspendUser(
    String userId, {
    required String reason,
    int? duration,
  }) async {
    final body = <String, dynamic>{'reason': reason};
    if (duration != null) body['duration'] = duration;
    final response = await _apiService.put(
      ApiRoutes.buildPath(ApiRoutes.adminSuspendUser(userId)),
      data: body,
    );
    return response.data ?? {};
  }

  Future<Map<String, dynamic>> updateUserRole(
    String userId, {
    required String role,
  }) async {
    final response = await _apiService.put(
      ApiRoutes.buildPath(ApiRoutes.adminUpdateUserRole(userId)),
      data: {'role': role},
    );
    return response.data ?? {};
  }

  Future<Map<String, dynamic>> getAuditLogs({
    String? action,
    String? adminId,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 50,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (action != null && action.isNotEmpty) queryParams['action'] = action;
    if (adminId != null && adminId.isNotEmpty) {
      queryParams['adminId'] = adminId;
    }
    if (startDate != null) {
      queryParams['startDate'] = startDate.toIso8601String();
    }
    if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();
    final uri = Uri.parse(ApiRoutes.buildPath(ApiRoutes.adminLogs))
        .replace(queryParameters: queryParams);
    final response = await _apiService.get(uri.toString());
    return response.data ?? {};
  }

  @override
  Future<void> banUser(String userId, Duration duration) async {
    final body = <String, dynamic>{
      'duration': duration.inDays,
      'reason': 'Banned for ${duration.inDays} days',
    };
    await _apiService.put(
      ApiRoutes.buildPath(ApiRoutes.adminBanUser(userId)),
      data: body,
    );
  }

  @override
  Future<void> unbanUser(String userId) async {
    await _apiService.put(
      ApiRoutes.buildPath(ApiRoutes.adminUnbanUser(userId)),
    );
  }

  Future<Map<String, dynamic>> deleteComment(String commentId,
      {String? reason}) async {
    final body = <String, dynamic>{};
    if (reason != null) body['reason'] = reason;
    final response = await _apiService.delete(
      ApiRoutes.buildPath(ApiRoutes.adminDeleteComment(commentId)),
      data: body,
    );
    return response.data ?? {};
  }

  Future<Map<String, dynamic>> deleteShort(String shortId,
      {String? reason}) async {
    final body = <String, dynamic>{};
    if (reason != null) body['reason'] = reason;
    final response = await _apiService.delete(
      ApiRoutes.buildPath(ApiRoutes.adminDeleteShort(shortId)),
      data: body,
    );
    return response.data ?? {};
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    final response =
        await _apiService.get(ApiRoutes.buildPath(ApiRoutes.adminStats));
    return response.data;
  }

  Future<Map<String, dynamic>> getJournalistsWithPressCards({
    String? search,
    bool? verified,
    bool? hasPressCard,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (search != null) queryParams['search'] = search;
    if (verified != null) queryParams['verified'] = verified.toString();
    if (hasPressCard != null) {
      queryParams['hasPressCard'] = hasPressCard.toString();
    }
    final uri =
        Uri.parse(ApiRoutes.buildPath(ApiRoutes.adminJournalistsPressCards))
            .replace(queryParameters: queryParams);
    final response = await _apiService.get(uri.toString());
    return response.data;
  }

  Future<Map<String, dynamic>> getAllJournalists({
    String? search,
    bool? verified,
    int page = 1,
    int limit = 20,
  }) async {
    return await getUsers(
      search: search,
      role: 'journalist',
      page: page,
      limit: limit,
    );
  }

  Future<void> toggleJournalistVerification(
      String journalistId, bool verify) async {
    await _apiService.put(
      ApiRoutes.buildPath(
          ApiRoutes.adminToggleJournalistVerification(journalistId)),
      data: {'verify': verify},
    );
  }

  @override
  Future<List<Report>> getReports({
    String status = 'pending',
    String? targetType,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, String>{
      'status': status,
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (targetType != null) queryParams['targetType'] = targetType;
    final uri = Uri.parse(ApiRoutes.buildPath(ApiRoutes.adminReports))
        .replace(queryParameters: queryParams);
    final response = await _apiService.get(uri.toString());
    final reportsData = response.data['reports'] as List? ?? [];
    final reports = reportsData
        .map((json) => Report.fromJson(json as Map<String, dynamic>))
        .toList();
    return reports;
  }

  Future<void> reviewReport(
      String reportId, String status, String? actionTaken) async {
    await _apiService.put(
      ApiRoutes.buildPath(ApiRoutes.adminReviewReport(reportId)),
      data: {
        'status': status,
        if (actionTaken != null) 'actionTaken': actionTaken,
      },
    );
  }

  Future<void> deleteContent(String contentType, String contentId) async {
    await _apiService.delete(
      ApiRoutes.buildPath(ApiRoutes.adminDeleteContent(contentType, contentId)),
    );
  }

  Future<Map<String, dynamic>> getReportsByTarget({
    required String targetType,
    required String targetId,
    int page = 1,
    int limit = 50,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    final uri = Uri.parse(ApiRoutes.buildPath(
      '/admin/reports/by-target/$targetType/$targetId',
    )).replace(queryParameters: queryParams);
    final response = await _apiService.get(uri.toString());
    return response.data;
  }

  @override
  Future<void> moderateContent(String contentId, String action) async {
    await _apiService.put(
      ApiRoutes.buildPath('/admin/moderate/$contentId'),
      data: {'action': action},
    );
  }

  @override
  Future<Map<String, dynamic>> getAnalytics() async {
    return await getDashboardStats();
  }

  Future<void> createReport({
    required String targetType,
    required String targetId,
    required String reason,
    String? description,
  }) async {
    final response = await _apiService.post(
      ApiRoutes.buildPath(ApiRoutes.createReport),
      data: {
        'targetType': targetType,
        'targetId': targetId,
        'reason': reason,
        if (description != null) 'description': description,
      },
    );
    if (response.data['success'] != true) {
      throw Exception(response.data['message'] ?? 'Failed to submit report');
    }
  }

  Future<Map<String, dynamic>> reportContent({
    required String targetType,
    required String targetId,
    required String reason,
    String? description,
  }) async {
    final response = await _apiService.post(
      ApiRoutes.buildPath(ApiRoutes.createReport),
      data: {
        'targetType': targetType,
        'targetId': targetId,
        'reason': reason,
        if (description != null) 'description': description,
      },
    );
    if (response.data['success'] == true) {
      return response.data;
    } else {
      throw Exception(response.data['message'] ?? 'Failed to submit report');
    }
  }

  Future<List<Map<String, dynamic>>> getMyReports() async {
    final response = await _apiService.get(
      ApiRoutes.buildPath(ApiRoutes.getMyReports),
    );
    if (response.data['success'] == true && response.data['reports'] != null) {
      return List<Map<String, dynamic>>.from(response.data['reports']);
    } else {
      throw Exception('Failed to fetch reports');
    }
  }

  Future<Map<String, dynamic>> getReportStats({
    required String targetType,
    required String targetId,
  }) async {
    final response = await _apiService.get(
      ApiRoutes.buildPath(ApiRoutes.getReportStats(targetType, targetId)),
    );
    if (response.data['success'] == true) {
      return response.data;
    } else {
      throw Exception('Failed to fetch report stats');
    }
  }

  List<Map<String, String>> getReportReasons() {
    return [
      {'value': 'spam', 'label': 'Spam ou publicité'},
      {'value': 'harassment', 'label': 'Harcèlement'},
      {'value': 'hate_speech', 'label': 'Discours haineux'},
      {'value': 'violence', 'label': 'Violence'},
      {
        'value': 'false_information',
        'label': 'Information fausse ou trompeuse'
      },
      {'value': 'inappropriate_content', 'label': 'Contenu inapproprié'},
      {'value': 'copyright', 'label': 'Violation des droits d\'auteur'},
      {'value': 'other', 'label': 'Autre'},
    ];
  }

  String getReasonLabel(String value) {
    final reasons = getReportReasons();
    final reason = reasons.firstWhere(
      (r) => r['value'] == value,
      orElse: () => {'value': value, 'label': value},
    );
    return reason['label'] ?? value;
  }

  Future<void> submitProblemReport({
    required String category,
    required String subCategory,
    required String message,
  }) async {
    final response = await _apiService.post(
      ApiRoutes.buildPath(ApiRoutes.createProblemReport),
      data: {
        'category': category,
        'subCategory': subCategory,
        'message': message,
        'platform': 'mobile',
        'appVersion': '1.0.0',
      },
    );
    if (response.data['success'] != true) {
      throw Exception(
          response.data['message'] ?? 'Failed to submit problem report');
    }
  }
}
