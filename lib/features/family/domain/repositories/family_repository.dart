import 'package:spokenodyssey/features/memories/domain/entities/memory_entity.dart';

import '../entities/family_member_entity.dart';

abstract class FamilyRepository {
  Future<List<FamilyMemberEntity>> getFamilyMembers();
  Future<List<MemoryEntity>> getFamilySharedMemories({bool forceRefresh = false});
  Future<bool> isFamilyAdmin();
  Future<List<FamilyInvitationEntity>> getPendingApprovals();
  Future<void> approveInvitation(String invitationId);
  Future<void> declineApproval(String invitationId);
  Future<void> promoteToAdmin(String userId);
  Future<void> demoteFromAdmin(String userId);
  Future<void> removeFamilyMember(String userId);
  Future<FamilyInvitationEntity> sendSMSInvite(
    String phoneNumber,
    String relationship,
  );
  Future<FamilyInvitationEntity> sendEmailInvite(
    String email,
    String relationship, {
    String? name,
    String? targetUid,
  });
  Future<FamilyInvitationEntity> createLinkInvite(String relationship);
  Future<FamilyInvitationEntity> createQRInvite(String relationship);
  Future<List<FamilyInvitationEntity>> getFamilyInvitations();
  Future<void> acceptFamilyInvite(String invitationId);
  Future<void> declineFamilyInvite(String invitationId);
  /// Resolves a raw QR/link token to the DB invitation ID, then the cubit calls acceptFamilyInvite.
  Future<String> validateInvitationToken(String token);
  Future<List<Map<String, dynamic>>> searchTaggableUsers(String query);
  Future<void> addDirectMember(String targetUserId, String relationship);
  Future<void> reactToMemory(String memoryId, String reactionType);
}
