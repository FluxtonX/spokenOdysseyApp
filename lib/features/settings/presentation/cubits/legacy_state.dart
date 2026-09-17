import '../../domain/entities/legacy_settings_entity.dart';

abstract class LegacyState {
  const LegacyState();
}

class LegacyInitial extends LegacyState {
  const LegacyInitial();
}

class LegacyLoading extends LegacyState {
  const LegacyLoading();
}

class LegacyLoaded extends LegacyState {
  final LegacySettingsEntity settings;
  final List<dynamic> vaultMemories;
  const LegacyLoaded({required this.settings, required this.vaultMemories});
}

class LegacyError extends LegacyState {
  final String message;
  const LegacyError(this.message);
}
