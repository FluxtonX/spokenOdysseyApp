import '../datasources/legacy_remote_datasource.dart';
import '../../domain/entities/legacy_settings_entity.dart';
import '../../domain/repositories/legacy_repository.dart';

class LegacyRepositoryImpl implements LegacyRepository {
  final LegacyRemoteDataSource remoteDataSource;

  LegacyRepositoryImpl({required this.remoteDataSource});

  @override
  Future<LegacySettingsEntity> getLegacySettings() async {
    return await remoteDataSource.getLegacySettings();
  }

  @override
  Future<LegacySettingsEntity> updateLegacySettings(
    Map<String, dynamic> settingsData,
  ) async {
    return await remoteDataSource.updateLegacySettings(settingsData);
  }

  @override
  Future<void> requestVaultRelease({
    required String legacyUserId,
    required String reason,
  }) async {
    await remoteDataSource.requestVaultRelease(
      legacyUserId: legacyUserId,
      reason: reason,
    );
  }

  @override
  Future<List<dynamic>> getVaultMemories() async {
    return await remoteDataSource.getVaultMemories();
  }
}
