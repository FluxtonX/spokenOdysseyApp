import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/legacy_repository.dart';
import 'legacy_state.dart';

class LegacyCubit extends Cubit<LegacyState> {
  final LegacyRepository repository;

  LegacyCubit({required this.repository}) : super(const LegacyInitial());

  Future<void> loadLegacyData() async {
    emit(const LegacyLoading());
    try {
      final settings = await repository.getLegacySettings();
      final vaultMemories = await repository.getVaultMemories();
      emit(LegacyLoaded(settings: settings, vaultMemories: vaultMemories));
    } catch (e) {
      emit(LegacyError('Failed to load legacy settings: ${e.toString()}'));
    }
  }

  Future<void> updateSettings(Map<String, dynamic> settingsData) async {
    try {
      final updated = await repository.updateLegacySettings(settingsData);
      final currentVault = state is LegacyLoaded
          ? (state as LegacyLoaded).vaultMemories
          : [];
      emit(LegacyLoaded(settings: updated, vaultMemories: currentVault));
    } catch (e) {
      emit(LegacyError('Failed to update legacy settings: ${e.toString()}'));
    }
  }

  Future<void> requestRelease(String legacyUserId, String reason) async {
    try {
      await repository.requestVaultRelease(
        legacyUserId: legacyUserId,
        reason: reason,
      );
      loadLegacyData();
    } catch (e) {
      emit(LegacyError('Failed to request vault release: ${e.toString()}'));
    }
  }
}
