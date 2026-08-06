import 'package:spokenodyssey/features/memories/domain/entities/memory_entity.dart';

import '../../domain/entities/family_member_entity.dart';
import '../../domain/repositories/family_repository.dart';
import '../datasources/family_remote_datasource.dart';

class FamilyRepositoryImpl implements FamilyRepository {
  final FamilyRemoteDataSource remoteDataSource;

  FamilyRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<FamilyMemberEntity>> getFamilyMembers() async {
    return await remoteDataSource.getFamilyMembers();
  }

  @override
  Future<List<MemoryEntity>> getFamilySharedMemories() async {
    return await remoteDataSource.getFamilySharedMemories();
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
}
