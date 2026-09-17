class LegacySettingsEntity {
  final String id;
  final String userId;
  final String? administratorId;
  final String administratorName;
  final String releaseCondition;
  final String familyCircleAccess;
  final String publicProfile;
  final bool isReleased;
  final DateTime? releasedAt;

  const LegacySettingsEntity({
    required this.id,
    required this.userId,
    this.administratorId,
    required this.administratorName,
    required this.releaseCondition,
    required this.familyCircleAccess,
    required this.publicProfile,
    required this.isReleased,
    this.releasedAt,
  });
}
