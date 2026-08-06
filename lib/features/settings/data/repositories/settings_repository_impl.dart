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
}
