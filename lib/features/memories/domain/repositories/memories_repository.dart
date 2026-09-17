import '../entities/comment_entity.dart';
import '../entities/memory_entity.dart';
import '../entities/story_layer_entity.dart';

abstract class MemoriesRepository {
  Future<List<MemoryEntity>> getFeedMemories();
  Future<List<MemoryEntity>> getMemories({String? userId});
  Future<List<MemoryEntity>> searchMemories(String query);
  Future<MemoryEntity> getMemoryDetails(String memoryId);
  Future<MemoryEntity> createMemory({
    required String title,
    String? description,
    List<String>? mediaPaths, // Changed to support multiple files
    String? privacy,
    List<String>? tags,
    List<String>? taggedUserIds,
    String? albumId,
    String? type,
    String? mood,
    String? occurredAt,
    bool? isVaultLocked,
    String? unlockDate,
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
  Future<List<StoryLayerEntity>> getStoryLayers(String memoryId);
  Future<StoryLayerEntity> addStoryLayer(
    String memoryId, {
    required String text,
    String? audioPath,
  });
}
