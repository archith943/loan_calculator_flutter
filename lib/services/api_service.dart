// api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config_model.dart'; // Ensure to import the model

class ApiService {
  final String _apiUrl =
      'https://gist.githubusercontent.com/motgi/8fc373cbfccee534c820875ba20ae7b5/raw/7143758ff2caa773e651dc3576de57cc829339c0/config.json';

  Future<List<ConfigItem>> fetchConfig() async {
    try {
      final response = await http.get(Uri.parse(_apiUrl));

      // Check if the response is successful (status code 200)
      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        if (responseBody is List) {
          return responseBody.map((data) => ConfigItem.fromJson(data)).toList();
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
