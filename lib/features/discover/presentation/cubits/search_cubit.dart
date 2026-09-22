import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/exceptions.dart';
import '../../../albums/domain/entities/album_entity.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../memories/domain/entities/memory_entity.dart';
import '../../domain/repositories/discover_repository.dart';

// ── States ────────────────────────────────────────────────────────────────────

abstract class SearchState {}

class SearchInitial extends SearchState {}

class SearchLoading extends SearchState {}

class SearchLoaded extends SearchState {
  final List<MemoryEntity> memories;
  final List<AlbumEntity> albums;
  final List<User> people;
  final String query;
  final String activeTab; // 'All' | 'Memories' | 'Albums' | 'People'

  SearchLoaded({
    required this.memories,
    required this.albums,
    required this.people,
    required this.query,
    this.activeTab = 'All',
  });

  int get totalCount => memories.length + albums.length + people.length;

  SearchLoaded copyWith({
    List<MemoryEntity>? memories,
    List<AlbumEntity>? albums,
    List<User>? people,
    String? query,
    String? activeTab,
  }) {
    return SearchLoaded(
      memories: memories ?? this.memories,
      albums: albums ?? this.albums,
      people: people ?? this.people,
      query: query ?? this.query,
      activeTab: activeTab ?? this.activeTab,
    );
  }
}

class SearchError extends SearchState {
  final String message;
  SearchError(this.message);
}

// ── Cubit ─────────────────────────────────────────────────────────────────────

class SearchCubit extends Cubit<SearchState> {
  final DiscoverRepository _repository;
  Timer? _debounce;

  SearchCubit({required DiscoverRepository repository})
    : _repository = repository,
      super(SearchInitial());

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }

  /// Debounced search — waits 350ms before hitting the API.
  void search(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      emit(SearchInitial());
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _executeSearch(query.trim());
    });
  }

  Future<void> _executeSearch(String query) async {
    try {
      // Keep previous results visible while searching
      if (state is! SearchLoaded) emit(SearchLoading());
      final results = await _repository.search(query);
      if (!isClosed) {
        final currentTab = state is SearchLoaded
            ? (state as SearchLoaded).activeTab
            : 'All';
        emit(
          SearchLoaded(
            memories: results.memories,
            albums: results.albums,
            people: results.users,
            query: query,
            activeTab: currentTab,
          ),
        );
      }
    } catch (e) {
      if (!isClosed) emit(SearchError(ErrorParser.extractMessage(e)));
    }
  }

  void setTab(String tab) {
    if (state is SearchLoaded) {
      emit((state as SearchLoaded).copyWith(activeTab: tab));
    }
  }

  Future<void> toggleFollow(User user) async {
    if (state is! SearchLoaded) return;
    final loaded = state as SearchLoaded;
    try {
      final isFollowing = user.isFollowing;
      // Optimistic update
      final updatedPeople = loaded.people.map((u) {
        if (u.id == user.id) {
          return User(
            id: u.id,
            email: u.email,
            name: u.name,
            avatarUrl: u.avatarUrl,
            bio: u.bio,
            location: u.location,
            relationship: u.relationship,
            dateOfBirth: u.dateOfBirth,
            firebaseUid: u.firebaseUid,
            memoriesCount: u.memoriesCount,
            albumsCount: u.albumsCount,
            followersCount: u.followersCount,
            followingCount: u.followingCount,
            familyCount: u.familyCount,
            isFollowing: !isFollowing,
          );
        }
        return u;
      }).toList();
      emit(loaded.copyWith(people: updatedPeople));

      if (isFollowing) {
        await _repository.unfollowUser(user.firebaseUid ?? user.id);
      } else {
        await _repository.followUser(user.firebaseUid ?? user.id);
      }
    } catch (_) {
      // Revert by re-emitting with original list
      emit(loaded);
    }
  }
}
