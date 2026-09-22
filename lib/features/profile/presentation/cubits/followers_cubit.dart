import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spokenodyssey/features/auth/domain/entities/user.dart';
import 'package:spokenodyssey/features/discover/domain/repositories/discover_repository.dart';
import 'followers_state.dart';

class FollowersCubit extends Cubit<FollowersState> {
  final DiscoverRepository _discoverRepository;

  FollowersCubit({required DiscoverRepository discoverRepository})
    : _discoverRepository = discoverRepository,
      super(FollowersInitial());

  Future<void> loadFollowers() async {
    emit(FollowersLoading());
    try {
      final results = await Future.wait([
        _discoverRepository.getFollowers().catchError((_) => <User>[]),
        _discoverRepository.getFollowing().catchError((_) => <User>[]),
        _discoverRepository.getSuggestedPeople().catchError((_) => <User>[]),
      ]);

      final followers = results[0];
      final following = results[1];
      final suggestions = results[2];

      emit(
        FollowersLoaded(
          followers: followers,
          following: following,
          suggestions: suggestions,
          searchResults: followers,
          selectedTab: 'followers',
        ),
      );
    } catch (e) {
      emit(FollowersError(e.toString()));
    }
  }

  void setTab(String tab) {
    final currentState = state;
    if (currentState is FollowersLoaded) {
      final targetList = tab == 'following'
          ? currentState.following
          : currentState.followers;
      emit(
        currentState.copyWith(
          selectedTab: tab,
          searchResults: targetList,
          searchQuery: '',
        ),
      );
    }
  }

  void searchFollowers(String query) {
    final currentState = state;
    if (currentState is FollowersLoaded) {
      final currentList = currentState.selectedTab == 'following'
          ? currentState.following
          : currentState.followers;

      if (query.isEmpty) {
        emit(
          currentState.copyWith(searchResults: currentList, searchQuery: query),
        );
      } else {
        final searchLower = query.toLowerCase();
        final results = currentList.where((user) {
          final nameMatch =
              user.name?.toLowerCase().contains(searchLower) ?? false;
          final emailMatch = user.email.toLowerCase().contains(searchLower);
          return nameMatch || emailMatch;
        }).toList();

        emit(currentState.copyWith(searchResults: results, searchQuery: query));
      }
    }
  }

  Future<void> toggleFollow(User user) async {
    final currentState = state;
    if (currentState is FollowersLoaded) {
      try {
        final isCurrentlyFollowing = user.isFollowing;

        User updateUser(User u) {
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
              isFollowing: !isCurrentlyFollowing,
            );
          }
          return u;
        }

        final updatedFollowers = currentState.followers
            .map(updateUser)
            .toList();
        final updatedFollowing = currentState.following
            .map(updateUser)
            .toList();
        final updatedSuggestions = currentState.suggestions
            .map(updateUser)
            .toList();
        final updatedSearchResults = currentState.searchResults
            .map(updateUser)
            .toList();

        emit(
          currentState.copyWith(
            followers: updatedFollowers,
            following: updatedFollowing,
            suggestions: updatedSuggestions,
            searchResults: updatedSearchResults,
          ),
        );

        // API Call
        final targetId = user.firebaseUid ?? user.id;
        if (isCurrentlyFollowing) {
          await _discoverRepository.unfollowUser(targetId);
        } else {
          await _discoverRepository.followUser(targetId);
        }
      } catch (e) {
        // Revert on error by reloading
        loadFollowers();
      }
    }
  }
}
