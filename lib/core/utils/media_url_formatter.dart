import '../constants/api_endpoints.dart';

class MediaUrlFormatter {
  MediaUrlFormatter._();

  static String? format(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    final trimmed = url.trim();

    if (trimmed.startsWith('data:') ||
        trimmed.startsWith('http://') ||
        trimmed.startsWith('https://') ||
        trimmed.startsWith('file://')) {
      return trimmed;
    }

    final apiBase = ApiEndpoints.baseUrl;
    final rootHost = apiBase.endsWith('/api')
        ? apiBase.substring(0, apiBase.length - 4)
        : apiBase;

    final path = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    return '$rootHost$path';
  }
}
