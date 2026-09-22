import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/repositories/settings_repository.dart';

// ── States ────────────────────────────────────────────────────────────────────

abstract class InsightsState {}

class InsightsInitial extends InsightsState {}

class InsightsLoading extends InsightsState {}

class InsightsLoaded extends InsightsState {
  final Map<String, dynamic> data;
  InsightsLoaded(this.data);

  // Convenience getters
  Map<String, dynamic> get stats =>
      (data['stats'] as Map<String, dynamic>?) ?? {};
  int get legacyScore => (data['legacyScore'] as num?)?.toInt() ?? 0;
  String get lifeSummary =>
      data['lifeSummary'] as String? ??
      'Your story is being woven — keep adding memories to your archive.';
  List<Map<String, dynamic>> get lifeThemes =>
      ((data['lifeThemes'] as List?) ?? [])
          .whereType<Map<String, dynamic>>()
          .toList();
  List<Map<String, dynamic>> get insights => ((data['insights'] as List?) ?? [])
      .whereType<Map<String, dynamic>>()
      .toList();
  List<Map<String, dynamic>> get wordCloud =>
      ((data['wordCloud'] as List?) ?? [])
          .whereType<Map<String, dynamic>>()
          .toList();
  List<Map<String, dynamic>> get peopleInArchive =>
      ((data['peopleInArchive'] as List?) ?? [])
          .whereType<Map<String, dynamic>>()
          .toList();
  Map<String, dynamic> get emotionalLandscape =>
      (data['emotionalLandscape'] as Map<String, dynamic>?) ?? {};
}

class InsightsError extends InsightsState {
  final String message;
  InsightsError(this.message);
}

// ── Cubit ─────────────────────────────────────────────────────────────────────

class InsightsCubit extends Cubit<InsightsState> {
  final SettingsRepository _repository;

  InsightsCubit({required SettingsRepository repository})
    : _repository = repository,
      super(InsightsInitial());

  Future<void> loadInsights() async {
    try {
      emit(InsightsLoading());
      final data = await _repository.getInsightsSummary();
      if (!isClosed) emit(InsightsLoaded(data));
    } catch (e) {
      if (!isClosed) emit(InsightsError(ErrorParser.extractMessage(e)));
    }
  }
}
