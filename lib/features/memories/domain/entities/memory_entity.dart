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

  MemoryEntity copyWith({
    String? id,
    String? title,
    String? description,
    String? mediaUrl,
    String? mediaType,
    String? privacy,
    List<String>? tags,
    String? albumId,
    String? albumTitle,
    User? author,
    String? createdAt,
    int? viewsCount,
    int? likesCount,
    int? commentsCount,
    int? sharesCount,
    Map<String, int>? reactionCounts,
    String? userReaction,
    bool clearUserReaction = false,
  }) {
    return MemoryEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaType: mediaType ?? this.mediaType,
      privacy: privacy ?? this.privacy,
      tags: tags ?? this.tags,
      albumId: albumId ?? this.albumId,
      albumTitle: albumTitle ?? this.albumTitle,
      author: author ?? this.author,
      createdAt: createdAt ?? this.createdAt,
      viewsCount: viewsCount ?? this.viewsCount,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      sharesCount: sharesCount ?? this.sharesCount,
      reactionCounts: reactionCounts ?? this.reactionCounts,
      userReaction: clearUserReaction ? null : (userReaction ?? this.userReaction),
    );
  }
}
