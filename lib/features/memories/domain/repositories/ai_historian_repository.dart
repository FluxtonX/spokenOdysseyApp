import '../entities/ai_chat_message.dart';

abstract class AiHistorianRepository {
  Future<AiChatMessageEntity> askHistorian({
    required String message,
    required List<AiChatMessageEntity> history,
  });
}
