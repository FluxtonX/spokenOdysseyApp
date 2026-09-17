class AiChatMessageEntity {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<dynamic>? sources;

  const AiChatMessageEntity({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.sources,
  });
}
