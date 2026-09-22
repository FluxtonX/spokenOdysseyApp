import 'package:spokenodyssey/features/auth/domain/entities/user.dart';

abstract class FollowersState {
  const FollowersState();
}

class FollowersInitial extends FollowersState {}

class FollowersLoading extends FollowersState {}

class FollowersLoaded extends FollowersState {
  final List<User> followers;
  final List<User> following;
  final List<User> suggestions;
  final List<User> searchResults;
  final String searchQuery;
  final String selectedTab; // 'followers' | 'following'

  const FollowersLoaded({
    required this.followers,
    this.following = const [],
    this.suggestions = const [],
    required this.searchResults,
    this.searchQuery = '',
    this.selectedTab = 'followers',
  });

  FollowersLoaded copyWith({
    List<User>? followers,
    List<User>? following,
    List<User>? suggestions,
    List<User>? searchResults,
    String? searchQuery,
    String? selectedTab,
  }) {
    return FollowersLoaded(
      followers: followers ?? this.followers,
      following: following ?? this.following,
      suggestions: suggestions ?? this.suggestions,
      searchResults: searchResults ?? this.searchResults,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedTab: selectedTab ?? this.selectedTab,
    );
  }
}

class FollowersError extends FollowersState {
  final String message;

  const FollowersError(this.message);
}
