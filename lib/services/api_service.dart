// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String _apiUrl =
      'https://gist.githubusercontent.com/motgi/8fc373cbfccee534c820875ba20ae7b5/raw/7143758ff2caa773e651dc3576de57cc829339c0/config.json';

  Future<Map<String, dynamic>> fetchConfig() async {
    try {
      final response = await http.get(Uri.parse(_apiUrl));

      // Check if the response is successful (status code 200)
      if (response.statusCode == 200) {
        // Attempt to decode the response body into a map.
        final responseBody = json.decode(response.body);

        // Check if the response is actually a list or map
        if (responseBody is List) {
          // Handle case when the response is a list (e.g., returning the first item)
          return responseBody.isNotEmpty
              ? Map<String, dynamic>.from(responseBody[0])
              : {}; // Cast to Map
        } else if (responseBody is Map) {
          // Handle the case where the response is a map
          return Map<String, dynamic>.from(
              responseBody); // Cast to Map<String, dynamic>
        } else {
          throw Exception('Unexpected response format');
        }
      } else {
        throw Exception('Failed to load config');
      }
    } catch (error) {
      throw Exception('Error fetching config: $error');
    }
  }
}
