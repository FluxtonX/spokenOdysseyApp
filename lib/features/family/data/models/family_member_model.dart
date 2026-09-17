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

  /// Parses a member from the backend response.
  ///
  /// The `/api/family-circle/members` endpoint returns FLAT objects:
  ///   { id, name, email, avatar, role, relationship, isAdmin, joinedAt, sharedCount }
  ///
  /// The `/api/users/family` (legacy) endpoint returns serialized user objects:
  ///   { id, _id, email, displayName, photoURL, ... }
  ///
  /// Both are handled here by checking for a nested `user` object first,
  /// then falling back to reading user fields from the root JSON.
  factory FamilyMemberModel.fromJson(Map<String, dynamic> json) {
    // ── Determine the member's DB id ──────────────────────────────────────────
    // family-circle/members uses `id` (prisma UUID)
    // legacy endpoint uses `_id`, `id`, or `firebaseUid`
    final memberId =
        json['id']?.toString() ??
        json['_id']?.toString() ??
        json['firebaseUid']?.toString() ??
        json['userId']?.toString() ??
        '';

    // ── Resolve the relationship label ────────────────────────────────────────
    // family-circle/members: `relationship` is already the resolved display label
    // legacy: `relationship` or `relation` may be present
    final relationship =
        json['relationship']?.toString() ??
        json['relation']?.toString() ??
        'Family Member';

    // ── Normalise the role ────────────────────────────────────────────────────
    // Backend uses 'ADMIN' / 'MEMBER' (uppercase), map to lowercase for consistency
    final rawRole = (json['role']?.toString() ?? 'member').toLowerCase();
    final role = rawRole == 'admin' ? 'admin' : 'member';

    // ── Build the User object ─────────────────────────────────────────────────
    // If there is a nested `user` object (old admin-approval format) use it.
    // Otherwise the user fields are flat (family-circle/members format).
    UserModel user;
    if (json['user'] is Map<String, dynamic>) {
      user = UserModel.fromJson(json['user'] as Map<String, dynamic>);
    } else {
      // Flat shape from /api/family-circle/members or /api/users/family
      user = UserModel.fromJson({
        'id': json['id'] ?? json['_id'] ?? json['userId'] ?? '',
        'email': json['email'] ?? '',
        'displayName': json['name'] ?? json['displayName'] ?? '',
        'photoURL': json['avatar'] ?? json['photoURL'] ?? json['avatarUrl'],
        'firebaseUid': json['firebaseUid'] ?? json['uid'],
        // pass through any extra fields UserModel knows how to read
        ...json,
      });
    }

    return FamilyMemberModel(
      id: memberId,
      user: user,
      relationship: relationship,
      role: role,
      status: json['status']?.toString() ?? 'accepted',
      joinedAt: json['joinedAt']?.toString() ?? json['createdAt']?.toString(),
    );
  }
}

class FamilyInvitationModel extends FamilyInvitationEntity {
  const FamilyInvitationModel({
    required super.id,
    super.inviterName,
    super.inviterEmail,
    super.inviterAvatar,
    super.receiverName,
    super.receiverAvatar,
    super.email,
    required super.relationship,
    super.invitationToken,
    super.inviteUrl,
    super.qrCodeUrl,
    super.method,
    super.status = 'pending',
    super.createdAt,
    super.acceptedAt,
  });

  factory FamilyInvitationModel.fromJson(Map<String, dynamic> json) {
    // Some responses wrap in `invitation` or `data`
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

    final senderObj = raw['sender'] is Map ? raw['sender'] as Map : null;
    final receiverObj = raw['receiver'] is Map ? raw['receiver'] as Map : null;

    final parsedInviterName =
        senderObj?['displayName'] ??
        senderObj?['name'] ??
        raw['inviter']?['displayName'] ??
        raw['inviterName'] ??
        json['inviterName'];

    final parsedInviterEmail =
        senderObj?['email'] ??
        raw['inviter']?['email'] ??
        raw['inviterEmail'] ??
        json['inviterEmail'];

    final parsedInviterAvatar =
        senderObj?['photoURL'] ??
        senderObj?['avatar'] ??
        raw['inviter']?['photoURL'] ??
        raw['inviterAvatar'];

    final parsedReceiverName =
        raw['receiverName'] ??
        receiverObj?['displayName'] ??
        receiverObj?['name'] ??
        raw['email'] ??
        raw['phoneNumber'];

    final parsedReceiverAvatar =
        raw['receiverAvatar'] ??
        receiverObj?['photoURL'] ??
        receiverObj?['avatar'];

    return FamilyInvitationModel(
      id:
          raw['_id']?.toString() ??
          raw['id']?.toString() ??
          json['_id']?.toString() ??
          json['id']?.toString() ??
          '',
      inviterName: parsedInviterName?.toString(),
      inviterEmail: parsedInviterEmail?.toString(),
      inviterAvatar: parsedInviterAvatar?.toString(),
      receiverName: parsedReceiverName?.toString(),
      receiverAvatar: parsedReceiverAvatar?.toString(),
      email: raw['email']?.toString() ?? json['email']?.toString(),
      relationship:
          raw['relationship'] ?? json['relationship'] ?? 'Family Member',
      invitationToken: rawToken?.toString(),
      inviteUrl: computedInviteUrl,
      qrCodeUrl: raw['qrCodeUrl'] ?? raw['qrCode'] ?? json['qrCodeUrl'],
      method: raw['method']?.toString() ?? json['method']?.toString(),
      status: raw['status'] ?? json['status'] ?? 'pending',
      createdAt: raw['createdAt']?.toString() ?? json['createdAt']?.toString(),
      acceptedAt:
          raw['acceptedAt']?.toString() ?? json['acceptedAt']?.toString(),
    );
  }
}
