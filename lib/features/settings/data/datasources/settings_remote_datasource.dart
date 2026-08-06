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
    return const LegacySettingsModel();
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
}
