import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  /// Base URL for the Nestora API.
  /// Uses a relative path on Web to work with Vercel/proxies.
  static String get baseUrl {
    if (kIsWeb) return "/api";
    return "http://localhost:8000";
  }

  /// Health check endpoint
  static const String healthEndpoint = "/health";
  
  /// Connection timeout in milliseconds
  static const int connectTimeout = 15000;
  
  /// Receive timeout in milliseconds
  static const int receiveTimeout = 15000;
}
