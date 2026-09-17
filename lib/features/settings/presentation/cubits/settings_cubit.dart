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

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await repository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updatePrivacySettings({
    String? defaultEntryPrivacy,
    String? profileVisibility,
  }) async {
    try {
      await repository.updatePrivacySettings(
        defaultEntryPrivacy: defaultEntryPrivacy,
        profileVisibility: profileVisibility,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> getNotificationPreferences() async {
    try {
      return await repository.getNotificationPreferences();
    } catch (e) {
      return {
        'push': true,
        'email': true,
        'familyUpdates': true,
        'communityLikes': true,
      };
    }
  }

  Future<bool> updateNotificationPreferences(
    Map<String, dynamic> preferences,
  ) async {
    try {
      await repository.updateNotificationPreferences(preferences);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getActiveSessions() async {
    try {
      return await repository.getActiveSessions();
    } catch (e) {
      return [];
    }
  }

  Future<bool> revokeSession(String sessionId) async {
    try {
      await repository.revokeSession(sessionId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> setupMfa() async {
    try {
      return await repository.setupMfa();
    } catch (e) {
      return null;
    }
  }

  Future<bool> verifyMfaSetup(String code) async {
    try {
      await repository.verifyMfaSetup(code);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> disableMfa() async {
    try {
      await repository.disableMfa();
      return true;
    } catch (e) {
      return false;
    }
  }
}
