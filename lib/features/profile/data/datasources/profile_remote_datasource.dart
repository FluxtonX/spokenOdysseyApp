import 'package:dio/dio.dart';
import 'package:spokenodyssey/features/auth/data/models/user_model.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';

abstract class ProfileRemoteDataSource {
  Future<UserModel> getMyProfile();
  Future<UserModel> getUserProfile(String userId);
  Future<UserModel> updateProfile({
    String? displayName,
    String? bio,
    String? location,
    String? relationship,
    String? avatarPath,
  });
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final ApiClient apiClient;

  ProfileRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<UserModel> getMyProfile() async {
    final response = await apiClient.get(ApiEndpoints.me);
    final data = response.data['data'] ?? response.data;
    return UserModel.fromJson(data);
  }

  @override
  Future<UserModel> getUserProfile(String userId) async {
    final response = await apiClient.get(ApiEndpoints.userProfileById(userId));
    final data = response.data['data'] ?? response.data;
    return UserModel.fromJson(data);
  }

  @override
  Future<UserModel> updateProfile({
    String? displayName,
    String? bio,
    String? location,
    String? relationship,
    String? avatarPath,
  }) async {
    final formDataMap = <String, dynamic>{
      if (displayName != null) 'displayName': displayName,
      if (bio != null) 'bio': bio,
      if (location != null) 'location': location,
      if (relationship != null) 'relationship': relationship,
    };

    if (avatarPath != null && avatarPath.isNotEmpty) {
      final fileName = avatarPath.split('/').last;
      formDataMap['avatar'] = await MultipartFile.fromFile(
        avatarPath,
        filename: fileName,
      );
    }

    final formData = FormData.fromMap(formDataMap);
    final response = await apiClient.put(
      ApiEndpoints.updateProfile,
      data: formData,
    );

    final data = response.data['data'] ?? response.data;
    return UserModel.fromJson(data);
  }
}
