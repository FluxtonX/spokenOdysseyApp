import '../entities/notification_entity.dart';

abstract class NotificationsRepository {
  Future<List<NotificationEntity>> getNotifications();
  Future<int> getUnreadCount();
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead();
  Future<void> deleteNotification(String notificationId);
}
