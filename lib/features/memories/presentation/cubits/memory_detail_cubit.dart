import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/exceptions.dart';
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
      emit(MemoryDetailError(ErrorParser.extractMessage(e)));
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
      emit(MemoryDetailError(ErrorParser.extractMessage(e)));
    }
  }

  Future<void> reactToMemory(String memoryId, String reactionType) async {
    MemoryEntity? backupMemory;
    if (state is MemoryDetailLoaded) {
      final currentLoaded = state as MemoryDetailLoaded;
      backupMemory = currentLoaded.memory;
      final isUnreacting = backupMemory.userReaction == reactionType;
      final newReaction = isUnreacting ? null : reactionType;
      final countDiff = isUnreacting ? -1 : (backupMemory.userReaction == null ? 1 : 0);
      
      final updatedMemory = backupMemory.copyWith(
        userReaction: newReaction,
        clearUserReaction: isUnreacting,
        likesCount: (backupMemory.likesCount + countDiff).clamp(0, 999999),
      );
      
      emit(MemoryDetailLoaded(
        memory: updatedMemory,
        comments: currentLoaded.comments,
      ));
    }

    try {
      await repository.reactToMemory(memoryId, reactionType);
      // No need to fetch memory details since optimistic update succeeded
    } catch (e) {
      if (state is MemoryDetailLoaded && backupMemory != null) {
        final currentLoaded = state as MemoryDetailLoaded;
        emit(MemoryDetailLoaded(
          memory: backupMemory,
          comments: currentLoaded.comments,
        ));
      } else if (state is! MemoryDetailLoaded) {
        emit(MemoryDetailError(ErrorParser.extractMessage(e)));
      }
    }
  }
}
