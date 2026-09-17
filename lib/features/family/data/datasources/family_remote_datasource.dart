import 'package:spokenodyssey/features/memories/data/models/memory_model.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../models/family_member_model.dart';

abstract class FamilyRemoteDataSource {
  Future<List<FamilyMemberModel>> getFamilyMembers();
  Future<List<MemoryModel>> getFamilySharedMemories({bool forceRefresh = false});
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
  Future<String> validateInvitationToken(String token);
  Future<List<Map<String, dynamic>>> searchTaggableUsers(String query);
  Future<void> addDirectMember(String targetUserId, String relationship);
  Future<void> reactToMemory(String memoryId, String reactionType);
}

class FamilyRemoteDataSourceImpl implements FamilyRemoteDataSource {
  final ApiClient apiClient;
  List<MemoryModel>? _cachedSharedMemories;
  DateTime? _lastSharedMemoriesFetch;

  FamilyRemoteDataSourceImpl({required this.apiClient});

  /// Extract a list from a response's data field — handles both
  /// { success: true, data: [...] } and bare [...] shapes.
  List<dynamic> _extractList(dynamic responseData) {
    if (responseData is List) return responseData;
    if (responseData is Map) {
      final inner = responseData['data'];
      if (inner is List) return inner;
    }
    return [];
  }

  @override
  Future<List<FamilyMemberModel>> getFamilyMembers() async {
    // ── Step 1: Call /api/family-circle/members (same as web) ─────────────────
    // Backend response shape:
    //   { success: true, data: [{ id, name, email, avatar, role, relationship,
    //                             isAdmin, joinedAt, sharedCount }, ...] }
    // NOTE: User fields are FLAT (no nested `user` object) — FamilyMemberModel
    // handles this by falling back to UserModel.fromJson(json) when json['user']
    // is null.
    List<FamilyMemberModel> circleMembers = [];
    try {
      final response = await apiClient.get(ApiEndpoints.familyCircleMembers);
      final list = _extractList(response.data);
      circleMembers = list
          .whereType<Map<String, dynamic>>()
          .map((json) => FamilyMemberModel.fromJson(json))
          .where((m) => m.id.isNotEmpty)
          .toList();
    } catch (e) {
      // Log but don't fail yet — try the legacy endpoint below
    }

    // ── Step 2: Call /api/users/family (legacy FamilyConnection table) ────────
    // Web also imports getFamilyMembers from backend.js which calls this.
    // Merging both ensures we don't miss members who are in FamilyConnection
    // but not yet in FamilyMember (or vice versa).
    List<FamilyMemberModel> legacyMembers = [];
    try {
      final response = await apiClient.get(ApiEndpoints.usersFamily);
      final list = _extractList(response.data);
      legacyMembers = list
          .whereType<Map<String, dynamic>>()
          .map((json) => FamilyMemberModel.fromJson(json))
          .where((m) => m.id.isNotEmpty)
          .toList();
    } catch (_) {}

    // ── Step 3: Merge both lists, de-duplicating by member ID ─────────────────
    if (circleMembers.isEmpty && legacyMembers.isEmpty) return [];

    final seenIds = <String>{};
    final merged = <FamilyMemberModel>[];

    for (final m in circleMembers) {
      if (seenIds.add(m.id)) merged.add(m);
    }
    for (final m in legacyMembers) {
      final userId = m.user?.id ?? m.id;
      if (seenIds.add(userId)) merged.add(m);
    }

    return merged;
  }

  @override
  Future<List<MemoryModel>> getFamilySharedMemories({bool forceRefresh = false}) async {
    final now = DateTime.now();
    if (!forceRefresh &&
        _cachedSharedMemories != null &&
        _lastSharedMemoriesFetch != null &&
        now.difference(_lastSharedMemoriesFetch!) < const Duration(seconds: 45)) {
      return _cachedSharedMemories!;
    }

    final Map<String, MemoryModel> memoriesMap = {};

    final familySharedFuture = apiClient
        .get(ApiEndpoints.familySharedMemories)
        .then((response) {
      final list = _extractList(response.data);
      for (final json in list) {
        if (json is Map<String, dynamic>) {
          final m = MemoryModel.fromJson(json);
          memoriesMap[m.id] = m;
        }
      }
    }).catchError((_) => null);

    final memberMemoriesFuture = getFamilyMembers().then((members) async {
      final futures = members.map((member) async {
        final uid = member.user?.id;
        if (uid != null && uid.isNotEmpty) {
          try {
            final res = await apiClient.get(
              ApiEndpoints.memories,
              queryParameters: {'userId': uid},
            );
            final list = _extractList(res.data);
            for (final json in list) {
              if (json is Map<String, dynamic>) {
                final m = MemoryModel.fromJson(json);
                memoriesMap.putIfAbsent(m.id, () => m);
              }
            }
          } catch (_) {}
        }
      });
      await Future.wait(futures);
    }).catchError((_) => null);

    await Future.wait([familySharedFuture, memberMemoriesFuture]);

    final result = memoriesMap.values.toList();
    _cachedSharedMemories = result;
    _lastSharedMemoriesFetch = now;
    return result;
  }

  @override
  Future<bool> isFamilyAdmin() async {
    try {
      final response = await apiClient.get(ApiEndpoints.familyIsAdmin);
      // Backend route returns: { success: true, data: { isAdmin: true } }
      final raw = response.data;
      if (raw is Map) {
        // Try data.isAdmin first (correct shape from backend)
        final inner = raw['data'];
        if (inner is Map && inner.containsKey('isAdmin')) {
          return inner['isAdmin'] == true;
        }
        // Fallback: top-level isAdmin
        if (raw.containsKey('isAdmin')) {
          return raw['isAdmin'] == true;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<FamilyInvitationModel>> getPendingApprovals() async {
    final response = await apiClient.get(ApiEndpoints.familyPendingApprovals);
    final list = _extractList(response.data);
    return list
        .whereType<Map<String, dynamic>>()
        .map((json) => FamilyInvitationModel.fromJson(json))
        .toList();
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
    final raw = response.data;
    final data = (raw is Map ? raw['data'] ?? raw : raw);
    if (data is Map<String, dynamic>) return FamilyInvitationModel.fromJson(data);
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
    final raw = response.data;
    final data = (raw is Map ? raw['data'] ?? raw : raw);
    if (data is Map<String, dynamic>) return FamilyInvitationModel.fromJson(data);
    return FamilyInvitationModel(id: '', relationship: relationship);
  }

  @override
  Future<FamilyInvitationModel> createLinkInvite(String relationship) async {
    final response = await apiClient.post(
      ApiEndpoints.familyInvitationsLink,
      data: {'relationship': relationship},
    );
    final raw = response.data;
    final data = (raw is Map ? raw['data'] ?? raw : raw);
    if (data is Map<String, dynamic>) return FamilyInvitationModel.fromJson(data);
    return FamilyInvitationModel(id: '', relationship: relationship);
  }

  @override
  Future<FamilyInvitationModel> createQRInvite(String relationship) async {
    final response = await apiClient.post(
      ApiEndpoints.familyInvitationsQr,
      data: {'relationship': relationship},
    );
    final raw = response.data;
    final data = (raw is Map ? raw['data'] ?? raw : raw);
    if (data is Map<String, dynamic>) return FamilyInvitationModel.fromJson(data);
    return FamilyInvitationModel(id: '', relationship: relationship);
  }

  @override
  Future<List<FamilyInvitationModel>> getFamilyInvitations() async {
    final response = await apiClient.get(ApiEndpoints.familyInvitations);
    final list = _extractList(response.data);
    return list
        .whereType<Map<String, dynamic>>()
        .map((json) => FamilyInvitationModel.fromJson(json))
        .toList();
  }

  @override
  Future<void> acceptFamilyInvite(String invitationId) async {
    await apiClient.post(ApiEndpoints.acceptFamilyInvite(invitationId));
  }

  @override
  Future<void> declineFamilyInvite(String invitationId) async {
    await apiClient.post(ApiEndpoints.declineFamilyInvite(invitationId));
  }

  @override
  Future<String> validateInvitationToken(String token) async {
    final response = await apiClient.get(
      ApiEndpoints.validateInvitationToken(token),
    );
    final raw = response.data;
    // Try { data: { invitation: { id } } }
    if (raw is Map) {
      final data = raw['data'];
      if (data is Map) {
        final inv = data['invitation'];
        if (inv is Map && inv['id'] != null) return inv['id'].toString();
        if (data['id'] != null) return data['id'].toString();
        if (data['_id'] != null) return data['_id'].toString();
      }
      // top-level fallback
      if (raw['id'] != null) return raw['id'].toString();
    }
    throw Exception('Could not resolve invitation token to a valid ID.');
  }

  @override
  Future<List<Map<String, dynamic>>> searchTaggableUsers(String query) async {
    try {
      final response = await apiClient.get(ApiEndpoints.usersTaggable(query));
      final list = _extractList(response.data);
      return list.whereType<Map<String, dynamic>>().toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> addDirectMember(String targetUserId, String relationship) async {
    await apiClient.post(
      ApiEndpoints.familyCircleMembers,
      data: {
        'targetUserId': targetUserId,
        'relationship': relationship,
      },
    );
  }

  @override
  Future<void> reactToMemory(String memoryId, String reactionType) async {
    await apiClient.post(
      ApiEndpoints.memoryReact(memoryId),
      data: {'type': reactionType, 'reactionType': reactionType},
    );
  }
}
