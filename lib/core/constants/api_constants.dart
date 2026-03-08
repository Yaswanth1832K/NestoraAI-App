import 'package:house_rental/config/api_config.dart';

/// API endpoint constants for the AI microservice.
abstract final class ApiConstants {
  ApiConstants._();

  /// Base URL for the AI microservice.
  static const String baseUrl = ApiConfig.baseUrl;

  // Endpoints
  static const String naturalLanguageSearch = '/search/natural-language';
  static const String recommendations = '/recommendations';
  static const String pricePrediction = '/price/predict';
  static const String propertyChat = '/chat/property';
  // CRUD Endpoints (Synced with AI Service)
  static const String properties = '/properties';
  static const String visits = '/visits';
  static const String payments = '/payments';
  static const String coupons = '/coupons';
  static const String validateCoupon = '/coupons/validate';
  static const String useCoupon = '/coupons/use';

}
