import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/legacy_settings_entity.dart';
import '../../domain/repositories/settings_repository.dart';

abstract class SettingsState {}

class SettingsInitial extends SettingsState {}
class SettingsLoading extends SettingsState {}
class SettingsLoaded extends SettingsState {
  final LegacySettingsEntity legacySettings;
  SettingsLoaded(this.legacySettings);
}
class SettingsError extends SettingsState {
  final String message;
  SettingsError(this.message);
}

class SettingsCubit extends Cubit<SettingsState> {
  final SettingsRepository repository;

  SettingsCubit({required this.repository}) : super(SettingsInitial());

  Future<void> loadSettings() async {
    try {
      emit(SettingsLoading());
      final settings = await repository.getLegacySettings();
      emit(SettingsLoaded(settings));
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }

  Future<void> updateLegacySettings({
    required bool isEnabled,
    String? legacyContactId,
    required String inactivityPeriod,
    String? note,
  }) async {
    try {
      final updated = await repository.updateLegacySettings(
        isEnabled: isEnabled,
        legacyContactId: legacyContactId,
        inactivityPeriod: inactivityPeriod,
        note: note,
      );
      emit(SettingsLoaded(updated));
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }
}
