import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/exceptions.dart';
import 'package:spokenodyssey/features/memories/domain/entities/memory_entity.dart';
import '../../domain/entities/family_member_entity.dart';
import '../../domain/repositories/family_repository.dart';

abstract class FamilyState {}

class FamilyInitial extends FamilyState {}

class FamilyLoading extends FamilyState {}

class FamilyLoaded extends FamilyState {
  final List<FamilyMemberEntity> members;
  final List<MemoryEntity> sharedMemories;
  final List<FamilyInvitationEntity> pendingApprovals;
  final List<FamilyInvitationEntity> myInvitations;
  final bool isAdmin;
  final String? actionError;

  FamilyLoaded({
    required this.members,
    required this.sharedMemories,
    required this.pendingApprovals,
    required this.myInvitations,
    required this.isAdmin,
    this.actionError,
  });

  FamilyLoaded copyWith({
    List<FamilyMemberEntity>? members,
    List<MemoryEntity>? sharedMemories,
    List<FamilyInvitationEntity>? pendingApprovals,
    List<FamilyInvitationEntity>? myInvitations,
    bool? isAdmin,
    String? actionError,
    bool clearError = false,
  }) {
    return FamilyLoaded(
      members: members ?? this.members,
      sharedMemories: sharedMemories ?? this.sharedMemories,
      pendingApprovals: pendingApprovals ?? this.pendingApprovals,
      myInvitations: myInvitations ?? this.myInvitations,
      isAdmin: isAdmin ?? this.isAdmin,
      actionError: clearError ? null : (actionError ?? this.actionError),
    );
  }
}

class FamilyError extends FamilyState {
  final String message;
  FamilyError(this.message);
}

class FamilyCubit extends Cubit<FamilyState> {
  final FamilyRepository repository;

  FamilyCubit({required this.repository}) : super(FamilyInitial());

  void _emitError(dynamic e) {
    if (state is FamilyLoaded) {
      emit((state as FamilyLoaded).copyWith(
        actionError: ErrorParser.extractMessage(e),
      ));
    } else {
      emit(FamilyError(ErrorParser.extractMessage(e)));
    }
  }

  Future<void> loadFamilyCircle() async {
    try {
      emit(FamilyLoading());
      final members = await repository.getFamilyMembers();
      final sharedMemories = await repository.getFamilySharedMemories();
      final isAdmin = await repository.isFamilyAdmin();
      List<FamilyInvitationEntity> pendingApprovals = [];
      if (isAdmin) {
        pendingApprovals = await repository.getPendingApprovals();
      }
      final myInvitations = await repository.getFamilyInvitations();

      emit(
        FamilyLoaded(
          members: members,
          sharedMemories: sharedMemories,
          pendingApprovals: pendingApprovals,
          myInvitations: myInvitations,
          isAdmin: isAdmin,
        ),
      );
    } catch (e) {
      emit(FamilyError(ErrorParser.extractMessage(e)));
    }
  }

  Future<void> approveInvitation(String id) async {
    try {
      await repository.approveInvitation(id);
      await loadFamilyCircle();
    } catch (e) {
      _emitError(e);
    }
  }

  Future<void> declineApproval(String id) async {
    try {
      await repository.declineApproval(id);
      await loadFamilyCircle();
    } catch (e) {
      _emitError(e);
    }
  }

  Future<void> promoteMember(String userId) async {
    try {
      await repository.promoteToAdmin(userId);
      await loadFamilyCircle();
    } catch (e) {
      _emitError(e);
    }
  }

  Future<void> removeMember(String userId) async {
    try {
      await repository.removeFamilyMember(userId);
      await loadFamilyCircle();
    } catch (e) {
      _emitError(e);
    }
  }

  Future<FamilyInvitationEntity?> sendEmailInvite(
    String email,
    String relation, {
    String? name,
    String? targetUid,
  }) async {
    try {
      final invite = await repository.sendEmailInvite(
        email,
        relation,
        name: name,
        targetUid: targetUid,
      );
      await loadFamilyCircle();
      return invite;
    } catch (e) {
      _emitError(e);
      return null;
    }
  }

  Future<FamilyInvitationEntity?> sendSMSInvite(
    String phone,
    String relation,
  ) async {
    try {
      final invite = await repository.sendSMSInvite(phone, relation);
      await loadFamilyCircle();
      return invite;
    } catch (e) {
      _emitError(e);
      return null;
    }
  }

  Future<FamilyInvitationEntity?> createLinkInvite(String relation) async {
    try {
      final invite = await repository.createLinkInvite(relation);
      return invite;
    } catch (e) {
      _emitError(e);
      return null;
    }
  }

  Future<FamilyInvitationEntity?> createQRInvite(String relation) async {
    try {
      final invite = await repository.createQRInvite(relation);
      return invite;
    } catch (e) {
      _emitError(e);
      return null;
    }
  }
}
