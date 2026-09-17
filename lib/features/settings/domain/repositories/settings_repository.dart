import '../entities/legacy_settings_entity.dart';

abstract class SettingsRepository {
  Future<LegacySettingsEntity> getLegacySettings();
  Future<LegacySettingsEntity> updateLegacySettings({
    required bool isEnabled,
    String? legacyContactId,
    required String inactivityPeriod,
    String? note,
  });
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
  Future<Map<String, dynamic>> getNotificationPreferences();
  Future<Map<String, dynamic>> updateNotificationPreferences(
    Map<String, dynamic> preferences,
  );
  Future<List<Map<String, dynamic>>> getActiveSessions();
  Future<void> revokeSession(String sessionId);
  Future<void> updatePrivacySettings({
    String? defaultEntryPrivacy,
    String? profileVisibility,
  });
  Future<Map<String, dynamic>> getMfaStatus();
  Future<Map<String, dynamic>> setupMfa();
  Future<void> verifyMfaSetup(String code);
  Future<void> disableMfa();
}
