import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import 'package:house_rental/core/constants/api_constants.dart';

class PropertyChatService {
  String get baseUrl => ApiConstants.baseUrl;

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
      debugPrint('🤖 Sending request to AI backend...');
      debugPrint('URL: $baseUrl/chat/property');
      
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
      
      debugPrint('Request body: $requestBody');
      
      final response = await http.post(
        Uri.parse('$baseUrl/chat/property'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timed out after 30 seconds');
        },
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['reply'];
        } else {
          return data['reply'] ?? 'Sorry, I could not process your question.';
        }
      } else {
        return 'Failed to get AI response. Status: ${response.statusCode}';
      }
    } catch (e) {
      debugPrint('❌ Error in PropertyChatService: $e');
      return 'Error connecting to AI service. Please check if the backend is running.';
    }
  }
}
