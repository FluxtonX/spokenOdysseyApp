import '../../../auth/domain/entities/user.dart';
import '../../../memories/domain/entities/memory_entity.dart';
import '../../domain/repositories/discover_repository.dart';
import '../datasources/discover_remote_datasource.dart';

class DiscoverRepositoryImpl implements DiscoverRepository {
  final DiscoverRemoteDataSource remoteDataSource;

  DiscoverRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<MemoryEntity>> getDiscoveryMemories({
    String? filter,
    String? theme,
    String? query,
  }) async {
    return await remoteDataSource.getDiscoveryMemories(
      filter: filter,
      theme: theme,
      query: query,
    );
  }

  @override
  Future<SearchResultsEntity> search(String query, {String type = 'all'}) async {
    return await remoteDataSource.search(query, type: type);
  }

  @override
  Future<List<User>> getSuggestedPeople() async {
    return await remoteDataSource.getSuggestedPeople();
  }

  @override
  Future<List<User>> getFeaturedPeople({String? category, String? query}) async {
    return await remoteDataSource.getFeaturedPeople(category: category, query: query);
  }

  @override
  Future<List<User>> getFollowers() async {
    return await remoteDataSource.getFollowers();
  }

  @override
  Future<void> followUser(String targetUid) async {
    await remoteDataSource.followUser(targetUid);
  }

  @override
  Future<void> unfollowUser(String targetUid) async {
    await remoteDataSource.unfollowUser(targetUid);
  }
}
