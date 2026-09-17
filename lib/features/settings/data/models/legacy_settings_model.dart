import '../../domain/entities/legacy_settings_entity.dart';

class LegacySettingsModel extends LegacySettingsEntity {
  const LegacySettingsModel({
    required super.id,
    required super.userId,
    super.administratorId,
    required super.administratorName,
    required super.releaseCondition,
    required super.familyCircleAccess,
    required super.publicProfile,
    required super.isReleased,
    super.releasedAt,
  });

  factory LegacySettingsModel.fromJson(Map<String, dynamic> json) {
    return LegacySettingsModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      administratorId: json['administratorId'] as String?,
      administratorName: json['administratorName'] as String? ?? 'Sarah Murphy',
      releaseCondition:
          json['releaseCondition'] as String? ?? 'After verified passing',
      familyCircleAccess:
          json['familyCircleAccess'] as String? ?? 'Full archive',
      publicProfile: json['publicProfile'] as String? ?? 'Remain public',
      isReleased: json['isReleased'] as bool? ?? false,
      releasedAt: json['releasedAt'] != null
          ? DateTime.parse(json['releasedAt'])
          : null,
    );
  }
}
