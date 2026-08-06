import 'package:spokenodyssey/features/memories/data/models/memory_model.dart';
import 'package:spokenodyssey/features/memories/domain/entities/memory_entity.dart';

import '../../domain/entities/album_entity.dart';

class AlbumModel extends AlbumEntity {
  const AlbumModel({
    required super.id,
    required super.title,
    super.description,
    super.coverPhotoUrl,
    super.memoriesCount = 0,
    super.memories = const [],
    super.createdAt,
  });

  factory AlbumModel.fromJson(Map<String, dynamic> json) {
    List<MemoryEntity> albumMemories = [];
    if (json['memories'] != null && json['memories'] is List) {
      albumMemories = (json['memories'] as List)
          .map((m) => MemoryModel.fromJson(m as Map<String, dynamic>))
          .toList();
    }

    return AlbumModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title'] ?? 'Untitled Album',
      description: json['description'] ?? json['subtitle'],
      coverPhotoUrl: json['coverImageUrl'] ??
          json['coverImageKey'] ??
          json['coverPhotoUrl'] ??
          json['coverPhoto'] ??
          json['coverUrl'],
      memoriesCount: json['memoriesCount'] ?? json['entries'] ?? albumMemories.length,
      memories: albumMemories,
      createdAt: json['createdAt'],
    );
  }
}
