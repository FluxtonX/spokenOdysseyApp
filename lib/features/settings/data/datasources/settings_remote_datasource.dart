import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../models/legacy_settings_model.dart';

abstract class SettingsRemoteDataSource {
  Future<LegacySettingsModel> getLegacySettings();
  Future<LegacySettingsModel> updateLegacySettings({
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
  Future<Map<String, dynamic>> getInsightsSummary();
  Future<void> updatePrivacySettings({
    String? defaultEntryPrivacy,
    String? profileVisibility,
  });
  Future<Map<String, dynamic>> getMfaStatus();
  Future<Map<String, dynamic>> setupMfa();
  Future<void> verifyMfaSetup(String code);
  Future<void> disableMfa();
}

class SettingsRemoteDataSourceImpl implements SettingsRemoteDataSource {
  final ApiClient apiClient;

  SettingsRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<LegacySettingsModel> getLegacySettings() async {
    final response = await apiClient.get(ApiEndpoints.legacyAccess);
    final data = response.data['data'] ?? response.data;
    if (data is Map) {
      return LegacySettingsModel.fromJson(data as Map<String, dynamic>);
    }
    return LegacySettingsModel.fromJson({});
  }

  @override
  Future<LegacySettingsModel> updateLegacySettings({
    required bool isEnabled,
    String? legacyContactId,
    required String inactivityPeriod,
    String? note,
  }) async {
    final response = await apiClient.put(
      ApiEndpoints.legacyAccess,
      data: {
        'isEnabled': isEnabled,
        if (legacyContactId != null) 'legacyContactId': legacyContactId,
        'inactivityPeriod': inactivityPeriod,
        if (note != null) 'note': note,
      },
    );
    final data = response.data['data'] ?? response.data;
    return LegacySettingsModel.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await apiClient.put(
      ApiEndpoints.changePassword,
      data: {'currentPassword': currentPassword, 'newPassword': newPassword},
    );
  }

  @override
  Future<Map<String, dynamic>> getNotificationPreferences() async {
    final response = await apiClient.get(ApiEndpoints.notificationPreferences);
    final data = response.data['data'] ?? response.data;
    if (data is Map<String, dynamic>) return data;
    return {};
  }

  @override
  Future<Map<String, dynamic>> updateNotificationPreferences(
    Map<String, dynamic> preferences,
  ) async {
    final response = await apiClient.put(
      ApiEndpoints.notificationPreferences,
      data: preferences,
    );
    final data = response.data['data'] ?? response.data;
    if (data is Map<String, dynamic>) return data;
    return preferences;
  }

  @override
  Future<List<Map<String, dynamic>>> getActiveSessions() async {
    final response = await apiClient.get(ApiEndpoints.activeSessions);
    final rawList = response.data['sessions'] ?? response.data['data'] ?? [];
    if (rawList is List) {
      return rawList.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  @override
  Future<void> revokeSession(String sessionId) async {
    await apiClient.delete('${ApiEndpoints.activeSessions}/$sessionId');
  }

  @override
  Future<Map<String, dynamic>> getInsightsSummary() async {
    final response = await apiClient.get(ApiEndpoints.insightsSummary);
    final data = response.data['data'] ?? response.data;
    return data is Map<String, dynamic> ? data : {};
  }

  @override
  Future<void> updatePrivacySettings({
    String? defaultEntryPrivacy,
    String? profileVisibility,
  }) async {
    await apiClient.put(
      ApiEndpoints.updateProfile,
      data: {
        if (defaultEntryPrivacy != null) 'defaultPrivacy': defaultEntryPrivacy,
        if (profileVisibility != null) 'profileVisibility': profileVisibility,
      },
    );
  }

  @override
  Future<Map<String, dynamic>> getMfaStatus() async {
    final response = await apiClient.get(ApiEndpoints.mfaStatus);
    return response.data['data'] as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> setupMfa() async {
    final response = await apiClient.post(ApiEndpoints.mfaSetup);
    return response.data['data'] as Map<String, dynamic>;
  }

  @override
  Future<void> verifyMfaSetup(String code) async {
    await apiClient.post(ApiEndpoints.mfaVerifySetup, data: {'code': code});
  }

  @override
  Future<void> disableMfa() async {
    await apiClient.post(ApiEndpoints.mfaDisable);
  }
}
