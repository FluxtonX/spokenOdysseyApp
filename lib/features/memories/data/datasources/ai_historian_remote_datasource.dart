import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';

abstract class AiHistorianRemoteDataSource {
  Future<Map<String, dynamic>> askAiHistorian({
    required String message,
    List<Map<String, String>>? history,
  });
}

class AiHistorianRemoteDataSourceImpl implements AiHistorianRemoteDataSource {
  final ApiClient apiClient;

  AiHistorianRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<Map<String, dynamic>> askAiHistorian({
    required String message,
    List<Map<String, String>>? history,
  }) async {
    final response = await apiClient.post(
      ApiEndpoints.aiHistorianChat,
      data: {'message': message, if (history != null) 'history': history},
    );
    return response.data;
  }
}
