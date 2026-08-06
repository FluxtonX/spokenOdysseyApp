import '../../domain/entities/comment_entity.dart';
import '../../domain/entities/memory_entity.dart';
import '../../domain/repositories/memories_repository.dart';
import '../datasources/memories_remote_datasource.dart';

class MemoriesRepositoryImpl implements MemoriesRepository {
  final MemoriesRemoteDataSource remoteDataSource;

  MemoriesRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<MemoryEntity>> getFeedMemories() async {
    return await remoteDataSource.getFeedMemories();
  }

  @override
  Future<List<MemoryEntity>> getMemories({String? userId}) async {
    return await remoteDataSource.getMemories(userId: userId);
  }

  @override
  Future<MemoryEntity> getMemoryDetails(String memoryId) async {
    return await remoteDataSource.getMemoryDetails(memoryId);
  }

  @override
  Future<MemoryEntity> createMemory({
    required String title,
    String? description,
    String? mediaPath,
    String? mediaType,
    String? privacy,
    List<String>? tags,
    String? albumId,
    String? type,
    String? mood,
  }) async {
    return await remoteDataSource.createMemory(
      title: title,
      description: description,
      mediaPath: mediaPath,
      mediaType: mediaType,
      privacy: privacy,
      tags: tags,
      albumId: albumId,
      type: type,
      mood: mood,
    );
  }

  @override
  Future<MemoryEntity> updateMemory({
    required String memoryId,
    String? title,
    String? description,
    String? privacy,
    List<String>? tags,
  }) async {
    return await remoteDataSource.updateMemory(
      memoryId: memoryId,
      title: title,
      description: description,
      privacy: privacy,
      tags: tags,
    );
  }

  @override
  Future<void> deleteMemory(String memoryId) async {
    await remoteDataSource.deleteMemory(memoryId);
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
}
