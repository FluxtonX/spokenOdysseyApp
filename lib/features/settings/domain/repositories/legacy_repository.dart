import '../entities/legacy_settings_entity.dart';

abstract class LegacyRepository {
  Future<LegacySettingsEntity> getLegacySettings();
  Future<LegacySettingsEntity> updateLegacySettings(
    Map<String, dynamic> settingsData,
  );
  Future<void> requestVaultRelease({
    required String legacyUserId,
    required String reason,
  });
  Future<List<dynamic>> getVaultMemories();
  Future<List<dynamic>> getPendingRequests();
  Future<List<dynamic>> getFamilyVaults();
  Future<void> approveRelease(String requestId);
  Future<void> rejectRelease(String requestId, {String? reason});
}
