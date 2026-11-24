import 'dart:async';
import 'dart:io' show HttpException, SocketException;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/api_endpoints.dart';
import '../error/exceptions.dart';
import '../storage/secure_storage_service.dart';
import 'network_info.dart';

class ApiClient {
  final Dio dio;
  final SecureStorageService storageService;
  final NetworkInfo? networkInfo;

  /// Called only when the server has really rejected the session
  /// (confirmed 401). Never called for offline / timeout errors.
  VoidCallback? onUnauthorized;

  /// Request flag for the session check itself, so it can't trigger another.
  static const String _skipAuthCheckKey = 'skipAuthCheck';
  Future<void>? _sessionCheck;

  ApiClient({Dio? dioClient, required this.storageService, this.networkInfo})
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
          networkInfo?.reportReachable();
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

          // No internet / DNS failure / timeout: the server never answered,
          // so this says nothing about the session. Keep the user signed in.
          if (_isNetworkFailure(error)) {
            networkInfo?.reportUnreachable();
            return handler.reject(
              DioException(
                requestOptions: error.requestOptions,
                error: NetworkException(_networkFailureMessage(error)),
                type: error.type,
              ),
            );
          }

          if (response != null) networkInfo?.reportReachable();

          // A 401 may be a real session rejection or just an endpoint saying
          // "wrong password". It is verified before signing anyone out.
          // 403 = business logic "forbidden" (e.g. QR invite not targeted at
          // you) — it must NOT log the user out.
          if (_isAuthRejection(response)) {
            _handleAuthRejection(error.requestOptions);
          }

          String message = 'An unexpected server error occurred';
          if (response?.data != null && response?.data is Map) {
            final data = response?.data as Map;
            message = (data['message'] ?? data['error'] ?? message).toString();
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
    final inner = e.error;
    if (inner is ServerException) return inner;
    if (inner is NetworkException) return inner;
    return ServerException(
      e.message ?? 'Network connection error',
      statusCode: e.response?.statusCode,
    );
  }

  /// True when the request never got a response from the server.
  static bool _isNetworkFailure(DioException e) {
    if (e.response != null) return false;
    switch (e.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return true;
      case DioExceptionType.unknown:
        final inner = e.error;
        return inner is SocketException ||
            inner is HttpException ||
            inner is TimeoutException;
      default:
        return false;
    }
  }

  static String _networkFailureMessage(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out. Please check your internet connection.';
      default:
        return "You're offline. Please check your internet connection.";
    }
  }

  static bool _isAuthRejection(Response? response) {
    if (response == null) return false;
    if (response.statusCode == 401) return true;
    final data = response.data;
    if (data is Map) {
      final text = '${data['message'] ?? ''} ${data['error'] ?? ''}'
          .toLowerCase();
      return text.contains('jwt expired');
    }
    return false;
  }

  void _handleAuthRejection(RequestOptions failedRequest) {
    if (failedRequest.extra[_skipAuthCheckKey] == true) return;
    // Requests without our token (e.g. wrong password on the sign-in form)
    // can't mean the session expired.
    final sentAuth = failedRequest.headers['Authorization']?.toString() ?? '';
    if (sentAuth.isEmpty) return;
    // Several requests failing together share one check (one sign-out).
    _sessionCheck ??= _signOutIfSessionRejected(
      sentAuth,
    ).whenComplete(() => _sessionCheck = null);
  }

  /// Asks the server whether the current session is still valid and signs
  /// out only if it answers 401. Endpoint-specific 401s (e.g. "incorrect
  /// password" on MFA settings) and network errors keep the user signed in.
  Future<void> _signOutIfSessionRejected(String sentAuth) async {
    try {
      final token = await storageService.getToken();
      // Already signed out, or the user signed in again meanwhile.
      if (token == null || token.isEmpty || sentAuth != 'Bearer $token') {
        return;
      }
      await dio.get(
        ApiEndpoints.me,
        options: Options(extra: {_skipAuthCheckKey: true}),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        debugPrint('🔒 [Auth] Session rejected by server — signing out');
        onUnauthorized?.call();
      }
    } catch (_) {
      // Unexpected local error: stay signed in.
    }
  }
}
