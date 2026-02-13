import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:house_rental/core/errors/exceptions.dart';

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
}

class AIRemoteDataSourceImpl implements AIRemoteDataSource {
  final http.Client _client;

  AIRemoteDataSourceImpl(this._client);

  String get _baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    } else {
      return 'http://127.0.0.1:8000'; // iOS/Desktop
    }
  }

  @override
  Future<Map<String, dynamic>> naturalLanguageSearch({
    required String query,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/search/natural-language'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'query': query,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data; 
      } else {
        throw ServerException(
          message: 'AI Service Error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<double> predictPrice({
    required String city,
    required double sqft,
    required int bedrooms,
    required int bathrooms,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/price/predict'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'city': city,
          'sqft': sqft,
          'bedrooms': bedrooms,
          'bathrooms': bathrooms,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return (data['predicted_price'] as num).toDouble();
      } else {
        throw ServerException(
          message: 'AI Price Prediction Error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }
}
