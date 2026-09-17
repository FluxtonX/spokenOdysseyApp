import '../datasources/ai_historian_remote_datasource.dart';
import '../../domain/entities/ai_chat_message.dart';
import '../../domain/repositories/ai_historian_repository.dart';

class AiHistorianRepositoryImpl implements AiHistorianRepository {
  final AiHistorianRemoteDataSource remoteDataSource;

  AiHistorianRepositoryImpl({required this.remoteDataSource});

  @override
  Future<AiChatMessageEntity> askHistorian({
    required String message,
    required List<AiChatMessageEntity> history,
  }) async {
    final historyPayload = history
        .map(
          (m) => {'role': m.isUser ? 'user' : 'assistant', 'content': m.text},
        )
        .toList();

    final response = await remoteDataSource.askAiHistorian(
      message: message,
      history: historyPayload,
    );

    final answerText =
        response['answer'] ??
        response['message'] ??
        response['response'] ??
        "I analyzed your family memories archive, but couldn't generate a clear response.";
    final sources = response['sources'] is List ? response['sources'] : null;

    return AiChatMessageEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: answerText,
      isUser: false,
      timestamp: DateTime.now(),
      sources: sources,
    );
  }
}
