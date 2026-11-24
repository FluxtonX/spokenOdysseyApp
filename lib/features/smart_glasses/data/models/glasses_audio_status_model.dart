import '../../domain/entities/glasses_audio_status.dart';

class GlassesAudioStatusModel {
  GlassesAudioStatusModel._();

  static GlassesAudioStatus fromMap(Map<String, dynamic> map) {
    final state = GlassesAudioState.values.firstWhere(
      (s) => s.name == map['state'],
      orElse: () => GlassesAudioState.unknown,
    );
    return GlassesAudioStatus(
      state: state,
      name: map['name'] as String? ?? '',
      address: map['address'] as String? ?? '',
      media: map['media'] == true,
      calls: map['calls'] == true,
      failReason: map['reason'] as String? ?? '',
    );
  }
}
