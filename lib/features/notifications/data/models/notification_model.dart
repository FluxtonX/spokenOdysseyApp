import '../../../auth/data/models/user_model.dart';
import '../../domain/entities/notification_entity.dart';

class NotificationModel extends NotificationEntity {
  const NotificationModel({
    required super.id,
    required super.title,
    required super.message,
    super.type,
    super.isRead = false,
    super.sender,
    super.targetId,
    super.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    UserModel? parsedSender;
    if (json['sender'] != null && json['sender'] is Map) {
      parsedSender = UserModel.fromJson(Map<String, dynamic>.from(json['sender']));
    } else if (json['metadata'] != null && json['metadata'] is Map) {
      final meta = json['metadata'] as Map;
      if (meta['senderName'] != null || meta['senderAvatarUrl'] != null || meta['senderId'] != null) {
        parsedSender = UserModel(
          id: meta['senderId']?.toString() ?? '',
          email: meta['senderEmail']?.toString() ?? '',
          name: meta['senderName']?.toString() ?? 'Spoken Odyssey User',
          avatarUrl: meta['senderAvatarUrl']?.toString(),
        );
      }
    }

    return NotificationModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title'] ?? 'Notification',
      message: json['message'] ?? json['content'] ?? '',
      type: json['type'],
      isRead: json['isRead'] ?? json['read'] ?? false,
      sender: parsedSender,
      targetId: json['targetId']?.toString() ??
          json['memoryId']?.toString() ??
          json['metadata']?['memoryId']?.toString() ??
          json['actionUrl']?.toString(),
      createdAt: json['createdAt']?.toString() ?? json['date']?.toString(),
    );
  }
}
