import 'package:dio/dio.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/comment_model.dart';
import '../models/memory_model.dart';
import '../models/story_layer_model.dart';

abstract class MemoriesRemoteDataSource {
  Future<List<MemoryModel>> getFeedMemories();
  Future<List<MemoryModel>> getMemories({String? userId});
  Future<List<MemoryModel>> searchMemories(String query);
  Future<MemoryModel> getMemoryDetails(String memoryId);
  Future<MemoryModel> createMemory({
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
  });
  Future<MemoryModel> updateMemory({
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
  Future<List<CommentModel>> getComments(String memoryId);
  Future<CommentModel> addComment(
    String memoryId,
    String text, {
    String? parentCommentId,
  });
  Future<void> reactToComment(String memoryId, String commentId, String type);
  Future<List<StoryLayerModel>> getStoryLayers(String memoryId);
  Future<StoryLayerModel> addStoryLayer(
    String memoryId, {
    required String text,
    String? audioPath,
  });
}

class MemoriesRemoteDataSourceImpl implements MemoriesRemoteDataSource {
  final ApiClient apiClient;

  MemoriesRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<MemoryModel>> getFeedMemories() async {
    final response = await apiClient.get(ApiEndpoints.memoriesFeed);
    final data = response.data['data'] ?? response.data;
    if (data is List) {
      return data.map((json) => MemoryModel.fromJson(json)).toList();
    }
    return [];
  }

  @override
  Future<List<MemoryModel>> getMemories({String? userId}) async {
    final path = userId != null
        ? '${ApiEndpoints.memories}?userId=$userId'
        : ApiEndpoints.memories;
    final response = await apiClient.get(path);
    final data = response.data['data'] ?? response.data;
    if (data is List) {
      return data.map((json) => MemoryModel.fromJson(json)).toList();
    }
    return [];
  }

  @override
  Future<List<MemoryModel>> searchMemories(String query) async {
    final response = await apiClient.get(
      ApiEndpoints.search,
      queryParameters: {'q': query, 'type': 'memories'},
    );
    final data = response.data['data'] ?? response.data;
    if (data is Map && data['memories'] is List) {
      return (data['memories'] as List)
          .map((json) => MemoryModel.fromJson(json))
          .toList();
    }
    return [];
  }

  @override
  Future<MemoryModel> getMemoryDetails(String memoryId) async {
    final response = await apiClient.get(ApiEndpoints.memoryById(memoryId));
    final data = response.data['data'] ?? response.data;
    return MemoryModel.fromJson(data);
  }

  @override
  Future<MemoryModel> createMemory({
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
    final chosenType = type ?? 'written';

    final formDataMap = <String, dynamic>{
      'title': title,
      'status': 'published',
      'type': chosenType,
      if (description != null && description.isNotEmpty)
        'description': description,
      'privacy': (privacy != null && privacy.isNotEmpty) ? privacy : 'Public',
      'visibility': (privacy != null && privacy.isNotEmpty)
          ? privacy
          : 'Public',
      if (mood != null && mood.isNotEmpty) 'mood': mood,
      if (albumId != null && albumId.isNotEmpty) 'albumId': albumId,
      if (tags != null && tags.isNotEmpty) 'tags': tags.join(','),
      if (taggedUserIds != null && taggedUserIds.isNotEmpty)
        'taggedUserIds': taggedUserIds.join(','),
      if (occurredAt != null) 'occurredAt': occurredAt,
      if (isVaultLocked != null) 'isVaultLocked': isVaultLocked,
      if (unlockDate != null) 'unlockDate': unlockDate,
    };

    if (mediaPaths != null && mediaPaths.isNotEmpty) {
      final List<MultipartFile> files = [];
      for (final path in mediaPaths) {
        final fileName = path.split('/').last;
        files.add(await MultipartFile.fromFile(path, filename: fileName));
      }
      formDataMap['media'] = files;
    }

    final formData = FormData.fromMap(formDataMap);
    final response = await apiClient.post(
      ApiEndpoints.memories,
      data: formData,
    );

    final data = response.data['data'] ?? response.data;
    return MemoryModel.fromJson(data);
  }

  @override
  Future<MemoryModel> updateMemory({
    required String memoryId,
    String? title,
    String? description,
    String? privacy,
    List<String>? tags,
  }) async {
    final body = <String, dynamic>{
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (privacy != null) 'privacy': privacy,
      if (tags != null) 'tags': tags,
    };
    final response = await apiClient.patch(
      ApiEndpoints.memoryById(memoryId),
      data: body,
    );
    final data = response.data['data'] ?? response.data;
    return MemoryModel.fromJson(data);
  }

  @override
  Future<void> deleteMemory(String memoryId) async {
    try {
      await apiClient.delete(ApiEndpoints.memoryById(memoryId));
    } on ServerException catch (e) {
      // If the memory is already deleted or not found on the server (404), treat as success
      if (e.statusCode == 404 ||
          e.message.toLowerCase().contains('could not be found') ||
          e.message.toLowerCase().contains('not found')) {
        return;
      }
      rethrow;
    } catch (_) {
      rethrow;
    }
  }

  @override
  Future<void> reactToMemory(String memoryId, String reactionType) async {
    await apiClient.post(
      ApiEndpoints.memoryReact(memoryId),
      data: {'type': reactionType, 'reactionType': reactionType},
    );
  }

  @override
  Future<void> interactWithMemory(String memoryId, String type) async {
    await apiClient.post(
      ApiEndpoints.memoryInteract(memoryId),
      data: {'type': type},
    );
  }

  @override
  Future<void> shareMemory(String memoryId) async {
    await apiClient.post(ApiEndpoints.memoryShare(memoryId));
  }

  @override
  Future<List<CommentModel>> getComments(String memoryId) async {
    final response = await apiClient.get(ApiEndpoints.memoryComments(memoryId));
    final data = response.data['data'] ?? response.data;
    if (data is List) {
      return data.map((json) => CommentModel.fromJson(json)).toList();
    }
    return [];
  }

  @override
  Future<CommentModel> addComment(
    String memoryId,
    String text, {
    String? parentCommentId,
  }) async {
    final response = await apiClient.post(
      ApiEndpoints.memoryComments(memoryId),
      data: {
        'text': text,
        if (parentCommentId != null) 'parentCommentId': parentCommentId,
      },
    );
    final data = response.data['data'] ?? response.data;
    return CommentModel.fromJson(data);
  }

  @override
  Future<void> reactToComment(
    String memoryId,
    String commentId,
    String type,
  ) async {
    await apiClient.post(
      ApiEndpoints.commentReact(memoryId, commentId),
      data: {'type': type},
    );
  }

  @override
  Future<List<StoryLayerModel>> getStoryLayers(String memoryId) async {
    final response = await apiClient.get(ApiEndpoints.storyLayers(memoryId));
    final data = response.data['data'] ?? response.data;
    if (data is List) {
      return data.map((json) => StoryLayerModel.fromJson(json)).toList();
    }
    return [];
  }

  @override
  Future<StoryLayerModel> addStoryLayer(
    String memoryId, {
    required String text,
    String? audioPath,
  }) async {
    final body = <String, dynamic>{'text': text};
    final response = await apiClient.post(
      ApiEndpoints.storyLayers(memoryId),
      data: body,
    );
    final data = response.data['data'] ?? response.data;
    return StoryLayerModel.fromJson(data);
  }
}
