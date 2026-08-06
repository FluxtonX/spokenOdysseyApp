import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../memories/domain/entities/memory_entity.dart';
import '../../domain/repositories/discover_repository.dart';

abstract class DiscoverState {}

class DiscoverInitial extends DiscoverState {}
class DiscoverLoading extends DiscoverState {}
class DiscoverLoaded extends DiscoverState {
  final List<MemoryEntity> memories;
  final List<User> suggestedPeople;
  final String selectedCategory;
  final SearchResultsEntity? searchResults;

  DiscoverLoaded({
    required this.memories,
    required this.suggestedPeople,
    this.selectedCategory = 'All',
    this.searchResults,
  });
}
class DiscoverError extends DiscoverState {
  final String message;
  DiscoverError(this.message);
}

class DiscoverCubit extends Cubit<DiscoverState> {
  final DiscoverRepository repository;

  DiscoverCubit({required this.repository}) : super(DiscoverInitial());

  Future<void> loadDiscovery({String category = 'All'}) async {
    try {
      emit(DiscoverLoading());
      final memories = await repository.getDiscoveryMemories(
        filter: category == 'All' ? null : category,
      );
      final suggested = await repository.getSuggestedPeople();

      emit(DiscoverLoaded(
        memories: memories,
        suggestedPeople: suggested,
        selectedCategory: category,
      ));
    } catch (e) {
      emit(DiscoverError(e.toString()));
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

      emit(DiscoverLoaded(
        memories: results.memories,
        suggestedPeople: suggested,
        searchResults: results,
      ));
    } catch (e) {
      emit(DiscoverError(e.toString()));
    }
  }

  Future<void> toggleFollow(String targetUid, bool currentlyFollowing) async {
    try {
      if (currentlyFollowing) {
        await repository.unfollowUser(targetUid);
      } else {
        await repository.followUser(targetUid);
      }
      if (state is DiscoverLoaded) {
        final currentState = state as DiscoverLoaded;
        await loadDiscovery(category: currentState.selectedCategory);
      }
    } catch (_) {}
  }
}
