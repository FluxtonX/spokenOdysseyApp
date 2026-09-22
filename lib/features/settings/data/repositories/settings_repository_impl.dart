import '../../domain/entities/legacy_settings_entity.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_remote_datasource.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsRemoteDataSource remoteDataSource;

  SettingsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<LegacySettingsEntity> getLegacySettings() async {
    return await remoteDataSource.getLegacySettings();
  }

  @override
  Future<LegacySettingsEntity> updateLegacySettings({
    required bool isEnabled,
    String? legacyContactId,
    required String inactivityPeriod,
    String? note,
  }) async {
    return await remoteDataSource.updateLegacySettings(
      isEnabled: isEnabled,
      legacyContactId: legacyContactId,
      inactivityPeriod: inactivityPeriod,
      note: note,
    );
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await remoteDataSource.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  @override
  Future<Map<String, dynamic>> getNotificationPreferences() async {
    return await remoteDataSource.getNotificationPreferences();
  }

  @override
  Future<Map<String, dynamic>> updateNotificationPreferences(
    Map<String, dynamic> preferences,
  ) async {
    return await remoteDataSource.updateNotificationPreferences(preferences);
  }

  @override
  Future<List<Map<String, dynamic>>> getActiveSessions() async {
    return await remoteDataSource.getActiveSessions();
  }

  @override
  Future<void> revokeSession(String sessionId) async {
    await remoteDataSource.revokeSession(sessionId);
  }

  @override
  Future<Map<String, dynamic>> getInsightsSummary() async {
    return await remoteDataSource.getInsightsSummary();
  }

  @override
  Future<void> updatePrivacySettings({
    String? defaultEntryPrivacy,
    String? profileVisibility,
  }) async {
    await remoteDataSource.updatePrivacySettings(
      defaultEntryPrivacy: defaultEntryPrivacy,
      profileVisibility: profileVisibility,
    );
  }

  @override
  Future<Map<String, dynamic>> getMfaStatus() async {
    return await remoteDataSource.getMfaStatus();
  }

  @override
  Future<Map<String, dynamic>> setupMfa() async {
    return await remoteDataSource.setupMfa();
  }

  @override
  Future<void> verifyMfaSetup(String code) async {
    await remoteDataSource.verifyMfaSetup(code);
  }

  @override
  Future<void> disableMfa() async {
    await remoteDataSource.disableMfa();
  }
}
