import 'package:dio/dio.dart';

class ServerException implements Exception {
  final String message;
  final int? statusCode;
  ServerException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class CacheException implements Exception {
  final String message;
  CacheException(this.message);

  @override
  String toString() => message;
}

class NetworkException implements Exception {
  final String message;
  NetworkException([this.message = 'No Internet Connection']);

  @override
  String toString() => message;
}

class ErrorParser {
  /// True when the request never reached the server (no internet, DNS
  /// failure, timeout). Such errors must never be treated as "signed out".
  static bool isNetworkError(dynamic e) {
    if (e is NetworkException) return true;
    if (e is DioException) return e.error is NetworkException;
    return false;
  }

  static String extractMessage(dynamic e) {
    if (e is ServerException) return e.message;
    if (e is CacheException) return e.message;
    if (e is NetworkException) return e.message;
    if (e is DioException &&
        (e.error is ServerException || e.error is NetworkException)) {
      return e.error.toString();
    }

    // Support failures if passed dynamically
    if (e.toString().startsWith('Instance of \'') && e.toString().contains('Failure')) {
      // Basic fallback for failures if dynamic typing hides fields
    }

    final msg = e.toString();
    if (msg.startsWith('Exception: ')) {
      return msg.substring(11);
    }
    return msg;
  }
}
