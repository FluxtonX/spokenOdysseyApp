import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../error/exceptions.dart';
import '../storage/secure_storage_service.dart';
import '../di/service_locator.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';

class ApiClient {
  final Dio dio;
  final SecureStorageService storageService;

  ApiClient({Dio? dioClient, required this.storageService})
    : dio =
          dioClient ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
              headers: {'Content-Type': 'application/json'},
            ),
          ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await storageService.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          debugPrint('🌐 [API Request] ${options.method} -> ${options.uri}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint(
            '✅ [API Response ${response.statusCode}] ${response.requestOptions.uri}',
          );
          return handler.next(response);
        },
        onError: (DioException error, handler) {
          final response = error.response;
          debugPrint(
            '❌ [API Error ${response?.statusCode}] ${error.requestOptions.uri}',
          );
          debugPrint('   Payload: ${response?.data}');

          if (response?.statusCode == 401 ||
              response?.statusCode == 403 ||
              (response?.data is Map &&
                  (response?.data['message']?.toString().toLowerCase().contains('jwt expired') == true ||
                   response?.data['error']?.toString().toLowerCase().contains('jwt expired') == true))) {
             sl<AuthCubit>().signOut();
          }

          String message = 'An unexpected server error occurred';
          if (response?.data != null && response?.data is Map) {
            final data = response?.data as Map;
            message = data['message'] ?? data['error'] ?? message;
          } else if (error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.receiveTimeout) {
            message =
                'Connection timed out. Please check your internet connection.';
          } else if (error.type == DioExceptionType.connectionError) {
            message =
                'Could not connect to server. Please ensure backend is accessible.';
          }

          return handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              response: error.response,
              error: ServerException(message, statusCode: response?.statusCode),
              type: error.type,
            ),
          );
        },
      ),
    );
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await dio.get(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Exception _handleDioError(DioException e) {
    if (e.error is ServerException) {
      return e.error as ServerException;
    }
    return ServerException(
      e.message ?? 'Network connection error',
      statusCode: e.response?.statusCode,
    );
  }
}
