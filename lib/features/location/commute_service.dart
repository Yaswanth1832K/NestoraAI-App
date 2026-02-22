import 'dart:convert';
import 'package:http/http.dart' as http;

class CommuteService {
  // Hardcoded for now as per instructions, can be centralized later
  static const apiKey = "AIzaSyAipJ7rbIwAF0Cpn1rhvLAAbZxsGVyYhc4";

  Future<String?> getCommuteTime({
    required double propertyLat,
    required double propertyLng,
    required String destination,
  }) async {
    final url =
        "https://maps.googleapis.com/maps/api/distancematrix/json"
        "?origins=$propertyLat,$propertyLng"
        "&destinations=${Uri.encodeComponent(destination)}"
        "&mode=driving"
        "&key=$apiKey";

    try {
      final res = await http.get(Uri.parse(url));

      if (res.statusCode != 200) return null;

      final data = jsonDecode(res.body);

      if (data['status'] != 'OK') {
        print('CommuteService Error: ${data['status']} - ${data['error_message']}');
        return null;
      }

      final element = data['rows'][0]['elements'][0];
      if (element['status'] != 'OK') {
        print('CommuteService Element Error: ${element['status']}');
        return null;
      }

      return element['duration']['text'];
    } catch (e) {
      print('CommuteService Exception: $e');
      return null;
    }
  }
}
