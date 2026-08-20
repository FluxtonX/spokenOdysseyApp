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
      final followers = await _discoverRepository.getFollowers();
      emit(FollowersLoaded(
        followers: followers,
        searchResults: followers,
      ));
    } catch (e) {
      emit(FollowersError(e.toString()));
    }
  }

  void searchFollowers(String query) {
    final currentState = state;
    if (currentState is FollowersLoaded) {
      if (query.isEmpty) {
        emit(currentState.copyWith(
          searchResults: currentState.followers,
          searchQuery: query,
        ));
      } else {
        final searchLower = query.toLowerCase();
        final results = currentState.followers.where((user) {
          final nameMatch = user.name?.toLowerCase().contains(searchLower) ?? false;
          final emailMatch = user.email.toLowerCase().contains(searchLower);
          return nameMatch || emailMatch;
        }).toList();
        
        emit(currentState.copyWith(
          searchResults: results,
          searchQuery: query,
        ));
      }
    }
  }

  Future<void> toggleFollow(User user) async {
    final currentState = state;
    if (currentState is FollowersLoaded) {
      try {
        final isCurrentlyFollowing = user.isFollowing;
        
        // Optimistic update
        final updatedFollowers = currentState.followers.map((u) {
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
        }).toList();

        final updatedSearchResults = currentState.searchResults.map((u) {
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
        }).toList();

        emit(currentState.copyWith(
          followers: updatedFollowers,
          searchResults: updatedSearchResults,
        ));

        // API Call
        if (isCurrentlyFollowing) {
          await _discoverRepository.unfollowUser(user.firebaseUid ?? user.id);
        } else {
          await _discoverRepository.followUser(user.firebaseUid ?? user.id);
        }
      } catch (e) {
        // Revert on error by reloading
        loadFollowers();
      }
    }
  }
}
