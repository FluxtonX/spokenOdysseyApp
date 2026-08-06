import '../../domain/entities/legacy_settings_entity.dart';

class LegacySettingsModel extends LegacySettingsEntity {
  const LegacySettingsModel({
    super.isEnabled = false,
    super.legacyContactId,
    super.legacyContactName,
    super.inactivityPeriod = '6_months',
    super.note,
  });

  factory LegacySettingsModel.fromJson(Map<String, dynamic> json) {
    return LegacySettingsModel(
      isEnabled: json['isEnabled'] ?? json['enabled'] ?? false,
      legacyContactId: json['legacyContact']?['_id']?.toString() ?? json['legacyContactId']?.toString(),
      legacyContactName: json['legacyContact']?['displayName'] ?? json['legacyContactName'],
      inactivityPeriod: json['inactivityPeriod'] ?? '6_months',
      note: json['note'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isEnabled': isEnabled,
      'legacyContactId': legacyContactId,
      'inactivityPeriod': inactivityPeriod,
      'note': note,
    };
  }
}
