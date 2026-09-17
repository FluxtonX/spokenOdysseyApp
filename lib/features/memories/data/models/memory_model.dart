import '../../../auth/data/models/user_model.dart';
import '../../domain/entities/memory_entity.dart';

class MemoryModel extends MemoryEntity {
  const MemoryModel({
    required super.id,
    required super.title,
    super.description,
    super.mediaUrl,
    super.mediaType,
    super.privacy,
    super.tags = const [],
    super.albumId,
    super.albumTitle,
    super.author,
    super.createdAt,
    super.viewsCount = 0,
    super.likesCount = 0,
    super.commentsCount = 0,
    super.sharesCount = 0,
    super.reactionCounts = const {},
    super.userReaction,
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
    if (json['owner'] != null && json['owner'] is Map) {
      return UserModel.fromJson(Map<String, dynamic>.from(json['owner']));
    }

    final name = json['ownerDisplayName'] ??
        json['ownerName'] ??
        json['userDisplayName'] ??
        json['userName'] ??
        json['authorName'] ??
        json['creatorName'] ??
        (json['ownerEmail'] != null && json['ownerEmail'].toString().contains('@')
            ? json['ownerEmail'].toString().split('@').first
            : null);

    final avatar = json['ownerAvatarUrl'] ??
        json['userAvatarUrl'] ??
        json['authorAvatarUrl'] ??
        json['ownerPhoto'] ??
        json['userAvatar'] ??
        json['avatarUrl'] ??
        json['avatar'];

    final id = json['ownerId']?.toString() ??
        json['userId']?.toString() ??
        json['authorId']?.toString() ??
        '';

    final email = json['ownerEmail']?.toString() ?? '';

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

  factory MemoryModel.fromJson(Map<String, dynamic> json) {
    Map<String, int> reactions = {};
    if (json['reactionCounts'] != null && json['reactionCounts'] is Map) {
      (json['reactionCounts'] as Map).forEach((key, value) {
        reactions[key.toString()] = int.tryParse(value.toString()) ?? 0;
      });
    }

    // Resolve mediaUrl
    String? resolvedMediaUrl = json['audioUrl']?.toString() ??
        json['mediaUrl']?.toString() ??
        json['fileUrl']?.toString() ??
        json['media']?.toString();

    if (resolvedMediaUrl == null && json['mediaList'] is List && (json['mediaList'] as List).isNotEmpty) {
      final first = (json['mediaList'] as List).first;
      if (first is Map) {
        resolvedMediaUrl = first['mediaUrl']?.toString() ?? first['url']?.toString();
      }
    }

    // Resolve mediaType
    String resolvedMediaType = 'text';
    final rawType = (json['mediaType'] ?? json['type'] ?? '').toString().toLowerCase();
    final rawMime = (json['mediaMimeType'] ?? '').toString().toLowerCase();
    final rawTitle = (json['title'] ?? '').toString().toLowerCase();
    final rawDesc = (json['description'] ?? '').toString().toLowerCase();
    final urlLower = (resolvedMediaUrl ?? '').toLowerCase();

    if (rawType.contains('audio') ||
        rawType.contains('voice') ||
        rawMime.contains('audio') ||
        urlLower.contains('.mp3') ||
        urlLower.contains('.m4a') ||
        urlLower.contains('.wav') ||
        urlLower.contains('.aac') ||
        rawTitle.contains('voice recording') ||
        rawTitle.contains('audio') ||
        rawDesc.contains('audio story')) {
      resolvedMediaType = 'audio';
    } else if (rawType.contains('video') ||
        rawMime.contains('video') ||
        urlLower.contains('.mp4') ||
        urlLower.contains('.mov') ||
        urlLower.contains('.webm')) {
      resolvedMediaType = 'video';
    } else if (rawType.contains('image') ||
        rawType.contains('photo') ||
        rawMime.contains('image') ||
        urlLower.contains('.jpg') ||
        urlLower.contains('.jpeg') ||
        urlLower.contains('.png') ||
        urlLower.contains('.webp') ||
        urlLower.contains('.gif') ||
        (resolvedMediaUrl != null && resolvedMediaUrl.isNotEmpty)) {
      resolvedMediaType = 'image';
    }

    return MemoryModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title'] ?? 'Untitled Memory',
      description: json['description'],
      mediaUrl: resolvedMediaUrl,
      mediaType: resolvedMediaType,
      privacy: json['privacy'] ?? json['visibility'] ?? 'public',
      tags: json['tags'] != null ? List<String>.from(json['tags']) : const [],
      albumId: json['albumId']?.toString() ?? json['album']?['_id']?.toString(),
      albumTitle: json['album']?['title'],
      author: _parseAuthor(json),
      createdAt: json['createdAt'] ?? json['date'],
      viewsCount: json['viewsCount'] ?? json['views'] ?? 0,
      likesCount: json['likesCount'] ?? json['likes'] ?? 0,
      commentsCount: json['commentsCount'] ?? json['comments'] ?? 0,
      sharesCount: json['sharesCount'] ?? json['shares'] ?? 0,
      reactionCounts: reactions,
      userReaction: json['userReaction'],
    );
  }
}
