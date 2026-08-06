import 'package:spokenodyssey/features/memories/data/models/memory_model.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../models/family_member_model.dart';

abstract class FamilyRemoteDataSource {
  Future<List<FamilyMemberModel>> getFamilyMembers();
  Future<List<MemoryModel>> getFamilySharedMemories();
  Future<bool> isFamilyAdmin();
  Future<List<FamilyInvitationModel>> getPendingApprovals();
  Future<void> approveInvitation(String invitationId);
  Future<void> declineApproval(String invitationId);
  Future<void> promoteToAdmin(String userId);
  Future<void> demoteFromAdmin(String userId);
  Future<void> removeFamilyMember(String userId);
  Future<FamilyInvitationModel> sendSMSInvite(
    String phoneNumber,
    String relationship,
  );
  Future<FamilyInvitationModel> sendEmailInvite(
    String email,
    String relationship, {
    String? name,
    String? targetUid,
  });
  Future<FamilyInvitationModel> createLinkInvite(String relationship);
  Future<FamilyInvitationModel> createQRInvite(String relationship);
  Future<List<FamilyInvitationModel>> getFamilyInvitations();
  Future<void> acceptFamilyInvite(String invitationId);
  Future<void> declineFamilyInvite(String invitationId);
}

class FamilyRemoteDataSourceImpl implements FamilyRemoteDataSource {
  final ApiClient apiClient;

  FamilyRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<FamilyMemberModel>> getFamilyMembers() async {
    try {
      final response = await apiClient.get(ApiEndpoints.familyCircleMembers);
      final data = response.data['data'] ?? response.data;
      if (data is List) {
        return data.map((json) => FamilyMemberModel.fromJson(json)).toList();
      }
    } catch (_) {
      final response = await apiClient.get(ApiEndpoints.usersFamily);
      final data = response.data['data'] ?? response.data;
      if (data is List) {
        return data.map((json) => FamilyMemberModel.fromJson(json)).toList();
      }
    }
    return [];
  }

  @override
  Future<List<MemoryModel>> getFamilySharedMemories() async {
    final response = await apiClient.get(ApiEndpoints.familySharedMemories);
    final data = response.data['data'] ?? response.data;
    if (data is List) {
      return data.map((json) => MemoryModel.fromJson(json)).toList();
    }
    return [];
  }

  @override
  Future<bool> isFamilyAdmin() async {
    try {
      final response = await apiClient.get(ApiEndpoints.familyIsAdmin);
      return response.data['isAdmin'] ?? response.data['data'] ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<FamilyInvitationModel>> getPendingApprovals() async {
    final response = await apiClient.get(ApiEndpoints.familyPendingApprovals);
    final data = response.data['data'] ?? response.data;
    if (data is List) {
      return data.map((json) => FamilyInvitationModel.fromJson(json)).toList();
    }
    return [];
  }

  @override
  Future<void> approveInvitation(String invitationId) async {
    await apiClient.post(ApiEndpoints.approveFamilyInvitation(invitationId));
  }

  @override
  Future<void> declineApproval(String invitationId) async {
    await apiClient.post(ApiEndpoints.declineFamilyApproval(invitationId));
  }

  @override
  Future<void> promoteToAdmin(String userId) async {
    await apiClient.post(ApiEndpoints.promoteFamilyMember(userId));
  }

  @override
  Future<void> demoteFromAdmin(String userId) async {
    await apiClient.post(ApiEndpoints.demoteFamilyMember(userId));
  }

  @override
  Future<void> removeFamilyMember(String userId) async {
    await apiClient.delete(ApiEndpoints.removeFamilyMember(userId));
  }

  @override
  Future<FamilyInvitationModel> sendSMSInvite(
    String phoneNumber,
    String relationship,
  ) async {
    final response = await apiClient.post(
      ApiEndpoints.familyInvitationsSms,
      data: {'phoneNumber': phoneNumber, 'relationship': relationship},
    );
    final data = response.data['data'] ?? response.data;
    if (data is Map<String, dynamic>) {
      return FamilyInvitationModel.fromJson(data);
    }
    if (response.data is Map<String, dynamic>) {
      return FamilyInvitationModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    }
    return FamilyInvitationModel(id: '', relationship: relationship);
  }

  @override
  Future<FamilyInvitationModel> sendEmailInvite(
    String email,
    String relationship, {
    String? name,
    String? targetUid,
  }) async {
    final response = await apiClient.post(
      ApiEndpoints.usersFamily,
      data: {
        'email': email,
        'relationship': relationship,
        if (targetUid != null) 'firebaseUid': targetUid,
      },
    );
    final data = response.data['data'] ?? response.data;
    if (data is Map<String, dynamic>) {
      return FamilyInvitationModel.fromJson(data);
    }
    if (response.data is Map<String, dynamic>) {
      return FamilyInvitationModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    }
    return FamilyInvitationModel(id: '', relationship: relationship);
  }

  @override
  Future<FamilyInvitationModel> createLinkInvite(String relationship) async {
    final response = await apiClient.post(
      ApiEndpoints.familyInvitationsLink,
      data: {'relationship': relationship},
    );
    final data = response.data['data'] ?? response.data;
    if (data is Map<String, dynamic>) {
      return FamilyInvitationModel.fromJson(data);
    }
    if (response.data is Map<String, dynamic>) {
      return FamilyInvitationModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    }
    return FamilyInvitationModel(id: '', relationship: relationship);
  }

  @override
  Future<FamilyInvitationModel> createQRInvite(String relationship) async {
    final response = await apiClient.post(
      ApiEndpoints.familyInvitationsQr,
      data: {'relationship': relationship},
    );
    final data = response.data['data'] ?? response.data;
    if (data is Map<String, dynamic>) {
      return FamilyInvitationModel.fromJson(data);
    }
    if (response.data is Map<String, dynamic>) {
      return FamilyInvitationModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    }
    return FamilyInvitationModel(id: '', relationship: relationship);
  }

  @override
  Future<List<FamilyInvitationModel>> getFamilyInvitations() async {
    final response = await apiClient.get(ApiEndpoints.familyInvitations);
    final data = response.data['data'] ?? response.data;
    if (data is List) {
      return data.map((json) => FamilyInvitationModel.fromJson(json)).toList();
    }
    return [];
  }

  @override
  Future<void> acceptFamilyInvite(String invitationId) async {
    await apiClient.post(ApiEndpoints.acceptFamilyInvite(invitationId));
  }

  @override
  Future<void> declineFamilyInvite(String invitationId) async {
    await apiClient.post(ApiEndpoints.declineFamilyInvite(invitationId));
  }
}
