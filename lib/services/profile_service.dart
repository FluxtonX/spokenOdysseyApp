import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../config/server_constants.dart';

class ProfileService {
  ProfileService()
    : _dio = Dio(
        BaseOptions(
          baseUrl: ServerConstants.baseUrl,
          connectTimeout: ServerConstants.connectTimeout,
          receiveTimeout: ServerConstants.receiveTimeout,
          sendTimeout: ServerConstants.sendTimeout,
        ),
      ) {
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: false,
          responseBody: false,
          requestHeader: false,
          responseHeader: false,
        ),
      );
    }
  }

  final Dio _dio;
  static Map<String, dynamic>? _cachedProfile;
  static Future<Map<String, dynamic>?>? _inFlightProfile;
  static String? _cachedUid;

  Future<Map<String, dynamic>?> fetchMyProfile({
    bool forceRefresh = false,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('Please sign in again.');
    }

    final uid = currentUser.uid;
    if (forceRefresh || _cachedUid != uid) {
      invalidateCache();
      _cachedUid = uid;
    }

    if (_cachedProfile != null) {
      return Map<String, dynamic>.from(_cachedProfile!);
    }

    if (_inFlightProfile != null) {
      final profile = await _inFlightProfile!;
      return profile == null ? null : Map<String, dynamic>.from(profile);
    }

    _inFlightProfile = _fetchProfileFromNetwork();

    try {
      final profile = await _inFlightProfile!;
      _cachedProfile = profile == null
          ? null
          : Map<String, dynamic>.from(profile);
      return profile == null ? null : Map<String, dynamic>.from(profile);
    } finally {
      _inFlightProfile = null;
    }
  }

  Future<Map<String, dynamic>?> _fetchProfileFromNetwork() async {
    try {
      final response = await _dio.get(
        '/api/auth/me',
        options: await _authorizedOptions(),
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is Map) {
        return Map<String, dynamic>.from(data['data'] as Map);
      }

      return null;
    } on DioException catch (error) {
      throw Exception(_extractMessage(error));
    }
  }

  Future<Map<String, dynamic>> updateProfile(
    Map<String, dynamic> payload, {
    File? profileImageFile,
  }) async {
    try {
      final requestData = profileImageFile == null
          ? payload
          : FormData.fromMap({
              ...payload,
              'profileImage': await MultipartFile.fromFile(
                profileImageFile.path,
                filename: profileImageFile.path.split('/').last,
              ),
            });

      final response = await _dio.put(
        '/api/auth/profile',
        data: requestData,
        options: await _authorizedOptions(
          isMultipart: profileImageFile != null,
        ),
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is Map) {
        final profile = Map<String, dynamic>.from(data['data'] as Map);
        _cachedUid = FirebaseAuth.instance.currentUser?.uid;
        _cachedProfile = Map<String, dynamic>.from(profile);
        return profile;
      }

      throw Exception('Profile response was invalid.');
    } on DioException catch (error) {
      throw Exception(_extractMessage(error));
    }
  }

  void invalidateCache() {
    _cachedProfile = null;
    _inFlightProfile = null;
  }

  Future<Options> _authorizedOptions({bool isMultipart = false}) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('Please sign in again.');
    }

    final token = await currentUser.getIdToken();

    return Options(
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': isMultipart
            ? 'multipart/form-data'
            : 'application/json',
      },
    );
  }

  String _extractMessage(DioException error) {
    final responseData = error.response?.data;
    if (responseData is Map<String, dynamic>) {
      final message = responseData['message']?.toString();
      if (message != null && message.isNotEmpty) {
        return message;
      }
    }

    return error.message ?? 'Something went wrong while loading profile data.';
  }
}
