import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../models/legacy_settings_model.dart';

abstract class LegacyRemoteDataSource {
  Future<LegacySettingsModel> getLegacySettings();
  Future<LegacySettingsModel> updateLegacySettings(
    Map<String, dynamic> settingsData,
  );
  Future<void> requestVaultRelease({
    required String legacyUserId,
    required String reason,
  });
  Future<List<dynamic>> getVaultMemories();
}

class LegacyRemoteDataSourceImpl implements LegacyRemoteDataSource {
  final ApiClient apiClient;

  LegacyRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<LegacySettingsModel> getLegacySettings() async {
    final response = await apiClient.get(ApiEndpoints.legacyAccess);
    final data = response.data['data'] ?? response.data;
    return LegacySettingsModel.fromJson(data);
  }

  @override
  Future<LegacySettingsModel> updateLegacySettings(
    Map<String, dynamic> settingsData,
  ) async {
    final response = await apiClient.put(
      ApiEndpoints.legacyAccess,
      data: settingsData,
    );
    final data = response.data['data'] ?? response.data;
    return LegacySettingsModel.fromJson(data);
  }

  @override
  Future<void> requestVaultRelease({
    required String legacyUserId,
    required String reason,
  }) async {
    await apiClient.post(
      ApiEndpoints.legacyRequestRelease,
      data: {'legacyUserId': legacyUserId, 'reason': reason},
    );
  }

  @override
  Future<List<dynamic>> getVaultMemories() async {
    final response = await apiClient.get(ApiEndpoints.legacyVaultMemories);
    final data = response.data['data'] ?? response.data;
    return data is List ? data : [];
  }
}
