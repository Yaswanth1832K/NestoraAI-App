/// API endpoint constants for the AI microservice.
abstract final class ApiConstants {
  ApiConstants._();

  /// Base URL for the AI microservice (override via flavor/env).
  static const String baseUrl = String.fromEnvironment(
    'AI_SERVICE_URL',
    defaultValue: 'http://localhost:8000',
  );

  // Endpoints
  static const String naturalLanguageSearch = '/search/natural-language';
  static const String recommendations = '/recommendations';
  static const String pricePrediction = '/price/predict';
  static const String propertyChat = '/chat/property';
}
