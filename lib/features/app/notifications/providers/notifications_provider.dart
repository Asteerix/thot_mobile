import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thot/core/services/network/api_client.dart';
import 'package:thot/core/di/service_locator.dart';
import 'package:thot/features/app/notifications/models/notification.dart';
import 'package:thot/features/app/notifications/providers/notification_repository.dart';
import 'package:thot/features/app/notifications/providers/notification_repository_impl.dart';
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final apiService = getIt<ApiService>();
  return NotificationRepositoryImpl(apiService);
});
class NotificationsState {
  final List<NotificationModel> notifications;
  final bool isLoading;
  final String? error;
  final int unreadCount;
  const NotificationsState({
    this.notifications = const [],
    this.isLoading = false,
    this.error,
    this.unreadCount = 0,
  });
  NotificationsState copyWith({
    List<NotificationModel>? notifications,
    bool? isLoading,
    String? error,
    int? unreadCount,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}
class NotificationsNotifier extends StateNotifier<NotificationsState> {
  final NotificationRepository _repository;
  NotificationsNotifier(this._repository) : super(const NotificationsState()) {
    _loadNotifications();
    _listenToNotificationStream();
  }
  Future<void> _loadNotifications() async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _repository.getNotifications();
    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
      ),
      (notifications) {
        final unreadCount = notifications.where((n) => !n.read).length;
        state = state.copyWith(
          isLoading: false,
          notifications: notifications,
          unreadCount: unreadCount,
          error: null,
        );
      },
    );
  }
  void _listenToNotificationStream() {
    _repository.notificationStream.listen((notification) {
      final updatedNotifications = [notification, ...state.notifications];
      final unreadCount = updatedNotifications.where((n) => !n.read).length;
      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: unreadCount,
      );
    });
  }
  Future<void> markAsRead(String notificationId) async {
    final result = await _repository.markAsRead(notificationId);
    result.fold(
      (failure) => state = state.copyWith(error: failure.message),
      (_) {
        final updatedNotifications = state.notifications.map((notification) {
          if (notification.id == notificationId) {
            return notification.copyWith(read: true);
          }
          return notification;
        }).toList();
        final unreadCount = updatedNotifications.where((n) => !n.read).length;
        state = state.copyWith(
          notifications: updatedNotifications,
          unreadCount: unreadCount,
          error: null,
        );
      },
    );
  }
  Future<void> markAllAsRead() async {
    final result = await _repository.markAllAsRead();
    result.fold(
      (failure) => state = state.copyWith(error: failure.message),
      (_) {
        final updatedNotifications = state.notifications.map((notification) {
          return notification.copyWith(read: true);
        }).toList();
        state = state.copyWith(
          notifications: updatedNotifications,
          unreadCount: 0,
          error: null,
        );
      },
    );
  }
  Future<void> deleteNotification(String notificationId) async {
    final result = await _repository.deleteNotification(notificationId);
    result.fold(
      (failure) => state = state.copyWith(error: failure.message),
      (_) {
        final updatedNotifications = state.notifications
            .where((notification) => notification.id != notificationId)
            .toList();
        final unreadCount = updatedNotifications.where((n) => !n.read).length;
        state = state.copyWith(
          notifications: updatedNotifications,
          unreadCount: unreadCount,
          error: null,
        );
      },
    );
  }
  Future<void> refresh() async {
    await _loadNotifications();
  }
}
final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  return NotificationsNotifier(repository);
});
final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notificationsState = ref.watch(notificationsProvider);
  return notificationsState.unreadCount;
});