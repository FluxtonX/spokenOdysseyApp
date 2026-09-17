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
    super.actionUrl,
    super.metadata,
    super.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    UserModel? parsedSender;
    Map<String, dynamic>? metaMap;
    if (json['metadata'] != null && json['metadata'] is Map) {
      metaMap = Map<String, dynamic>.from(json['metadata']);
    }

    if (json['sender'] != null && json['sender'] is Map) {
      parsedSender = UserModel.fromJson(Map<String, dynamic>.from(json['sender']));
    } else if (metaMap != null) {
      if (metaMap['senderName'] != null || metaMap['senderAvatarUrl'] != null || metaMap['senderId'] != null) {
        parsedSender = UserModel(
          id: metaMap['senderId']?.toString() ?? '',
          email: metaMap['senderEmail']?.toString() ?? '',
          name: metaMap['senderName']?.toString() ?? 'Spoken Odyssey User',
          avatarUrl: metaMap['senderAvatarUrl']?.toString(),
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
          metaMap?['memoryId']?.toString() ??
          metaMap?['invitationId']?.toString() ??
          json['actionUrl']?.toString(),
      actionUrl: json['actionUrl']?.toString(),
      metadata: metaMap,
      createdAt: json['createdAt']?.toString() ?? json['date']?.toString(),
    );
  }
}
