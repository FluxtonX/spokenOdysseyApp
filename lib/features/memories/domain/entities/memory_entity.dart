import 'package:spokenodyssey/features/auth/domain/entities/user.dart';

class MemoryEntity {
  final String id;
  final String title;
  final String? description;
  final String? mediaUrl;
  final String? mediaType; // 'audio', 'image', 'video'
  final String? privacy; // 'private', 'family', 'public'
  final List<String> tags;
  final String? albumId;
  final String? albumTitle;
  final User? author;
  final String? createdAt;
  final int viewsCount;
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final Map<String, int> reactionCounts;
  final String? userReaction;

  const MemoryEntity({
    required this.id,
    required this.title,
    this.description,
    this.mediaUrl,
    this.mediaType,
    this.privacy,
    this.tags = const [],
    this.albumId,
    this.albumTitle,
    this.author,
    this.createdAt,
    this.viewsCount = 0,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.sharesCount = 0,
    this.reactionCounts = const {},
    this.userReaction,
  });
}
