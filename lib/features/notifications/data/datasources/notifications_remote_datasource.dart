import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../models/notification_model.dart';

abstract class NotificationsRemoteDataSource {
  Future<List<NotificationModel>> getNotifications();
  Future<int> getUnreadCount();
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead();
  Future<void> deleteNotification(String notificationId);
}

class NotificationsRemoteDataSourceImpl implements NotificationsRemoteDataSource {
  final ApiClient apiClient;

  NotificationsRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<NotificationModel>> getNotifications() async {
    final response = await apiClient.get(ApiEndpoints.notifications);
    final data = response.data['data'] ?? response.data;
    if (data is List) {
      return data.map((json) => NotificationModel.fromJson(json)).toList();
    }
    return [];
  }

  @override
  Future<int> getUnreadCount() async {
    try {
      final response = await apiClient.get(ApiEndpoints.notificationsUnreadCount);
      final data = response.data['data'] ?? response.data;
      if (data is Map) {
        return data['count'] ?? data['unreadCount'] ?? 0;
      }
      if (data is int) return data;
      return 0;
    } catch (_) {
      return 0;
    }
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    await apiClient.patch(ApiEndpoints.notificationRead(notificationId));
  }

  @override
  Future<void> markAllAsRead() async {
    await apiClient.patch(ApiEndpoints.notificationsReadAll);
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    await apiClient.delete(ApiEndpoints.notificationDelete(notificationId));
  }
}
