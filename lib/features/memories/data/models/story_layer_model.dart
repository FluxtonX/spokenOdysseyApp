import '../../../../core/utils/media_url_formatter.dart';
import '../../../auth/data/models/user_model.dart';
import '../../domain/entities/story_layer_entity.dart';

class StoryLayerModel extends StoryLayerEntity {
  const StoryLayerModel({
    required super.id,
    required super.memoryId,
    required super.text,
    super.audioKey,
    super.audioUrl,
    super.audioDuration,
    super.author,
    required super.createdAt,
  });

  factory StoryLayerModel.fromJson(Map<String, dynamic> json) {
    final rawAudioKey = json['audioKey'] as String?;
    final rawAudioUrl = json['audioUrl'] as String?;
    final formattedAudio = MediaUrlFormatter.format(rawAudioUrl ?? rawAudioKey);

    return StoryLayerModel(
      id: json['id'] as String? ?? '',
      memoryId: json['memoryId'] as String? ?? '',
      text: json['text'] as String? ?? '',
      audioKey: rawAudioKey,
      audioUrl: formattedAudio,
      audioDuration: (json['audioDuration'] as num?)?.toDouble(),
      author: json['author'] != null
          ? UserModel.fromJson(json['author'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}
