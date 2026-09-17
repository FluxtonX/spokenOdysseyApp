import '../../../../core/network/cache_manager.dart';
import '../../domain/entities/comment_entity.dart';
import '../../domain/entities/memory_entity.dart';
import '../../domain/entities/story_layer_entity.dart';
import '../../domain/repositories/memories_repository.dart';
import '../datasources/memories_remote_datasource.dart';

class MemoriesRepositoryImpl implements MemoriesRepository {
  final MemoriesRemoteDataSource remoteDataSource;

  MemoriesRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<MemoryEntity>> getFeedMemories() async {
    const key = 'memories_feed';
    final cached = CacheManager().get<List<MemoryEntity>>(
      key,
      ttl: const Duration(minutes: 3),
    );
    if (cached != null) return cached;

    final memories = await remoteDataSource.getFeedMemories();
    CacheManager().set(key, memories);
    return memories;
  }

  @override
  Future<List<MemoryEntity>> getMemories({String? userId}) async {
    final key = 'memories_list_${userId ?? "all"}';
    final cached = CacheManager().get<List<MemoryEntity>>(
      key,
      ttl: const Duration(minutes: 3),
    );
    if (cached != null) return cached;

    final memories = await remoteDataSource.getMemories(userId: userId);
    CacheManager().set(key, memories);
    return memories;
  }

  @override
  Future<List<MemoryEntity>> searchMemories(String query) async {
    return await remoteDataSource.searchMemories(query);
  }

  @override
  Future<MemoryEntity> getMemoryDetails(String memoryId) async {
    return await remoteDataSource.getMemoryDetails(memoryId);
  }

  @override
  Future<MemoryEntity> createMemory({
    required String title,
    String? description,
    List<String>? mediaPaths,
    String? privacy,
    List<String>? tags,
    List<String>? taggedUserIds,
    String? albumId,
    String? type,
    String? mood,
    String? occurredAt,
    bool? isVaultLocked,
    String? unlockDate,
  }) async {
    final result = await remoteDataSource.createMemory(
      title: title,
      description: description,
      mediaPaths: mediaPaths,
      privacy: privacy,
      tags: tags,
      taggedUserIds: taggedUserIds,
      albumId: albumId,
      type: type,
      mood: mood,
      occurredAt: occurredAt,
      isVaultLocked: isVaultLocked,
      unlockDate: unlockDate,
    );
    CacheManager().invalidate('memories_');
    return result;
  }

  @override
  Future<MemoryEntity> updateMemory({
    required String memoryId,
    String? title,
    String? description,
    String? privacy,
    List<String>? tags,
  }) async {
    final result = await remoteDataSource.updateMemory(
      memoryId: memoryId,
      title: title,
      description: description,
      privacy: privacy,
      tags: tags,
    );
    CacheManager().invalidate('memories_');
    return result;
  }

  @override
  Future<void> deleteMemory(String memoryId) async {
    await remoteDataSource.deleteMemory(memoryId);
    CacheManager().invalidate('memories_');
  }

  @override
  Future<void> reactToMemory(String memoryId, String reactionType) async {
    await remoteDataSource.reactToMemory(memoryId, reactionType);
  }

  @override
  Future<void> interactWithMemory(String memoryId, String type) async {
    await remoteDataSource.interactWithMemory(memoryId, type);
  }

  @override
  Future<void> shareMemory(String memoryId) async {
    await remoteDataSource.shareMemory(memoryId);
  }

  @override
  Future<List<CommentEntity>> getComments(String memoryId) async {
    return await remoteDataSource.getComments(memoryId);
  }

  @override
  Future<CommentEntity> addComment(
    String memoryId,
    String text, {
    String? parentCommentId,
  }) async {
    return await remoteDataSource.addComment(
      memoryId,
      text,
      parentCommentId: parentCommentId,
    );
  }

  @override
  Future<void> reactToComment(
    String memoryId,
    String commentId,
    String type,
  ) async {
    await remoteDataSource.reactToComment(memoryId, commentId, type);
  }

  @override
  Future<List<StoryLayerEntity>> getStoryLayers(String memoryId) async {
    return await remoteDataSource.getStoryLayers(memoryId);
  }

  @override
  Future<StoryLayerEntity> addStoryLayer(
    String memoryId, {
    required String text,
    String? audioPath,
  }) async {
    return await remoteDataSource.addStoryLayer(
      memoryId,
      text: text,
      audioPath: audioPath,
    );
  }
}
