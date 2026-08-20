import 'package:spokenodyssey/features/auth/domain/entities/user.dart';

abstract class FollowersState {
  const FollowersState();
}

class FollowersInitial extends FollowersState {}

class FollowersLoading extends FollowersState {}

class FollowersLoaded extends FollowersState {
  final List<User> followers;
  final List<User> searchResults;
  final String searchQuery;

  const FollowersLoaded({
    required this.followers,
    required this.searchResults,
    this.searchQuery = '',
  });

  FollowersLoaded copyWith({
    List<User>? followers,
    List<User>? searchResults,
    String? searchQuery,
  }) {
    return FollowersLoaded(
      followers: followers ?? this.followers,
      searchResults: searchResults ?? this.searchResults,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class FollowersError extends FollowersState {
  final String message;

  const FollowersError(this.message);
}
