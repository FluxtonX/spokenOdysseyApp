import '../../../../features/auth/domain/entities/user.dart';

class StoryLayerEntity {
  final String id;
  final String memoryId;
  final String text;
  final String? audioKey;
  final String? audioUrl;
  final double? audioDuration;
  final User? author;
  final DateTime createdAt;

  const StoryLayerEntity({
    required this.id,
    required this.memoryId,
    required this.text,
    this.audioKey,
    this.audioUrl,
    this.audioDuration,
    this.author,
    required this.createdAt,
  });
}
