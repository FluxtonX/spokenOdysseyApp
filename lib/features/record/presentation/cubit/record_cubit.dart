import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import '../../../../core/error/exceptions.dart';

enum RecordStatus { idle, recording, paused, stopped }

class RecordState {
  final RecordStatus status;
  final Duration duration;
  final String? recordedFilePath;
  final String? errorMessage;

  RecordState({
    required this.status,
    required this.duration,
    this.recordedFilePath,
    this.errorMessage,
  });

  factory RecordState.initial() => RecordState(
        status: RecordStatus.idle,
        duration: Duration.zero,
      );

  RecordState copyWith({
    RecordStatus? status,
    Duration? duration,
    String? recordedFilePath,
    String? errorMessage,
    bool clearError = false,
  }) {
    return RecordState(
      status: status ?? this.status,
      duration: duration ?? this.duration,
      recordedFilePath: recordedFilePath ?? this.recordedFilePath,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class RecordCubit extends Cubit<RecordState> {
  final AudioRecorder _recorder = AudioRecorder();
  Timer? _timer;

  RecordCubit() : super(RecordState.initial());

  Future<void> startRecording() async {
    try {
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        emit(state.copyWith(errorMessage: 'Microphone permission denied'));
        return;
      }

      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        emit(state.copyWith(errorMessage: 'Microphone permission missing'));
        return;
      }

      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/odyssey_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );

      _startTimer();
      emit(RecordState(
        status: RecordStatus.recording,
        duration: Duration.zero,
      ));
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to start recording: ${ErrorParser.extractMessage(e)}'));
    }
  }

  Future<void> pauseRecording() async {
    try {
      await _recorder.pause();
      _timer?.cancel();
      emit(state.copyWith(status: RecordStatus.paused));
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to pause recording: ${ErrorParser.extractMessage(e)}'));
    }
  }

  Future<void> resumeRecording() async {
    try {
      await _recorder.resume();
      _startTimer();
      emit(state.copyWith(status: RecordStatus.recording));
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to resume recording: ${ErrorParser.extractMessage(e)}'));
    }
  }

  Future<String?> stopRecording() async {
    try {
      _timer?.cancel();
      final path = await _recorder.stop();
      emit(state.copyWith(
        status: RecordStatus.stopped,
        recordedFilePath: path,
      ));
      return path;
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to stop recording: ${ErrorParser.extractMessage(e)}'));
      return null;
    }
  }

  void reset() {
    _timer?.cancel();
    emit(RecordState.initial());
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      emit(state.copyWith(duration: state.duration + const Duration(seconds: 1)));
    });
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    _recorder.dispose();
    return super.close();
  }
}
