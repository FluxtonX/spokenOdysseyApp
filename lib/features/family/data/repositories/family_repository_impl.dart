import 'package:spokenodyssey/features/memories/domain/entities/memory_entity.dart';
import '../../../../core/network/cache_manager.dart';
import '../../domain/entities/family_member_entity.dart';
import '../../domain/entities/family_prompt_entity.dart';
import '../../domain/repositories/family_repository.dart';
import '../datasources/family_remote_datasource.dart';

class FamilyRepositoryImpl implements FamilyRepository {
  final FamilyRemoteDataSource remoteDataSource;

  FamilyRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<FamilyMemberEntity>> getFamilyMembers() async {
    const key = 'family_members';
    final cached = CacheManager().get<List<FamilyMemberEntity>>(
      key,
      ttl: const Duration(minutes: 5),
    );
    if (cached != null) return cached;

    final members = await remoteDataSource.getFamilyMembers();
    CacheManager().set(key, members);
    return members;
  }

  @override
  Future<List<MemoryEntity>> getFamilySharedMemories({
    bool forceRefresh = false,
  }) async {
    const key = 'family_shared_memories';
    if (!forceRefresh) {
      final cached = CacheManager().get<List<MemoryEntity>>(
        key,
        ttl: const Duration(minutes: 3),
      );
      if (cached != null) return cached;
    }

    final memories = await remoteDataSource.getFamilySharedMemories(
      forceRefresh: forceRefresh,
    );
    CacheManager().set(key, memories);
    return memories;
  }

  @override
  Future<bool> isFamilyAdmin() async {
    return await remoteDataSource.isFamilyAdmin();
  }

  @override
  Future<List<FamilyInvitationEntity>> getPendingApprovals() async {
    return await remoteDataSource.getPendingApprovals();
  }

  @override
  Future<void> approveInvitation(String invitationId) async {
    await remoteDataSource.approveInvitation(invitationId);
  }

  @override
  Future<void> declineApproval(String invitationId) async {
    await remoteDataSource.declineApproval(invitationId);
  }

  @override
  Future<void> promoteToAdmin(String userId) async {
    await remoteDataSource.promoteToAdmin(userId);
  }

  @override
  Future<void> demoteFromAdmin(String userId) async {
    await remoteDataSource.demoteFromAdmin(userId);
  }

  @override
  Future<void> removeFamilyMember(String userId) async {
    await remoteDataSource.removeFamilyMember(userId);
  }

  @override
  Future<FamilyInvitationEntity> sendSMSInvite(
    String phoneNumber,
    String relationship,
  ) async {
    return await remoteDataSource.sendSMSInvite(phoneNumber, relationship);
  }

  @override
  Future<FamilyInvitationEntity> sendEmailInvite(
    String email,
    String relationship, {
    String? name,
    String? targetUid,
  }) async {
    return await remoteDataSource.sendEmailInvite(
      email,
      relationship,
      name: name,
      targetUid: targetUid,
    );
  }

  @override
  Future<FamilyInvitationEntity> createLinkInvite(String relationship) async {
    return await remoteDataSource.createLinkInvite(relationship);
  }

  @override
  Future<FamilyInvitationEntity> createQRInvite(String relationship) async {
    return await remoteDataSource.createQRInvite(relationship);
  }

  @override
  Future<List<FamilyInvitationEntity>> getFamilyInvitations() async {
    return await remoteDataSource.getFamilyInvitations();
  }

  @override
  Future<void> acceptFamilyInvite(String invitationId) async {
    await remoteDataSource.acceptFamilyInvite(invitationId);
  }

  @override
  Future<void> declineFamilyInvite(String invitationId) async {
    await remoteDataSource.declineFamilyInvite(invitationId);
  }

  @override
  Future<String> validateInvitationToken(String token) async {
    return await remoteDataSource.validateInvitationToken(token);
  }

  @override
  Future<List<Map<String, dynamic>>> searchTaggableUsers(String query) async {
    return await remoteDataSource.searchTaggableUsers(query);
  }

  @override
  Future<void> addDirectMember(String targetUserId, String relationship) async {
    await remoteDataSource.addDirectMember(targetUserId, relationship);
  }

  @override
  Future<void> reactToMemory(String memoryId, String reactionType) async {
    await remoteDataSource.reactToMemory(memoryId, reactionType);
  }

  @override
  Future<String?> getCurrentFamilyCircleId() async {
    return await remoteDataSource.getCurrentFamilyCircleId();
  }

  @override
  Future<List<FamilyPromptEntity>> getFamilyPrompts(String circleId) async {
    return await remoteDataSource.getFamilyPrompts(circleId);
  }

  @override
  Future<FamilyPromptEntity> createFamilyPrompt(
    String circleId,
    String question,
    String category,
  ) async {
    return await remoteDataSource.createFamilyPrompt(
      circleId,
      question,
      category,
    );
  }

  @override
  Future<FamilyPromptResponse> respondToFamilyPrompt(
    String promptId,
    String text,
  ) async {
    return await remoteDataSource.respondToFamilyPrompt(promptId, text);
  }
}
