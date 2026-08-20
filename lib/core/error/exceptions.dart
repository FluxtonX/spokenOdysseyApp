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
  static String extractMessage(dynamic e) {
    if (e is ServerException) return e.message;
    if (e is CacheException) return e.message;
    if (e is NetworkException) return e.message;
    
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
