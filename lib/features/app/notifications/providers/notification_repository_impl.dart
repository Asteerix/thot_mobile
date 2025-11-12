import 'dart:async';
import 'package:thot/core/utils/either.dart';
import 'package:thot/core/services/network/api_client.dart';
import 'package:thot/core/config/api_routes.dart';
import 'package:thot/core/services/logging/logger_service.dart';
import 'package:thot/core/services/realtime/socket_service.dart';
import 'package:thot/core/services/realtime/event_bus.dart';
import 'package:thot/features/app/notifications/models/notification.dart';
import 'package:thot/features/app/notifications/models/notification_failure.dart';
import 'package:thot/features/app/notifications/providers/notification_repository.dart';
import 'package:thot/features/app/notifications/models/notification_dto.dart';
class NotificationRepositoryImpl implements NotificationRepository {
  final ApiService _apiService;
  final _logger = LoggerService.instance;
  final _socketService = SocketService();
  final _eventBus = EventBus();
  StreamSubscription<SocketNotificationEvent>? _socketSubscription;
  final _unreadCountController = StreamController<int>.broadcast();
  final _notificationController =
      StreamController<NotificationModel>.broadcast();
  NotificationRepositoryImpl(this._apiService) {
    _initializeSocketListener();
  }
  void _initializeSocketListener() {
    _socketSubscription =
        _eventBus.on<SocketNotificationEvent>().listen((event) {
      try {
        final notification = NotificationModel.fromJson(event.notification);
        _notificationController.add(notification);
        _updateUnreadCount();
        _logger.info(
            'New notification received: ${notification.type} from ${notification.sender.username}');
      } catch (e) {
        _logger.error('Error processing socket notification', e);
      }
    });
  }
  @override
  Future<Either<NotificationFailure, List<NotificationModel>>>
      getNotifications() async {
    try {
      final result = await getNotificationsPaginated();
      return Right(result['notifications'] as List<NotificationModel>);
    } catch (e) {
      _logger.error('Error getting notifications', e);
      return Left(NotificationFailure.serverError(e.toString()));
    }
  }
  Future<Map<String, dynamic>> getNotificationsPaginated({
    int page = 1,
    int limit = 20,
    String? type,
  }) async {
    try {
      var endpoint =
          '${ApiRoutes.buildPath(ApiRoutes.notifications)}?page=$page&limit=$limit';
      if (type != null && type.isNotEmpty) {
        endpoint += '&type=$type';
      }
      final response = await _apiService.get(endpoint);
      final data = response.data['data'] ?? response.data;
      if (data['notifications'] != null) {
        return {
          'notifications': (data['notifications'] as List)
              .map((n) => NotificationModel.fromJson(n))
              .toList(),
          'currentPage': data['currentPage'] ?? page,
          'totalPages': data['totalPages'] ?? 1,
          'totalNotifications': data['totalNotifications'] ?? 0,
          'unreadCount': data['unreadCount'] ?? 0,
        };
      } else {
        throw Exception('Failed to get notifications');
      }
    } catch (e) {
      _logger.error('Error getting notifications paginated', e);
      rethrow;
    }
  }
  Future<int> getUnreadCount() async {
    try {
      final endpoint = ApiRoutes.buildPath(ApiRoutes.notificationUnreadCount);
      final response = await _apiService.get(endpoint);
      final data = response.data['data'] ?? response.data;
      return data['unreadCount'] ?? 0;
    } catch (e) {
      _logger.error('Error getting unread count', e);
      return 0;
    }
  }
  @override
  Future<Either<NotificationFailure, void>> markAsRead(
      String notificationId) async {
    try {
      final endpoint =
          ApiRoutes.buildPath(ApiRoutes.markNotificationAsRead(notificationId));
      await _apiService.patch(endpoint, data: {});
      return const Right(null);
    } catch (e) {
      _logger.error('Error marking notification as read', e);
      return Left(NotificationFailure.serverError(e.toString()));
    }
  }
  @override
  Future<Either<NotificationFailure, void>> markAllAsRead() async {
    try {
      final endpoint =
          ApiRoutes.buildPath(ApiRoutes.markAllNotificationsAsRead);
      await _apiService.patch(endpoint, data: {});
      return const Right(null);
    } catch (e) {
      _logger.error('Error marking all notifications as read', e);
      return Left(NotificationFailure.serverError(e.toString()));
    }
  }
  @override
  Future<Either<NotificationFailure, void>> deleteNotification(
      String notificationId) async {
    try {
      final endpoint =
          ApiRoutes.buildPath(ApiRoutes.deleteNotification(notificationId));
      await _apiService.delete(endpoint);
      return const Right(null);
    } catch (e) {
      _logger.error('Error deleting notification', e);
      return Left(NotificationFailure.serverError(e.toString()));
    }
  }
  Future<void> deleteReadNotifications() async {
    try {
      final endpoint = ApiRoutes.buildPath(ApiRoutes.deleteReadNotifications);
      await _apiService.delete(endpoint);
    } catch (e) {
      _logger.error('Error deleting read notifications', e);
      rethrow;
    }
  }
  Future<void> setRead(String notificationId, {required bool markRead}) async {
    try {
      if (markRead) {
        await markAsRead(notificationId);
      }
    } catch (e) {
      _logger.error('Error setting notification read status', e);
      rethrow;
    }
  }
  Future<void> setReadMany(List<String> ids, {required bool markRead}) async {
    try {
      for (final id in ids) {
        await setRead(id, markRead: markRead);
      }
    } catch (e) {
      _logger.error('Error setting multiple notifications read status', e);
      rethrow;
    }
  }
  Future<void> deleteNotifications(List<String> ids) async {
    try {
      for (final id in ids) {
        await deleteNotification(id);
      }
    } catch (e) {
      _logger.error('Error deleting multiple notifications', e);
      rethrow;
    }
  }
  Future<void> followBack(String userId) async {
    try {
      _logger.info('Follow back requested for user: $userId');
    } catch (e) {
      _logger.error('Error following back user', e);
      rethrow;
    }
  }
  @override
  Stream<NotificationModel> get notificationStream =>
      _notificationController.stream;
  Stream<int> get unreadCountStream => _unreadCountController.stream;
  void startPolling() {
    _socketService.initialize();
    _socketService.subscribeToNotifications();
    _updateUnreadCount();
  }
  void stopPolling() {
    _socketSubscription?.cancel();
  }
  Future<void> _updateUnreadCount() async {
    try {
      final count = await getUnreadCount();
      _unreadCountController.add(count);
    } catch (e) {
      _logger.error('Error updating unread count', e);
    }
  }
  Future<Map<String, bool>> getPreferences() async {
    try {
      final endpoint = ApiRoutes.buildPath(ApiRoutes.notificationPreferences);
      final response = await _apiService.get(endpoint);
      final data = response.data['data'] ?? response.data;
      if (data['preferences'] != null) {
        return Map<String, bool>.from(data['preferences']);
      }
      return _getDefaultPreferences();
    } catch (e) {
      _logger.error('Error fetching notification preferences', e);
      return _getDefaultPreferences();
    }
  }
  Future<bool> updatePreferences(Map<String, bool> preferences) async {
    try {
      final endpoint = ApiRoutes.buildPath(ApiRoutes.notificationPreferences);
      final response = await _apiService.put(endpoint, data: preferences);
      return response.data['success'] == true;
    } catch (e) {
      _logger.error('Error updating notification preferences', e);
      return false;
    }
  }
  Map<String, bool> _getDefaultPreferences() {
    return {
      'enabled': true,
      'likes': true,
      'comments': true,
      'follows': true,
      'mentions': true,
      'posts': true,
      'polls': true,
      'sound': true,
    };
  }
  void dispose() {
    _socketSubscription?.cancel();
    _socketService.disconnect();
    _unreadCountController.close();
    _notificationController.close();
  }
}