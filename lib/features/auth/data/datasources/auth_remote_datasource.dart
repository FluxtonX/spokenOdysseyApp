import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';

abstract class AuthRemoteDataSource {
  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  });
  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
  });
  Future<Map<String, dynamic>> googleLogin({
    required String idToken,
  });
  Future<void> forgotPassword({required String email});
  Future<bool> verifyOtp({required String email, required String otp});
  Future<void> resetPassword({
    required String email,
    required String newPassword,
    required String token,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    final response = await apiClient.post(
      ApiEndpoints.login,
      data: {'email': email, 'password': password},
    );
    return response.data;
  }

  @override
  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
  }) async {
    final response = await apiClient.post(
      ApiEndpoints.register,
      data: {'email': email, 'password': password},
    );
    return response.data;
  }

  @override
  Future<Map<String, dynamic>> googleLogin({
    required String idToken,
  }) async {
    final response = await apiClient.post(
      '${ApiEndpoints.baseUrl}/auth/google',
      data: {'idToken': idToken, 'googleToken': idToken},
    );
    return response.data;
  }

  @override
  Future<void> forgotPassword({required String email}) async {
    await apiClient.post(ApiEndpoints.forgotPassword, data: {'email': email});
  }

  @override
  Future<bool> verifyOtp({required String email, required String otp}) async {
    final response = await apiClient.post(
      ApiEndpoints.verifyOtp,
      data: {'email': email, 'otp': otp},
    );
    return response.data['success'] ?? true;
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String newPassword,
    required String token,
  }) async {
    await apiClient.post(
      ApiEndpoints.resetPassword,
      data: {'email': email, 'newPassword': newPassword, 'token': token},
    );
  }
}
