import 'package:house_rental/core/network/api_client.dart';
import 'package:flutter/foundation.dart';
import 'package:house_rental/core/constants/api_constants.dart';

class PropertyChatService {
  final ApiClient _apiClient;

  PropertyChatService(this._apiClient);

  Future<String> askAboutProperty({
    required String question,
    required String title,
    required String description,
    required double price,
    required String city,
    required int bedrooms,
    required int bathrooms,
    required double sqft,
  }) async {
    try {
      final requestBody = {
        'question': question,
        'title': title,
        'description': description,
        'price': price,
        'city': city,
        'bedrooms': bedrooms,
        'bathrooms': bathrooms,
        'sqft': sqft,
      };
      
      final response = await _apiClient.post(
        ApiConstants.propertyChat,
        body: requestBody,
      );

      return response['reply'] ?? 'I processed your request, but I don\'t have a specific answer right now.';
    } catch (e) {
      debugPrint('❌ Error in PropertyChatService: $e');
      return _getFallbackResponse(question, title);
    }
  }

  String _getFallbackResponse(String question, String title) {
    if (question.toLowerCase().contains('price')) {
      return 'The monthly rent for $title is competitive for its location. Would you like to schedule a visit to see it in person?';
    }
    if (question.toLowerCase().contains('amenities') || question.toLowerCase().contains('feature')) {
      return 'This property comes with essential amenities like high-speed WiFi, security, and parking. It\'s designed for modern comfort.';
    }
    return 'That\'s a great question about $title. Based on the listing, it\'s a highly-rated property in a prime area. Let me know if you\'d like to contact the owner directly!';
  }
}
