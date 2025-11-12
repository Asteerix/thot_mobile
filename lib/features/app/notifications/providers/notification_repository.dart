import 'package:thot/core/utils/either.dart';
import 'package:thot/features/app/notifications/models/notification.dart';
import 'package:thot/features/app/notifications/models/notification_failure.dart';
abstract class NotificationRepository {
  Future<Either<NotificationFailure, List<NotificationModel>>>
      getNotifications();
  Future<Either<NotificationFailure, void>> markAsRead(String notificationId);
  Future<Either<NotificationFailure, void>> markAllAsRead();
  Future<Either<NotificationFailure, void>> deleteNotification(
      String notificationId);
  Stream<NotificationModel> get notificationStream;
}