import 'package:spokenodyssey/features/auth/domain/entities/user.dart';

class CommentEntity {
  final String id;
  final String text;
  final User? author;
  final String? createdAt;
  final String? parentCommentId;
  final List<CommentEntity> replies;
  final int likesCount;
  final bool isLiked;

  const CommentEntity({
    required this.id,
    required this.text,
    this.author,
    this.createdAt,
    this.parentCommentId,
    this.replies = const [],
    this.likesCount = 0,
    this.isLiked = false,
  });
}
