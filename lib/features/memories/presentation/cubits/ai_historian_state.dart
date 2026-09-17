import '../../domain/entities/ai_chat_message.dart';

abstract class AiHistorianState {
  const AiHistorianState();
}

class AiHistorianInitial extends AiHistorianState {
  const AiHistorianInitial();
}

class AiHistorianLoading extends AiHistorianState {
  final List<AiChatMessageEntity> messages;
  const AiHistorianLoading(this.messages);
}

class AiHistorianLoaded extends AiHistorianState {
  final List<AiChatMessageEntity> messages;
  const AiHistorianLoaded(this.messages);
}

class AiHistorianError extends AiHistorianState {
  final String message;
  final List<AiChatMessageEntity> messages;
  const AiHistorianError(this.message, this.messages);
}
