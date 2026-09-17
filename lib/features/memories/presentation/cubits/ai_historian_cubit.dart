import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/ai_chat_message.dart';
import '../../domain/repositories/ai_historian_repository.dart';
import 'ai_historian_state.dart';

class AiHistorianCubit extends Cubit<AiHistorianState> {
  final AiHistorianRepository repository;
  final List<AiChatMessageEntity> _messages = [];

  AiHistorianCubit({required this.repository})
    : super(const AiHistorianInitial()) {
    // Add default welcoming message
    _messages.add(
      AiChatMessageEntity(
        id: 'welcome',
        text:
            'Greetings! I am your AI Family Historian. Ask me anything about your recorded memories, family stories, or historical timeline!',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
    emit(AiHistorianLoaded(List.unmodifiable(_messages)));
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = AiChatMessageEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );

    _messages.add(userMessage);
    emit(AiHistorianLoading(List.unmodifiable(_messages)));

    try {
      final aiResponse = await repository.askHistorian(
        message: text.trim(),
        history: _messages,
      );
      _messages.add(aiResponse);
      emit(AiHistorianLoaded(List.unmodifiable(_messages)));
    } catch (e) {
      emit(
        AiHistorianError(
          'Failed to fetch answer from AI Historian: ${e.toString()}',
          List.unmodifiable(_messages),
        ),
      );
    }
  }

  void clearChat() {
    _messages.clear();
    _messages.add(
      AiChatMessageEntity(
        id: 'welcome_${DateTime.now().millisecondsSinceEpoch}',
        text:
            'Chat history cleared. How can I assist with your family archive today?',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
    emit(AiHistorianLoaded(List.unmodifiable(_messages)));
  }
}
