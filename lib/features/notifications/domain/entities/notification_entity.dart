import 'package:spokenodyssey/features/auth/domain/entities/user.dart';

class NotificationEntity {
  final String id;
  final String title;
  final String message;
  final String?
  type; // 'memory_like', 'memory_comment', 'family_invite', 'system'
  final bool isRead;
  final User? sender;
  final String? targetId;
  final String? createdAt;

  const NotificationEntity({
    required this.id,
    required this.title,
    required this.message,
    this.type,
    this.isRead = false,
    this.sender,
    this.targetId,
    this.createdAt,
  });
}
