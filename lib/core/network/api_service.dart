import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:house_rental/config/api_config.dart';

// Riverpod provider for easy access throughout the app
final apiServiceProvider = Provider((ref) => ApiService());

class ApiService {
  String get baseUrl => ApiConfig.baseUrl; 

  // 1. Fetch properties from FastAPI SQLite DB
  Future<List<dynamic>> fetchProperties({String? city}) async {
    try {
      final uri = city != null 
          ? Uri.parse('$baseUrl/properties?city=$city')
          : Uri.parse('$baseUrl/properties');
          
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body); 
      } else {
        throw Exception('Failed to load properties: \${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: \$e');
    }
  }

  // 2. Chat with Gemini via FastAPI
  Future<String> askAiAboutProperty({
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
      final response = await http.post(
        Uri.parse('$baseUrl/chat/property'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "question": question,
          "title": title,
          "description": description,
          "price": price, 
          "city": city,
          "bedrooms": bedrooms,
          "bathrooms": bathrooms,
          "sqft": sqft
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
             return data['reply'];
        } else {
             throw Exception(data['reply'] ?? data['error']);
        }
      } else {
        throw Exception('AI request failed: \${response.statusCode}');
      }
    } catch (e) {
       throw Exception('Network error: \$e');
    }
  }

  // 3. Search parameters via NLP Gemini
  Future<Map<String, dynamic>> searchNaturalLanguage(String query) async {
      try {
      final response = await http.post(
        Uri.parse('$baseUrl/search/natural-language'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"query": query}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
             return data['filters'];
        } else {
             throw Exception('NLP parsing failed');
        }
      } else {
        throw Exception('NLP request failed: \${response.statusCode}');
      }
    } catch (e) {
       throw Exception('Network error: \$e');
    }
  }
}
