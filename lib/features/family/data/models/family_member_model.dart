import '../../../auth/data/models/user_model.dart';
import '../../domain/entities/family_member_entity.dart';

class FamilyMemberModel extends FamilyMemberEntity {
  const FamilyMemberModel({
    required super.id,
    super.user,
    required super.relationship,
    super.role = 'member',
    super.status = 'accepted',
    super.joinedAt,
  });

  factory FamilyMemberModel.fromJson(Map<String, dynamic> json) {
    return FamilyMemberModel(
      id:
          json['_id']?.toString() ??
          json['id']?.toString() ??
          json['firebaseUid']?.toString() ??
          '',
      user: json['user'] != null
          ? UserModel.fromJson(json['user'] as Map<String, dynamic>)
          : UserModel.fromJson(json),
      relationship: json['relationship'] ?? json['relation'] ?? 'Family Member',
      role: json['role'] ?? 'member',
      status: json['status'] ?? 'accepted',
      joinedAt: json['joinedAt'] ?? json['createdAt'],
    );
  }
}

class FamilyInvitationModel extends FamilyInvitationEntity {
  const FamilyInvitationModel({
    required super.id,
    super.inviterName,
    super.inviterEmail,
    required super.relationship,
    super.invitationToken,
    super.inviteUrl,
    super.qrCodeUrl,
    super.status = 'pending',
    super.createdAt,
  });

  factory FamilyInvitationModel.fromJson(Map<String, dynamic> json) {
    final raw = (json['invitation'] is Map)
        ? json['invitation'] as Map<String, dynamic>
        : (json['data'] is Map ? json['data'] as Map<String, dynamic> : json);

    final rawToken =
        raw['token'] ??
        raw['invitationToken'] ??
        json['invitationToken'] ??
        json['token'];
    final rawJoinLink =
        raw['joinLink'] ??
        raw['inviteUrl'] ??
        raw['url'] ??
        json['joinLink'] ??
        json['inviteUrl'];

    String? computedInviteUrl = rawJoinLink?.toString();
    if (computedInviteUrl == null && rawToken != null) {
      computedInviteUrl =
          'http://ec2-13-206-196-136.ap-south-1.compute.amazonaws.com:5001/invite/$rawToken';
    }

    return FamilyInvitationModel(
      id:
          raw['_id']?.toString() ??
          raw['id']?.toString() ??
          json['_id']?.toString() ??
          json['id']?.toString() ??
          '',
      inviterName:
          raw['inviter']?['displayName'] ??
          raw['inviterName'] ??
          json['inviterName'],
      inviterEmail:
          raw['inviter']?['email'] ??
          raw['inviterEmail'] ??
          json['inviterEmail'],
      relationship:
          raw['relationship'] ?? json['relationship'] ?? 'Family Member',
      invitationToken: rawToken?.toString(),
      inviteUrl: computedInviteUrl,
      qrCodeUrl: raw['qrCodeUrl'] ?? raw['qrCode'] ?? json['qrCodeUrl'],
      status: raw['status'] ?? json['status'] ?? 'pending',
      createdAt: raw['createdAt']?.toString() ?? json['createdAt']?.toString(),
    );
  }
}
