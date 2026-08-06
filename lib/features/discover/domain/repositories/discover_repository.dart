import 'package:spokenodyssey/features/albums/domain/entities/album_entity.dart';
import 'package:spokenodyssey/features/auth/domain/entities/user.dart';
import 'package:spokenodyssey/features/memories/domain/entities/memory_entity.dart';

class SearchResultsEntity {
  final List<MemoryEntity> memories;
  final List<AlbumEntity> albums;
  final List<User> users;

  const SearchResultsEntity({
    this.memories = const [],
    this.albums = const [],
    this.users = const [],
  });
}

abstract class DiscoverRepository {
  Future<List<MemoryEntity>> getDiscoveryMemories({
    String? filter,
    String? theme,
    String? query,
  });
  Future<SearchResultsEntity> search(String query, {String type = 'all'});
  Future<List<User>> getSuggestedPeople();
  Future<List<User>> getFeaturedPeople({String? category, String? query});
  Future<void> followUser(String targetUid);
  Future<void> unfollowUser(String targetUid);
}
