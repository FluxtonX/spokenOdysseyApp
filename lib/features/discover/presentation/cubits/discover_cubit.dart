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
  final String selectedCategory;
  final SearchResultsEntity? searchResults;
  final String? actionError;

  DiscoverLoaded({
    required this.memories,
    required this.suggestedPeople,
    this.selectedCategory = 'All',
    this.searchResults,
    this.actionError,
  });

  DiscoverLoaded copyWith({
    List<MemoryEntity>? memories,
    List<User>? suggestedPeople,
    String? selectedCategory,
    SearchResultsEntity? searchResults,
    String? actionError,
    bool clearError = false,
  }) {
    return DiscoverLoaded(
      memories: memories ?? this.memories,
      suggestedPeople: suggestedPeople ?? this.suggestedPeople,
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
      emit((state as DiscoverLoaded).copyWith(
        actionError: ErrorParser.extractMessage(e),
      ));
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
      final suggested = await repository.getSuggestedPeople();

      emit(DiscoverLoaded(
        memories: memories,
        suggestedPeople: suggested,
        selectedCategory: category,
      ));
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

      emit(DiscoverLoaded(
        memories: results.memories,
        suggestedPeople: suggested,
        searchResults: results,
      ));
    } catch (e) {
      emit(DiscoverError(ErrorParser.extractMessage(e)));
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
    } catch (e) {
      _emitError(e);
    }
  }
}
