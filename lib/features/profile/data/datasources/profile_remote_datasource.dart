import 'dart:convert';
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
    String? profession,
    String? location,
    String? birthDate,
    String? lifeMotto,
    List<String>? expertise,
    String? relationship,
    String? avatarPath,
    String? coverPath,
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
    String? profession,
    String? location,
    String? birthDate,
    String? lifeMotto,
    List<String>? expertise,
    String? relationship,
    String? avatarPath,
    String? coverPath,
  }) async {
    final formDataMap = <String, dynamic>{
      if (displayName != null) 'displayName': displayName,
      if (bio != null) 'bio': bio,
      if (profession != null) 'profession': profession,
      if (location != null) 'location': location,
      if (birthDate != null) 'birthDate': birthDate,
      if (lifeMotto != null) 'lifeMotto': lifeMotto,
      if (expertise != null) 'expertise': jsonEncode(expertise),
      if (relationship != null) 'relationship': relationship,
    };

    if (avatarPath != null && avatarPath.isNotEmpty) {
      final fileName = avatarPath.split('/').last;
      formDataMap['profileImage'] = await MultipartFile.fromFile(
        avatarPath,
        filename: fileName,
      );
    }

    if (coverPath != null && coverPath.isNotEmpty) {
      final fileName = coverPath.split('/').last;
      formDataMap['coverImage'] = await MultipartFile.fromFile(
        coverPath,
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
