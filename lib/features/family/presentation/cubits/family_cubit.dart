import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/error/exceptions.dart';
import 'package:spokenodyssey/features/memories/domain/entities/memory_entity.dart';
import '../../../auth/domain/entities/user.dart';
import '../../domain/entities/family_member_entity.dart';
import '../../domain/entities/family_prompt_entity.dart';
import '../../domain/repositories/family_repository.dart';

abstract class FamilyState {}

class FamilyInitial extends FamilyState {}

class FamilyLoading extends FamilyState {}

class FamilyLoaded extends FamilyState {
  final List<FamilyMemberEntity> members;
  final List<MemoryEntity> sharedMemories;
  final List<FamilyInvitationEntity> pendingApprovals;
  final List<FamilyInvitationEntity> myInvitations;
  final List<FamilyInvitationEntity> awaitingApprovalInvites;
  final List<FamilyInvitationEntity> sentInvitations;
  final List<FamilyPromptEntity> prompts;
  final String? currentCircleId;
  final bool isAdmin;
  final String? actionError;

  FamilyLoaded({
    required this.members,
    required this.sharedMemories,
    required this.pendingApprovals,
    required this.myInvitations,
    this.awaitingApprovalInvites = const [],
    this.sentInvitations = const [],
    this.prompts = const [],
    this.currentCircleId,
    required this.isAdmin,
    this.actionError,
  });

  FamilyLoaded copyWith({
    List<FamilyMemberEntity>? members,
    List<MemoryEntity>? sharedMemories,
    List<FamilyInvitationEntity>? pendingApprovals,
    List<FamilyInvitationEntity>? myInvitations,
    List<FamilyInvitationEntity>? awaitingApprovalInvites,
    List<FamilyInvitationEntity>? sentInvitations,
    List<FamilyPromptEntity>? prompts,
    String? currentCircleId,
    bool? isAdmin,
    String? actionError,
    bool clearError = false,
  }) {
    return FamilyLoaded(
      members: members ?? this.members,
      sharedMemories: sharedMemories ?? this.sharedMemories,
      pendingApprovals: pendingApprovals ?? this.pendingApprovals,
      myInvitations: myInvitations ?? this.myInvitations,
      awaitingApprovalInvites:
          awaitingApprovalInvites ?? this.awaitingApprovalInvites,
      sentInvitations: sentInvitations ?? this.sentInvitations,
      prompts: prompts ?? this.prompts,
      currentCircleId: currentCircleId ?? this.currentCircleId,
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
      emit(
        (state as FamilyLoaded).copyWith(
          actionError: ErrorParser.extractMessage(e),
        ),
      );
    } else {
      emit(FamilyError(ErrorParser.extractMessage(e)));
    }
  }

  // ── FULL LOAD: Only shows spinner on first open ──
  Future<void> loadFamilyCircle({bool forceRefresh = false}) async {
    try {
      if (state is! FamilyLoaded) {
        emit(FamilyLoading());
      }
      await _fetchAndEmit(forceRefresh: forceRefresh);
    } catch (e) {
      if (state is! FamilyLoaded) {
        emit(FamilyError(ErrorParser.extractMessage(e)));
      }
    }
  }

  // ── SILENT REFRESH: keeps current members visible. No loading spinner. ──────
  // Use this after every action (approve, decline, remove, etc.) so members
  // NEVER disappear from the screen during a background data sync.
  Future<void> _silentRefresh() async {
    try {
      await _fetchAndEmit(forceRefresh: true);
    } catch (_) {
      // Silently ignore: never blank the screen due to a refresh failure
    }
  }

  Future<List<FamilyInvitationEntity>> _loadSentInvitations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList('saved_sent_family_invitations') ?? [];
      return raw.map((str) {
        final map = jsonDecode(str) as Map<String, dynamic>;
        return FamilyInvitationEntity(
          id: map['id']?.toString() ?? '',
          email: map['email']?.toString(),
          receiverName: map['receiverName']?.toString(),
          relationship: map['relationship']?.toString() ?? 'Family',
          status: map['status']?.toString() ?? 'PENDING',
          createdAt: map['createdAt']?.toString(),
          method: map['method']?.toString() ?? 'EMAIL',
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveSentInvitation(FamilyInvitationEntity invite) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList('saved_sent_family_invitations') ?? [];
      final map = {
        'id': invite.id,
        'email': invite.email,
        'receiverName': invite.receiverName,
        'relationship': invite.relationship,
        'status': invite.status,
        'createdAt': invite.createdAt ?? DateTime.now().toIso8601String(),
        'method': invite.method,
      };
      final list = raw.where((str) {
        try {
          final m = jsonDecode(str) as Map<String, dynamic>;
          final sameId = invite.id.isNotEmpty && m['id'] == invite.id;
          final sameEmail =
              invite.email != null &&
              invite.email!.isNotEmpty &&
              m['email']?.toString().toLowerCase() ==
                  invite.email!.toLowerCase();
          return !sameId && !sameEmail;
        } catch (_) {
          return true;
        }
      }).toList();
      list.insert(0, jsonEncode(map));
      await prefs.setStringList('saved_sent_family_invitations', list);
    } catch (_) {}
  }

  // ── Core fetch logic shared by loadFamilyCircle() and _silentRefresh() ───────
  Future<void> _fetchAndEmit({bool forceRefresh = false}) async {
    // Run network calls concurrently in parallel for blazing-fast load times
    final membersFuture = repository.getFamilyMembers();
    final sharedMemoriesFuture =
        repository.getFamilySharedMemories(forceRefresh: forceRefresh);
    final myInvitationsFuture = repository.getFamilyInvitations();
    final isAdminFuture = repository.isFamilyAdmin().catchError((_) => false);

    final results = await Future.wait([
      membersFuture,
      sharedMemoriesFuture,
      myInvitationsFuture,
      isAdminFuture,
    ]);

    final members = results[0] as List<FamilyMemberEntity>;
    final sharedMemories = results[1] as List<MemoryEntity>;
    final myInvitations = results[2] as List<FamilyInvitationEntity>;
    final isAdmin = results[3] as bool;

    List<FamilyInvitationEntity> pendingApprovals = [];
    if (isAdmin) {
      try {
        pendingApprovals = await repository.getPendingApprovals();
      } catch (_) {}
    }

    // Preserve awaiting approval invites until user is officially added as a member
    final existingAwaiting = (state is FamilyLoaded)
        ? (state as FamilyLoaded).awaitingApprovalInvites
              .where(
                (inv) => !members.any(
                  (m) =>
                      m.id == inv.id ||
                      (inv.inviterEmail != null &&
                          m.user?.email == inv.inviterEmail) ||
                      (inv.inviterName != null &&
                          m.user?.name == inv.inviterName),
                ),
              )
              .toList()
        : <FamilyInvitationEntity>[];

    // Load and update sent invitations
    final sentList = await _loadSentInvitations();
    final updatedSentList = sentList.map((sent) {
      final isPendingApproval = pendingApprovals.any(
        (a) =>
            (sent.id.isNotEmpty && a.id == sent.id) ||
            (sent.email != null &&
                a.email?.toLowerCase() == sent.email?.toLowerCase()),
      );
      if (isPendingApproval) {
        return FamilyInvitationEntity(
          id: sent.id,
          email: sent.email,
          receiverName: sent.receiverName,
          relationship: sent.relationship,
          status: 'ACCEPTED',
          createdAt: sent.createdAt,
          method: sent.method,
        );
      }
      final isJoined = members.any(
        (m) =>
            sent.email != null &&
            m.user?.email.toLowerCase() == sent.email?.toLowerCase(),
      );
      if (isJoined) {
        return FamilyInvitationEntity(
          id: sent.id,
          email: sent.email,
          receiverName: sent.receiverName,
          relationship: sent.relationship,
          status: 'APPROVED',
          createdAt: sent.createdAt,
          method: sent.method,
        );
      }
      return sent;
    }).toList();

    final circleId =
        await repository.getCurrentFamilyCircleId().catchError((_) => null);
    List<FamilyPromptEntity> prompts = [];
    if (circleId != null && circleId.isNotEmpty) {
      try {
        prompts = await repository.getFamilyPrompts(circleId);
      } catch (_) {}
    }

    emit(
      FamilyLoaded(
        members: members,
        sharedMemories: sharedMemories,
        pendingApprovals: pendingApprovals,
        myInvitations: myInvitations,
        awaitingApprovalInvites: existingAwaiting,
        sentInvitations: updatedSentList,
        prompts: prompts,
        currentCircleId: circleId,
        isAdmin: isAdmin || pendingApprovals.isNotEmpty,
      ),
    );
  }

  // ── APPROVE: move pending -> member optimistically, then sync backend ─────────
  Future<void> approveInvitation(String id) async {
    try {
      // Step 1: Optimistic update — move the approved person into members NOW
      if (state is FamilyLoaded) {
        final current = state as FamilyLoaded;
        final matched = current.pendingApprovals
            .where((p) => p.id == id)
            .toList();
        final remaining = current.pendingApprovals
            .where((p) => p.id != id)
            .toList();

        if (matched.isNotEmpty) {
          final inv = matched.first;
          final alreadyIn = current.members.any(
            (m) =>
                m.id == inv.id ||
                (inv.inviterEmail != null &&
                    m.user?.email == inv.inviterEmail) ||
                (inv.receiverName != null && m.user?.name == inv.receiverName),
          );

          if (!alreadyIn) {
            emit(
              current.copyWith(
                members: [
                  ...current.members,
                  FamilyMemberEntity(
                    id: inv.id,
                    user: User(
                      id: inv.id,
                      email: inv.inviterEmail ?? '',
                      name:
                          inv.receiverName ??
                          inv.inviterName ??
                          'Family Member',
                      avatarUrl: inv.receiverAvatar ?? inv.inviterAvatar,
                    ),
                    relationship: inv.relationship,
                    role: 'member',
                    status: 'accepted',
                    joinedAt: DateTime.now().toIso8601String(),
                  ),
                ],
                pendingApprovals: remaining,
              ),
            );
          }
        }
      }

      // Step 2: Tell backend
      await repository.approveInvitation(id);

      // Step 3: Wait for backend propagation, then silently sync
      await Future.delayed(const Duration(milliseconds: 800));
      await _silentRefresh();
    } catch (e) {
      _emitError(e);
      await _silentRefresh();
    }
  }

  // ── DECLINE PENDING APPROVAL ──────────────────────────────────────────────────
  Future<void> declineApproval(String id) async {
    try {
      // Optimistic: remove from pending list immediately
      if (state is FamilyLoaded) {
        final current = state as FamilyLoaded;
        emit(
          current.copyWith(
            pendingApprovals: current.pendingApprovals
                .where((p) => p.id != id)
                .toList(),
          ),
        );
      }
      await repository.declineApproval(id);
      await _silentRefresh();
    } catch (e) {
      _emitError(e);
      await _silentRefresh();
    }
  }

  // ── ACCEPT INVITE (invitee side) ──────────────────────────────────────────────
  Future<void> acceptFamilyInvite(String invitationId) async {
    try {
      FamilyInvitationEntity? acceptedInv;

      if (state is FamilyLoaded) {
        final current = state as FamilyLoaded;
        try {
          acceptedInv = current.myInvitations.firstWhere(
            (i) => i.id == invitationId,
          );
        } catch (_) {}

        final updatedMyInvites = current.myInvitations
            .where((i) => i.id != invitationId)
            .toList();
        final updatedAwaiting = [
          if (acceptedInv != null) acceptedInv,
          ...current.awaitingApprovalInvites.where((i) => i.id != invitationId),
        ];

        emit(
          current.copyWith(
            myInvitations: updatedMyInvites,
            awaitingApprovalInvites: updatedAwaiting,
          ),
        );
      }

      await repository.acceptFamilyInvite(invitationId);
      await Future.delayed(const Duration(milliseconds: 500));
      await _silentRefresh();
    } catch (e) {
      _emitError(e);
      await _silentRefresh();
    }
  }

  // ── DIRECT ADD MEMBER (admin side, instant connect) ───────────────────────────
  Future<bool> addDirectMember(String targetUserId, String relationship) async {
    try {
      await repository.addDirectMember(targetUserId, relationship);
      await _silentRefresh();
      return true;
    } catch (e) {
      _emitError(e);
      return false;
    }
  }

  // ── SEARCH REGISTERED USERS ───────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> searchTaggableUsers(String query) async {
    return await repository.searchTaggableUsers(query);
  }

  // ── DECLINE INVITE (invitee side) ────────────────────────────────────────────
  Future<void> declineFamilyInvite(String invitationId) async {
    try {
      if (state is FamilyLoaded) {
        final current = state as FamilyLoaded;
        emit(
          current.copyWith(
            myInvitations: current.myInvitations
                .where((i) => i.id != invitationId)
                .toList(),
          ),
        );
      }
      await repository.declineFamilyInvite(invitationId);
      await _silentRefresh();
    } catch (e) {
      _emitError(e);
    }
  }

  // ── PROMOTE / REMOVE ─────────────────────────────────────────────────────────
  Future<void> promoteMember(String userId) async {
    try {
      await repository.promoteToAdmin(userId);
      await _silentRefresh();
    } catch (e) {
      _emitError(e);
    }
  }

  Future<void> removeMember(String userId) async {
    try {
      // Optimistic: remove member immediately
      if (state is FamilyLoaded) {
        final current = state as FamilyLoaded;
        emit(
          current.copyWith(
            members: current.members
                .where((m) => m.id != userId && m.user?.id != userId)
                .toList(),
          ),
        );
      }
      await repository.removeFamilyMember(userId);
      await _silentRefresh();
    } catch (e) {
      _emitError(e);
      await _silentRefresh();
    }
  }

  // ── SEND INVITES ──────────────────────────────────────────────────────────────
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
      await _saveSentInvitation(invite);
      await _silentRefresh();
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
      await _saveSentInvitation(invite);
      await _silentRefresh();
      return invite;
    } catch (e) {
      _emitError(e);
      return null;
    }
  }

  Future<FamilyInvitationEntity?> createLinkInvite(String relation) async {
    try {
      return await repository.createLinkInvite(relation);
    } catch (e) {
      _emitError(e);
      return null;
    }
  }

  Future<FamilyInvitationEntity?> createQRInvite(String relation) async {
    try {
      return await repository.createQRInvite(relation);
    } catch (e) {
      _emitError(e);
      return null;
    }
  }

  // ── QR SCAN ACCEPT ────────────────────────────────────────────────────────────
  /// Flow:
  ///   1. Extract the raw token from the scanned URL.
  ///   2. Validate token via `GET /family/invitations/validate?token=<token>`
  ///   3. Accept via `POST /family/invitations/<id>/accept`
  Future<bool> acceptInviteFromQR(String rawValue) async {
    try {
      String token = rawValue.trim();
      final uri = Uri.tryParse(rawValue);
      if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
        final segments = uri.pathSegments;
        if (segments.isNotEmpty) token = segments.last;
        if (uri.queryParameters.containsKey('token')) {
          token = uri.queryParameters['token']!;
        }
      }

      if (token.isEmpty) return false;

      final invitationId = await repository.validateInvitationToken(token);
      await acceptFamilyInvite(invitationId);
      return true;
    } catch (e) {
      _emitError(e);
      return false;
    }
  }

  // ── REACT / LIKE SHARED MEMORY ─────────────────────────────────────────────
  Future<void> reactToSharedMemory(String memoryId, String reactionType) async {
    if (state is FamilyLoaded) {
      final loaded = state as FamilyLoaded;
      final list = List<MemoryEntity>.from(loaded.sharedMemories);
      final idx = list.indexWhere((m) => m.id == memoryId);
      if (idx != -1) {
        final current = list[idx];
        final isUnreacting = current.userReaction == reactionType;
        final nextReaction = isUnreacting ? null : reactionType;
        final diff = isUnreacting ? -1 : (current.userReaction == null ? 1 : 0);
        list[idx] = current.copyWith(
          userReaction: nextReaction,
          clearUserReaction: isUnreacting,
          likesCount: (current.likesCount + diff).clamp(0, 999999),
        );
        emit(loaded.copyWith(sharedMemories: list));
      }
    }

    try {
      await repository.reactToMemory(memoryId, reactionType);
    } catch (e) {
      _emitError(e);
    }
  }

  // ── FAMILY PROMPTS (Q&A) ───────────────────────────────────────────────────
  Future<void> loadPrompts() async {
    if (state is! FamilyLoaded) return;
    final current = state as FamilyLoaded;
    try {
      final circleId = current.currentCircleId ??
          await repository.getCurrentFamilyCircleId();
      if (circleId != null && circleId.isNotEmpty) {
        final prompts = await repository.getFamilyPrompts(circleId);
        emit(current.copyWith(prompts: prompts, currentCircleId: circleId));
      }
    } catch (_) {}
  }

  Future<bool> createPrompt({
    required String question,
    required String category,
  }) async {
    if (state is! FamilyLoaded) return false;
    final current = state as FamilyLoaded;
    try {
      final circleId = current.currentCircleId ??
          await repository.getCurrentFamilyCircleId();
      if (circleId == null || circleId.isEmpty) {
        emit(current.copyWith(
            actionError: 'No active family circle found to post prompt.'));
        return false;
      }
      final newPrompt = await repository.createFamilyPrompt(
        circleId,
        question,
        category,
      );
      emit(current.copyWith(
        prompts: [newPrompt, ...current.prompts],
        currentCircleId: circleId,
      ));
      return true;
    } catch (e) {
      emit(current.copyWith(actionError: ErrorParser.extractMessage(e)));
      return false;
    }
  }

  Future<bool> respondToPrompt({
    required String promptId,
    required String text,
  }) async {
    if (state is! FamilyLoaded) return false;
    final current = state as FamilyLoaded;
    try {
      final newResponse =
          await repository.respondToFamilyPrompt(promptId, text);
      final updatedPrompts = current.prompts.map((p) {
        if (p.id == promptId) {
          return FamilyPromptEntity(
            id: p.id,
            familyCircleId: p.familyCircleId,
            question: p.question,
            category: p.category,
            audioUrl: p.audioUrl,
            creatorName: p.creatorName,
            creatorAvatar: p.creatorAvatar,
            createdAt: p.createdAt,
            responses: [...p.responses, newResponse],
          );
        }
        return p;
      }).toList();
      emit(current.copyWith(prompts: updatedPrompts));
      return true;
    } catch (e) {
      emit(current.copyWith(actionError: ErrorParser.extractMessage(e)));
      return false;
    }
  }
}
