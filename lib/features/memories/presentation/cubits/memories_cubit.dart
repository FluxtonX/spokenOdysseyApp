import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/memory_entity.dart';
import '../../domain/repositories/memories_repository.dart';

abstract class MemoriesState {}

class MemoriesInitial extends MemoriesState {}

class MemoriesLoading extends MemoriesState {}

class MemoriesLoaded extends MemoriesState {
  final List<MemoryEntity> memories;
  final String? filter;
  MemoriesLoaded(this.memories, {this.filter});
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
      emit(MemoriesLoading());
      final memories = await repository.getFeedMemories();
      emit(MemoriesLoaded(memories));
    } catch (e) {
      emit(MemoriesError(e.toString()));
    }
  }

  Future<void> loadUserMemories(String userId) async {
    try {
      emit(MemoriesLoading());
      final memories = await repository.getMemories(userId: userId);
      emit(MemoriesLoaded(memories));
    } catch (e) {
      emit(MemoriesError(e.toString()));
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
      emit(MemoriesError(e.toString()));
      return false;
    }
  }

  Future<void> deleteMemory(String memoryId) async {
    try {
      await repository.deleteMemory(memoryId);
      if (state is MemoriesLoaded) {
        final currentList = (state as MemoriesLoaded).memories;
        final updated = currentList.where((m) => m.id != memoryId).toList();
        emit(MemoriesLoaded(updated));
      }
    } catch (e) {
      emit(MemoriesError(e.toString()));
    }
  }

  Future<void> reactToMemory(String memoryId, String reactionType) async {
    try {
      await repository.reactToMemory(memoryId, reactionType);
      // Refresh feed
      final memories = await repository.getFeedMemories();
      emit(MemoriesLoaded(memories));
    } catch (_) {}
  }
}
