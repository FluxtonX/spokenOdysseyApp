import '../entities/legacy_settings_entity.dart';

abstract class SettingsRepository {
  Future<LegacySettingsEntity> getLegacySettings();
  Future<LegacySettingsEntity> updateLegacySettings({
    required bool isEnabled,
    String? legacyContactId,
    required String inactivityPeriod,
    String? note,
  });
}
