import '../../../auth/data/models/user_model.dart';
import '../../domain/entities/comment_entity.dart';

class CommentModel extends CommentEntity {
  const CommentModel({
    required super.id,
    required super.text,
    super.author,
    super.createdAt,
    super.parentCommentId,
    super.replies = const [],
    super.likesCount = 0,
    super.isLiked = false,
  });

  static UserModel? _parseAuthor(Map<String, dynamic> json) {
    if (json['author'] != null && json['author'] is Map) {
      return UserModel.fromJson(Map<String, dynamic>.from(json['author']));
    }
    if (json['userId'] != null && json['userId'] is Map) {
      return UserModel.fromJson(Map<String, dynamic>.from(json['userId']));
    }
    if (json['user'] != null && json['user'] is Map) {
      return UserModel.fromJson(Map<String, dynamic>.from(json['user']));
    }

    final name = json['userName'] ??
        json['userDisplayName'] ??
        json['displayName'] ??
        json['name'] ??
        json['authorName'] ??
        json['ownerDisplayName'] ??
        (json['email'] != null && json['email'].toString().contains('@')
            ? json['email'].toString().split('@').first
            : null);

    final avatar = json['userAvatarUrl'] ??
        json['userAvatar'] ??
        json['photoURL'] ??
        json['avatarUrl'] ??
        json['avatar'] ??
        json['ownerAvatarUrl'];

    final id = json['userId']?.toString() ??
        json['authorId']?.toString() ??
        json['id']?.toString() ??
        '';

    final email = json['email']?.toString() ?? '';

    if (name != null || avatar != null || id.isNotEmpty) {
      return UserModel(
        id: id,
        email: email,
        name: name,
        avatarUrl: avatar,
      );
    }

    return null;
  }

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    List<CommentEntity> parsedReplies = [];
    if (json['replies'] != null && json['replies'] is List) {
      parsedReplies = (json['replies'] as List)
          .map((r) => CommentModel.fromJson(r as Map<String, dynamic>))
          .toList();
    }

    return CommentModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      text: json['text'] ?? json['content'] ?? '',
      author: _parseAuthor(json),
      createdAt: json['createdAt'],
      parentCommentId: json['parentCommentId']?.toString(),
      replies: parsedReplies,
      likesCount: json['likesCount'] ?? json['likes'] ?? 0,
      isLiked: json['isLiked'] ?? false,
    );
  }
}
