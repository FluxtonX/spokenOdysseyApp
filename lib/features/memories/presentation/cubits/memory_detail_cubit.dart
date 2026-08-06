import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/comment_entity.dart';
import '../../domain/entities/memory_entity.dart';
import '../../domain/repositories/memories_repository.dart';

abstract class MemoryDetailState {}

class MemoryDetailInitial extends MemoryDetailState {}
class MemoryDetailLoading extends MemoryDetailState {}
class MemoryDetailLoaded extends MemoryDetailState {
  final MemoryEntity memory;
  final List<CommentEntity> comments;
  MemoryDetailLoaded({required this.memory, required this.comments});
}
class MemoryDetailError extends MemoryDetailState {
  final String message;
  MemoryDetailError(this.message);
}

class MemoryDetailCubit extends Cubit<MemoryDetailState> {
  final MemoriesRepository repository;

  MemoryDetailCubit({required this.repository}) : super(MemoryDetailInitial());

  Future<void> loadMemoryDetails(String memoryId) async {
    try {
      emit(MemoryDetailLoading());
      final memory = await repository.getMemoryDetails(memoryId);
      final comments = await repository.getComments(memoryId);
      emit(MemoryDetailLoaded(memory: memory, comments: comments));
    } catch (e) {
      emit(MemoryDetailError(e.toString()));
    }
  }

  Future<void> addComment(String memoryId, String text, {String? parentCommentId}) async {
    try {
      await repository.addComment(memoryId, text, parentCommentId: parentCommentId);
      final comments = await repository.getComments(memoryId);
      if (state is MemoryDetailLoaded) {
        final currentMemory = (state as MemoryDetailLoaded).memory;
        emit(MemoryDetailLoaded(memory: currentMemory, comments: comments));
      }
    } catch (e) {
      emit(MemoryDetailError(e.toString()));
    }
  }

  Future<void> reactToMemory(String memoryId, String reactionType) async {
    try {
      await repository.reactToMemory(memoryId, reactionType);
      final updatedMemory = await repository.getMemoryDetails(memoryId);
      if (state is MemoryDetailLoaded) {
        final comments = (state as MemoryDetailLoaded).comments;
        emit(MemoryDetailLoaded(memory: updatedMemory, comments: comments));
      }
    } catch (_) {}
  }
}
