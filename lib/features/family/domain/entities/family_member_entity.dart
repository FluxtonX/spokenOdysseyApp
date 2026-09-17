import 'package:spokenodyssey/features/auth/domain/entities/user.dart';

class FamilyMemberEntity {
  final String id;
  final User? user;
  final String
  relationship; // 'Parent', 'Child', 'Spouse', 'Sibling', 'Grandparent', etc.
  final String role; // 'admin' or 'member'
  final String? status; // 'accepted', 'pending'
  final String? joinedAt;

  const FamilyMemberEntity({
    required this.id,
    this.user,
    required this.relationship,
    this.role = 'member',
    this.status = 'accepted',
    this.joinedAt,
  });
}

class FamilyInvitationEntity {
  final String id;
  final String? inviterName;
  final String? inviterEmail;
  final String? inviterAvatar;
  final String? receiverName;
  final String? receiverAvatar;
  final String? email;
  final String relationship;
  final String? invitationToken;
  final String? inviteUrl;
  final String? qrCodeUrl;
  final String? method;
  final String status;
  final String? createdAt;
  final String? acceptedAt;

  const FamilyInvitationEntity({
    required this.id,
    this.inviterName,
    this.inviterEmail,
    this.inviterAvatar,
    this.receiverName,
    this.receiverAvatar,
    this.email,
    required this.relationship,
    this.invitationToken,
    this.inviteUrl,
    this.qrCodeUrl,
    this.method,
    this.status = 'pending',
    this.createdAt,
    this.acceptedAt,
  });
}
