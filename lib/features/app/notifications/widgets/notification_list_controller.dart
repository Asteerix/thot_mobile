import 'package:flutter/material.dart';
import 'package:thot/features/app/notifications/models/notification.dart';
import 'package:thot/core/di/service_locator.dart';
import '../widgets/notification_filter.dart';
class NotificationSection {
  final String label;
  final List<NotificationModel> items;
  NotificationSection({required this.label, required this.items});
}
class NotificationListController extends ChangeNotifier {
  final List<NotificationModel> _notifications = [];
  bool _loading = true;
  bool _error = false;
  String _errorMessage = '';
  int _currentPage = 1;
  int _totalPages = 1;
  final _repository = ServiceLocator.instance.notificationRepository;
  List<NotificationModel> get notifications => List.unmodifiable(_notifications);
  bool get loading => _loading;
  bool get error => _error;
  String get errorMessage => _errorMessage;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  bool get hasMore => _currentPage < _totalPages;
  Future<void> loadNotifications({
    required NotificationFilter filter,
    bool reset = false,
  }) async {
    if (_loading && !reset) return;
    _loading = true;
    if (reset) {
      _error = false;
      _errorMessage = '';
      _currentPage = 1;
    }
    notifyListeners();
    try {
      if (reset) _notifications.clear();

      final String? filterType = filter.apiParam;

      final result = await _repository.getNotificationsPaginated(
        page: _currentPage,
        limit: 20,
        type: filterType,
      );

      if (result['notifications'] is List) {
        _notifications.addAll(
            (result['notifications'] as List).cast<NotificationModel>());
      }
      final newPage = (result['currentPage'] as int?) ?? 1;
      _totalPages = (result['totalPages'] as int?) ?? 1;

      // Increment page for next load if we're not resetting
      if (!reset) {
        _currentPage = newPage + 1;
      } else {
        _currentPage = newPage;
      }

      _loading = false;
      _error = false;
      notifyListeners();
    } catch (e) {
      _loading = false;
      _error = true;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
  Future<void> markAllAsRead() async {
    try {
      await _repository.markAllAsRead();
      for (var i = 0; i < _notifications.length; i++) {
        _notifications[i] = _notifications[i].copyWith(read: true);
      }
      notifyListeners();
    } catch (e) {
      _error = true;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }
  Future<void> deleteNotification(NotificationModel notification) async {
    final index = _notifications.indexOf(notification);
    if (index < 0) return;
    _notifications.removeAt(index);
    notifyListeners();
    try {
      await _repository.deleteNotification(notification.id);
    } catch (e) {
      _notifications.insert(index, notification);
      notifyListeners();
      rethrow;
    }
  }
  Future<void> toggleRead(NotificationModel notification) async {
    final index = _notifications.indexWhere((n) => n.id == notification.id);
    if (index < 0) return;
    final oldNotification = _notifications[index];
    final newReadStatus = !notification.read;
    _notifications[index] = notification.copyWith(read: newReadStatus);
    notifyListeners();
    try {
      if (newReadStatus) {
        await _repository.markAsRead(notification.id);
      }
    } catch (e) {
      _notifications[index] = oldNotification;
      notifyListeners();
      rethrow;
    }
  }
  List<NotificationSection> groupByDate(List<NotificationModel> notifications) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final thisWeek = today.subtract(const Duration(days: 7));
    final Map<String, List<NotificationModel>> groups = {};
    for (final notification in notifications) {
      final date = DateTime(
        notification.createdAt.year,
        notification.createdAt.month,
        notification.createdAt.day,
      );
      String label;
      if (date == today) {
        label = 'Aujourd\'hui';
      } else if (date == yesterday) {
        label = 'Hier';
      } else if (date.isAfter(thisWeek)) {
        label = 'Cette semaine';
      } else {
        label = 'Plus tôt';
      }
      groups.putIfAbsent(label, () => []).add(notification);
    }
    return groups.entries
        .map((e) => NotificationSection(label: e.key, items: e.value))
        .toList();
  }
}