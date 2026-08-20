import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/memory_entity.dart';
import '../../domain/repositories/memories_repository.dart';

abstract class MemoriesState {}

class MemoriesInitial extends MemoriesState {}

class MemoriesLoading extends MemoriesState {}

class MemoriesLoaded extends MemoriesState {
  final List<MemoryEntity> memories;
  final String? filter;
  final bool isGridView;
  final String searchQuery;
  final String? actionError;

  MemoriesLoaded(
    this.memories, {
    this.filter,
    this.isGridView = false,
    this.searchQuery = '',
    this.actionError,
  });

  MemoriesLoaded copyWith({
    List<MemoryEntity>? memories,
    String? filter,
    bool? isGridView,
    String? searchQuery,
    String? actionError,
    bool clearError = false,
  }) {
    return MemoriesLoaded(
      memories ?? this.memories,
      filter: filter ?? this.filter,
      isGridView: isGridView ?? this.isGridView,
      searchQuery: searchQuery ?? this.searchQuery,
      actionError: clearError ? null : (actionError ?? this.actionError),
    );
  }
}

class MemoriesError extends MemoriesState {
  final String message;
  MemoriesError(this.message);
}

class MemoriesCubit extends Cubit<MemoriesState> {
  final MemoriesRepository repository;

  MemoriesCubit({required this.repository}) : super(MemoriesInitial());

  Future<void> loadFeedMemories() async {
    try {
      final bool wasGridView = (state is MemoriesLoaded) ? (state as MemoriesLoaded).isGridView : false;
      emit(MemoriesLoading());
      final memories = await repository.getFeedMemories();
      emit(MemoriesLoaded(memories, isGridView: wasGridView));
    } catch (e) {
      emit(MemoriesError(ErrorParser.extractMessage(e)));
    }
  }

  Future<void> loadUserMemories(String userId) async {
    try {
      final bool wasGridView = (state is MemoriesLoaded) ? (state as MemoriesLoaded).isGridView : false;
      emit(MemoriesLoading());
      final memories = await repository.getMemories(userId: userId);
      emit(MemoriesLoaded(memories, isGridView: wasGridView));
    } catch (e) {
      emit(MemoriesError(ErrorParser.extractMessage(e)));
    }
  }

  Future<void> searchMemories(String query) async {
    try {
      if (query.trim().isEmpty) {
        await loadFeedMemories();
        return;
      }
      final bool wasGridView = (state is MemoriesLoaded) ? (state as MemoriesLoaded).isGridView : false;
      emit(MemoriesLoading());
      final memories = await repository.searchMemories(query);
      emit(MemoriesLoaded(memories, isGridView: wasGridView, searchQuery: query));
    } catch (e) {
      emit(MemoriesError(ErrorParser.extractMessage(e)));
    }
  }

  void toggleViewMode() {
    if (state is MemoriesLoaded) {
      final current = state as MemoriesLoaded;
      emit(current.copyWith(isGridView: !current.isGridView, clearError: true));
    }
  }

  Future<bool> createMemory({
    required String title,
    String? description,
    String? mediaPath,
    String? mediaType,
    String? privacy,
    List<String>? tags,
    String? albumId,
    String? type,
    String? mood,
  }) async {
    try {
      await repository.createMemory(
        title: title,
        description: description,
        mediaPath: mediaPath,
        mediaType: mediaType,
        privacy: privacy,
        tags: tags,
        albumId: albumId,
        type: type,
        mood: mood,
      );
      await loadFeedMemories();
      return true;
    } catch (e) {
      emit(MemoriesError(ErrorParser.extractMessage(e)));
      return false;
    }
  }

  Future<void> deleteMemory(String memoryId) async {
    List<MemoryEntity>? backupList;
    if (state is MemoriesLoaded) {
      backupList = List<MemoryEntity>.from((state as MemoriesLoaded).memories);
      final currentList = List<MemoryEntity>.from(backupList);
      final index = currentList.indexWhere((m) => m.id == memoryId);
      if (index != -1) {
        currentList.removeAt(index);
        emit((state as MemoriesLoaded).copyWith(memories: currentList, clearError: true));
      }
    }
    
    try {
      await repository.deleteMemory(memoryId);
    } catch (e) {
      if (state is MemoriesLoaded && backupList != null) {
        emit((state as MemoriesLoaded).copyWith(
          memories: backupList,
          actionError: 'Could not delete memory: ${ErrorParser.extractMessage(e)}',
        ));
      } else if (state is! MemoriesLoaded) {
        emit(MemoriesError(ErrorParser.extractMessage(e)));
      }
    }
  }

  Future<void> reactToMemory(String memoryId, String reactionType) async {
    List<MemoryEntity>? backupList;
    if (state is MemoriesLoaded) {
      backupList = List<MemoryEntity>.from((state as MemoriesLoaded).memories);
      final currentList = List<MemoryEntity>.from(backupList);
      final index = currentList.indexWhere((m) => m.id == memoryId);
      
      if (index != -1) {
        final currentMemory = currentList[index];
        final isUnreacting = currentMemory.userReaction == reactionType;
        final newReaction = isUnreacting ? null : reactionType;
        final countDiff = isUnreacting ? -1 : (currentMemory.userReaction == null ? 1 : 0);
        
        currentList[index] = currentMemory.copyWith(
          userReaction: newReaction,
          clearUserReaction: isUnreacting,
          likesCount: (currentMemory.likesCount + countDiff).clamp(0, 999999),
        );
        emit((state as MemoriesLoaded).copyWith(memories: currentList, clearError: true));
      }
    }

    try {
      await repository.reactToMemory(memoryId, reactionType);
      // No need to refetch the entire feed on a successful reaction.
    } catch (e) {
      if (state is MemoriesLoaded && backupList != null) {
        emit((state as MemoriesLoaded).copyWith(
          memories: backupList,
          actionError: 'Could not react to memory: ${ErrorParser.extractMessage(e)}',
        ));
      } else if (state is! MemoriesLoaded) {
        emit(MemoriesError(ErrorParser.extractMessage(e)));
      }
    }
  }
}
