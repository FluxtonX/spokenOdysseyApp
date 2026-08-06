import 'package:spokenodyssey/features/memories/domain/entities/memory_entity.dart';

class AlbumEntity {
  final String id;
  final String title;
  final String? description;
  final String? coverPhotoUrl;
  final int memoriesCount;
  final List<MemoryEntity> memories;
  final String? createdAt;

  const AlbumEntity({
    required this.id,
    required this.title,
    this.description,
    this.coverPhotoUrl,
    this.memoriesCount = 0,
    this.memories = const [],
    this.createdAt,
  });
}
