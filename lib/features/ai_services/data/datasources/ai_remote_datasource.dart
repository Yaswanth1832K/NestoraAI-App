import 'package:house_rental/core/network/api_client.dart';
import 'package:house_rental/core/errors/exceptions.dart';
import 'package:house_rental/core/constants/api_constants.dart';

abstract interface class AIRemoteDataSource {
  Future<Map<String, dynamic>> naturalLanguageSearch({
    required String query,
  });

  Future<double> predictPrice({
    required String city,
    required double sqft,
    required int bedrooms,
    required int bathrooms,
  });

  Future<String> getRecommendations(Map<String, dynamic> data);
}

class AIRemoteDataSourceImpl implements AIRemoteDataSource {
  final ApiClient _apiClient;

  AIRemoteDataSourceImpl(this._apiClient);

  @override
  Future<Map<String, dynamic>> naturalLanguageSearch({
    required String query,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.naturalLanguageSearch,
      body: {'query': query},
    );
    return response as Map<String, dynamic>;
  }

  @override
  Future<double> predictPrice({
    required String city,
    required double sqft,
    required int bedrooms,
    required int bathrooms,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.pricePrediction,
      body: {
        'city': city,
        'sqft': sqft,
        'bedrooms': bedrooms,
        'bathrooms': bathrooms,
      },
    );
    return (response['predicted_price'] as num).toDouble();
  }

  @override
  Future<String> getRecommendations(Map<String, dynamic> data) async {
    final response = await _apiClient.post(
      ApiConstants.recommendations,
      body: {
        'user_preferences': data['preferences'],
        'available_properties': data['properties'],
      },
    );
    return response['recommendations'] as String;
  }
}
