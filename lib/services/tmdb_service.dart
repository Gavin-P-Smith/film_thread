import 'dart:convert';
import 'package:http/http.dart' as http;

class TMDbService {
  static const String _apiKey = '38f9ac0f23b36b7c64990e9711335610'; // 🔁 Replace with your TMDb API key
  static const String _baseUrl = 'https://api.themoviedb.org/3';

  static Future<Map<String, dynamic>?> searchActorByName(String name) async {
    final encodedName = Uri.encodeQueryComponent(name);
    final url = Uri.parse('$_baseUrl/search/person?api_key=$_apiKey&query=$encodedName');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['results'] != null && data['results'].isNotEmpty) {
          return data['results'][0]; // Return the first match
        }
      }
    } catch (_) {
      // Fail silently in production
    }

    return null;
  }

  static String getProfileImageUrl(String path) {
    return 'https://image.tmdb.org/t/p/w200$path';
  }
}
