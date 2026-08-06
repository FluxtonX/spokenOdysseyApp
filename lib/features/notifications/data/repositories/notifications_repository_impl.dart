import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../datasources/notifications_remote_datasource.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  final NotificationsRemoteDataSource remoteDataSource;

  NotificationsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<NotificationEntity>> getNotifications() async {
    return await remoteDataSource.getNotifications();
  }

  @override
  Future<int> getUnreadCount() async {
    return await remoteDataSource.getUnreadCount();
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    await remoteDataSource.markAsRead(notificationId);
  }

  @override
  Future<void> markAllAsRead() async {
    await remoteDataSource.markAllAsRead();
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    await remoteDataSource.deleteNotification(notificationId);
  }
}
