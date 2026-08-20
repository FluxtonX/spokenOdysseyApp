import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../memories/data/models/memory_model.dart';
import '../../../memories/domain/entities/memory_entity.dart';
import '../../../albums/data/models/album_model.dart';
import '../../../albums/domain/entities/album_entity.dart';
import '../../domain/repositories/discover_repository.dart';

abstract class DiscoverRemoteDataSource {
  Future<List<MemoryModel>> getDiscoveryMemories({
    String? filter,
    String? theme,
    String? query,
  });
  Future<SearchResultsEntity> search(String query, {String type = 'all'});
  Future<List<UserModel>> getSuggestedPeople();
  Future<List<UserModel>> getFeaturedPeople({String? category, String? query});
  Future<List<UserModel>> getFollowers();
  Future<void> followUser(String targetUid);
  Future<void> unfollowUser(String targetUid);
}

class DiscoverRemoteDataSourceImpl implements DiscoverRemoteDataSource {
  final ApiClient apiClient;

  DiscoverRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<MemoryModel>> getDiscoveryMemories({
    String? filter,
    String? theme,
    String? query,
  }) async {
    final queryParams = <String, String>{
      if (filter != null) 'filter': filter,
      if (theme != null) 'theme': theme,
      if (query != null) 'q': query,
    };
    final response = await apiClient.get(
      ApiEndpoints.memoriesDiscovery,
      queryParameters: queryParams,
    );
    final data = response.data['data'] ?? response.data;
    if (data is List) {
      return data.map((json) => MemoryModel.fromJson(json)).toList();
    }
    return [];
  }

  @override
  Future<SearchResultsEntity> search(String query, {String type = 'all'}) async {
    final response = await apiClient.get(
      ApiEndpoints.search,
      queryParameters: {'q': query, 'type': type},
    );
    final data = response.data['data'] ?? response.data;
    List<MemoryEntity> memories = [];
    List<AlbumEntity> albums = [];
    List<User> users = [];

    if (data is Map) {
      if (data['memories'] is List) {
        memories = (data['memories'] as List).map((m) => MemoryModel.fromJson(m)).toList();
      }
      if (data['albums'] is List) {
        albums = (data['albums'] as List).map((a) => AlbumModel.fromJson(a)).toList();
      }
      if (data['users'] is List) {
        users = (data['users'] as List).map((u) => UserModel.fromJson(u)).toList();
      }
    }
    return SearchResultsEntity(memories: memories, albums: albums, users: users);
  }

  @override
  Future<List<UserModel>> getSuggestedPeople() async {
    final response = await apiClient.get(ApiEndpoints.usersDiscovery);
    final data = response.data['data'] ?? response.data;
    if (data is List) {
      return data.map((json) => UserModel.fromJson(json)).toList();
    }
    return [];
  }

  @override
  Future<List<UserModel>> getFeaturedPeople({String? category, String? query}) async {
    final response = await apiClient.get(
      ApiEndpoints.usersFeatured,
      queryParameters: {
        if (category != null) 'category': category,
        if (query != null) 'q': query,
      },
    );
    final data = response.data['data'] ?? response.data;
    if (data is List) {
      return data.map((json) => UserModel.fromJson(json)).toList();
    }
    return [];
  }

  @override
  Future<List<UserModel>> getFollowers() async {
    final response = await apiClient.get(ApiEndpoints.followers);
    final data = response.data['data'] ?? response.data;
    if (data is List) {
      return data.map((json) => UserModel.fromJson(json)).toList();
    }
    return [];
  }

  @override
  Future<void> followUser(String targetUid) async {
    await apiClient.post(ApiEndpoints.followUser(targetUid));
  }

  @override
  Future<void> unfollowUser(String targetUid) async {
    await apiClient.delete(ApiEndpoints.followUser(targetUid));
  }
}
