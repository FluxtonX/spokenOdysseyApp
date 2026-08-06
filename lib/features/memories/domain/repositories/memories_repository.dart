import '../entities/comment_entity.dart';
import '../entities/memory_entity.dart';

abstract class MemoriesRepository {
  Future<List<MemoryEntity>> getFeedMemories();
  Future<List<MemoryEntity>> getMemories({String? userId});
  Future<MemoryEntity> getMemoryDetails(String memoryId);
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
  });
  Future<MemoryEntity> updateMemory({
    required String memoryId,
    String? title,
    String? description,
    String? privacy,
    List<String>? tags,
  });
  Future<void> deleteMemory(String memoryId);
  Future<void> reactToMemory(String memoryId, String reactionType);
  Future<void> interactWithMemory(String memoryId, String type);
  Future<void> shareMemory(String memoryId);
  Future<List<CommentEntity>> getComments(String memoryId);
  Future<CommentEntity> addComment(
    String memoryId,
    String text, {
    String? parentCommentId,
  });
  Future<void> reactToComment(String memoryId, String commentId, String type);
}
