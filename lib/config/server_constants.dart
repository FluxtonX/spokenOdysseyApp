class ServerConstants {
  // EC2 production endpoint is served through nginx on port 80.
  static const String prodBaseUrl = 'http://13.206.196.136';

  static const String localBaseUrl = 'http://192.168.1.7:5001';

  static const Duration connectTimeout = Duration(seconds: 12);
  static const Duration receiveTimeout = Duration(seconds: 12);
  static const Duration sendTimeout = Duration(seconds: 12);

  static const String baseUrl = prodBaseUrl;
}
