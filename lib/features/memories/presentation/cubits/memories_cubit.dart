import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/cache_manager.dart';
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

  Future<void> loadMemories({String? userId, bool forceRefresh = false}) async {
    try {
      final bool wasGridView = (state is MemoriesLoaded)
          ? (state as MemoriesLoaded).isGridView
          : false;
      if (state is! MemoriesLoaded || forceRefresh) {
        if (state is! MemoriesLoaded) emit(MemoriesLoading());
      }
      if (forceRefresh) {
        CacheManager().invalidate('memories_');
      }
      final memories = await repository.getMemories(userId: userId);
      emit(MemoriesLoaded(memories, isGridView: wasGridView));
    } catch (e) {
      if (state is! MemoriesLoaded) {
        emit(MemoriesError(ErrorParser.extractMessage(e)));
      }
    }
  }

  Future<void> loadFeedMemories({bool forceRefresh = false}) async {
    try {
      final bool wasGridView = (state is MemoriesLoaded)
          ? (state as MemoriesLoaded).isGridView
          : false;
      if (state is! MemoriesLoaded || forceRefresh) {
        if (state is! MemoriesLoaded) emit(MemoriesLoading());
      }
      if (forceRefresh) {
        CacheManager().invalidate('memories_');
      }
      final memories = await repository.getFeedMemories();
      emit(MemoriesLoaded(memories, isGridView: wasGridView));
    } catch (e) {
      if (state is! MemoriesLoaded) {
        emit(MemoriesError(ErrorParser.extractMessage(e)));
      }
    }
  }

  Future<void> loadUserMemories(String userId) async {
    return loadMemories(userId: userId);
  }

  Future<void> searchMemories(String query) async {
    try {
      if (query.trim().isEmpty) {
        await loadMemories();
        return;
      }
      final bool wasGridView = (state is MemoriesLoaded)
          ? (state as MemoriesLoaded).isGridView
          : false;
      final memories = await repository.searchMemories(query);
      emit(
        MemoriesLoaded(memories, isGridView: wasGridView, searchQuery: query),
      );
    } catch (e) {
      if (state is! MemoriesLoaded) {
        emit(MemoriesError(ErrorParser.extractMessage(e)));
      }
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
    List<String>? mediaPaths,
    String? privacy,
    List<String>? tags,
    List<String>? taggedUserIds,
    String? albumId,
    String? type,
    String? mood,
    String? occurredAt,
    bool? isVaultLocked,
    String? unlockDate,
  }) async {
    try {
      await repository.createMemory(
        title: title,
        description: description,
        mediaPaths: mediaPaths,
        privacy: privacy,
        tags: tags,
        taggedUserIds: taggedUserIds,
        albumId: albumId,
        type: type,
        mood: mood,
        occurredAt: occurredAt,
        isVaultLocked: isVaultLocked,
        unlockDate: unlockDate,
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
        emit(
          (state as MemoriesLoaded).copyWith(
            memories: currentList,
            clearError: true,
          ),
        );
      }
    }

    try {
      await repository.deleteMemory(memoryId);
    } catch (e) {
      final msg = ErrorParser.extractMessage(e).toLowerCase();
      if (msg.contains('not found') || msg.contains('could not be found')) {
        // Memory is already deleted on the server, keep it removed from UI
        return;
      }
      if (state is MemoriesLoaded && backupList != null) {
        emit(
          (state as MemoriesLoaded).copyWith(
            memories: backupList,
            actionError:
                'Could not delete memory: ${ErrorParser.extractMessage(e)}',
          ),
        );
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
        final countDiff = isUnreacting
            ? -1
            : (currentMemory.userReaction == null ? 1 : 0);

        currentList[index] = currentMemory.copyWith(
          userReaction: newReaction,
          clearUserReaction: isUnreacting,
          likesCount: (currentMemory.likesCount + countDiff).clamp(0, 999999),
        );
        emit(
          (state as MemoriesLoaded).copyWith(
            memories: currentList,
            clearError: true,
          ),
        );
      }
    }

    try {
      await repository.reactToMemory(memoryId, reactionType);
      // No need to refetch the entire feed on a successful reaction.
    } catch (e) {
      if (state is MemoriesLoaded && backupList != null) {
        emit(
          (state as MemoriesLoaded).copyWith(
            memories: backupList,
            actionError:
                'Could not react to memory: ${ErrorParser.extractMessage(e)}',
          ),
        );
      } else if (state is! MemoriesLoaded) {
        emit(MemoriesError(ErrorParser.extractMessage(e)));
      }
    }
  }
}
