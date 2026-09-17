import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/exceptions.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../memories/domain/entities/memory_entity.dart';
import '../../domain/repositories/discover_repository.dart';

abstract class DiscoverState {}

class DiscoverInitial extends DiscoverState {}

class DiscoverLoading extends DiscoverState {}

class DiscoverLoaded extends DiscoverState {
  final List<MemoryEntity> memories;
  final List<User> suggestedPeople;
  final List<User> featuredPeople;
  final String selectedCategory;
  final SearchResultsEntity? searchResults;
  final String? actionError;

  DiscoverLoaded({
    required this.memories,
    required this.suggestedPeople,
    this.featuredPeople = const [],
    this.selectedCategory = 'All',
    this.searchResults,
    this.actionError,
  });

  DiscoverLoaded copyWith({
    List<MemoryEntity>? memories,
    List<User>? suggestedPeople,
    List<User>? featuredPeople,
    String? selectedCategory,
    SearchResultsEntity? searchResults,
    String? actionError,
    bool clearError = false,
  }) {
    return DiscoverLoaded(
      memories: memories ?? this.memories,
      suggestedPeople: suggestedPeople ?? this.suggestedPeople,
      featuredPeople: featuredPeople ?? this.featuredPeople,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchResults: searchResults ?? this.searchResults,
      actionError: clearError ? null : (actionError ?? this.actionError),
    );
  }
}

class DiscoverError extends DiscoverState {
  final String message;
  DiscoverError(this.message);
}

class DiscoverCubit extends Cubit<DiscoverState> {
  final DiscoverRepository repository;

  DiscoverCubit({required this.repository}) : super(DiscoverInitial());

  void _emitError(dynamic e) {
    if (state is DiscoverLoaded) {
      emit(
        (state as DiscoverLoaded).copyWith(
          actionError: ErrorParser.extractMessage(e),
        ),
      );
    } else {
      emit(DiscoverError(ErrorParser.extractMessage(e)));
    }
  }

  Future<void> loadDiscovery({String category = 'All'}) async {
    try {
      emit(DiscoverLoading());
      final memories = await repository.getDiscoveryMemories(
        filter: category == 'All' ? null : category,
      );

      List<User> featured = [];
      try {
        featured = await repository.getFeaturedPeople(
          category: category == 'All' ? null : category,
        );
      } catch (_) {}

      final suggested = await repository.getSuggestedPeople();
      final finalPeople = featured.isNotEmpty ? featured : suggested;

      emit(
        DiscoverLoaded(
          memories: memories,
          suggestedPeople: suggested,
          featuredPeople: finalPeople,
          selectedCategory: category,
        ),
      );
    } catch (e) {
      emit(DiscoverError(ErrorParser.extractMessage(e)));
    }
  }

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      await loadDiscovery();
      return;
    }

    try {
      emit(DiscoverLoading());
      final results = await repository.search(query);
      final suggested = await repository.getSuggestedPeople();

      emit(
        DiscoverLoaded(
          memories: results.memories,
          suggestedPeople: suggested,
          featuredPeople: results.users.isNotEmpty ? results.users : suggested,
          searchResults: results,
        ),
      );
    } catch (e) {
      emit(DiscoverError(ErrorParser.extractMessage(e)));
    }
  }

  Future<void> toggleFollow(String targetUid, bool currentlyFollowing) async {
    // ── Optimistic state update ──────────────────────────────────────────
    if (state is DiscoverLoaded) {
      final current = state as DiscoverLoaded;
      final updatedFeatured = current.featuredPeople.map((u) {
        if (u.id == targetUid || u.firebaseUid == targetUid) {
          final newCount = currentlyFollowing
              ? (u.followersCount > 0 ? u.followersCount - 1 : 0)
              : u.followersCount + 1;
          return User(
            id: u.id,
            email: u.email,
            name: u.name,
            avatarUrl: u.avatarUrl,
            coverUrl: u.coverUrl,
            bio: u.bio,
            profession: u.profession,
            location: u.location,
            relationship: u.relationship,
            dateOfBirth: u.dateOfBirth,
            birthDate: u.birthDate,
            expertise: u.expertise,
            lifeMotto: u.lifeMotto,
            firebaseUid: u.firebaseUid,
            memoriesCount: u.memoriesCount,
            albumsCount: u.albumsCount,
            followersCount: newCount,
            followingCount: u.followingCount,
            familyCount: u.familyCount,
            isFollowing: !currentlyFollowing,
          );
        }
        return u;
      }).toList();

      emit(current.copyWith(featuredPeople: updatedFeatured));
    }

    try {
      if (currentlyFollowing) {
        await repository.unfollowUser(targetUid);
      } else {
        await repository.followUser(targetUid);
      }
    } catch (e) {
      _emitError(e);
      // Revert if error
      if (state is DiscoverLoaded) {
        final current = state as DiscoverLoaded;
        await loadDiscovery(category: current.selectedCategory);
      }
    }
  }
}
