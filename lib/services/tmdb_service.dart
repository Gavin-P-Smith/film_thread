import 'dart:convert';
import 'package:http/http.dart' as http;

class TMDbService {
  static const String _apiKey = '38f9ac0f23b36b7c64990e9711335610';
  static const String _baseUrl = 'https://api.themoviedb.org/3';

  static Future<Map<String, dynamic>?> getTvDetails(int tvId) async {
  final url = Uri.parse('$_baseUrl/tv/$tvId?api_key=$_apiKey');
  return _getJson(url);
}

static Future<Map<String, dynamic>?> getEpisodeDetails({
  required int tvId,
  required int seasonNumber,
  required int episodeNumber,
}) async {
  final url = Uri.parse(
    '$_baseUrl/tv/$tvId/season/$seasonNumber/episode/$episodeNumber?api_key=$_apiKey',
  );
  return _getJson(url);
}
static Future<List<dynamic>> searchMulti(String query) async {
  final encoded = Uri.encodeQueryComponent(query);
  final url = Uri.parse('$_baseUrl/search/multi?api_key=$_apiKey&query=$encoded');
  final data = await _getJson(url);
  return data?['results'] ?? [];
}
static Future<Map<String, dynamic>?> getTvCredits(int tvId) async {
  final url = Uri.parse('$_baseUrl/tv/$tvId/credits?api_key=$_apiKey');
  return _getJson(url);
}

  static Future<List<dynamic>> getTvFilmography(int personId) async {
  final url = Uri.parse('$_baseUrl/person/$personId/tv_credits?api_key=$_apiKey');
  final data = await _getJson(url);
  return data?['cast'] ?? [];
}

  static Future<Map<String, dynamic>?> getMovieDetails(int movieId) async {
    final url = Uri.parse('$_baseUrl/movie/$movieId?api_key=$_apiKey');
    return _getJson(url);
  }

  static Future<Map<String, dynamic>?> getMovieCredits(int movieId) async {
    final url = Uri.parse('$_baseUrl/movie/$movieId/credits?api_key=$_apiKey');
    return _getJson(url);
  }

  static Future<Map<String, dynamic>?> getMovieVideos(int movieId) async {
    final url = Uri.parse('$_baseUrl/movie/$movieId/videos?api_key=$_apiKey');
    return _getJson(url);
  }

  static Future<Map<String, dynamic>?> getExternalIds(int movieId) async {
    final url = Uri.parse('$_baseUrl/movie/$movieId/external_ids?api_key=$_apiKey');
    return _getJson(url);
  }

  static Future<Map<String, dynamic>?> getReleaseDates(int movieId) async {
    final url = Uri.parse('$_baseUrl/movie/$movieId/release_dates?api_key=$_apiKey');
    return _getJson(url);
  }

  static Future<Map<String, dynamic>?> getSimilarMovies(int movieId) async {
    final url = Uri.parse('$_baseUrl/movie/$movieId/similar?api_key=$_apiKey');
    return _getJson(url);
  }

  static Future<Map<String, dynamic>?> searchActorByName(String name) async {
    final encodedName = Uri.encodeQueryComponent(name);
    final url = Uri.parse('$_baseUrl/search/person?api_key=$_apiKey&query=$encodedName');
    final data = await _getJson(url);
    return (data != null && data['results'] != null && data['results'].isNotEmpty)
        ? data['results'][0]
        : null;
  }

  static Future<Map<String, dynamic>?> getActorDetails(int personId) async {
    final url = Uri.parse('$_baseUrl/person/$personId?api_key=$_apiKey');
    return _getJson(url);
  }

  static Future<List<dynamic>> getFilmography(int personId) async {
    final url = Uri.parse('$_baseUrl/person/$personId/movie_credits?api_key=$_apiKey');
    final data = await _getJson(url);
    return data?['cast'] ?? [];
  }

  static String getImageUrl(String path, {int size = 200}) {
    return 'https://image.tmdb.org/t/p/w$size$path';
  }

  static Future<Map<String, dynamic>?> getSeasonDetails(int tvId, int seasonNumber) async {
  final url = Uri.parse('$_baseUrl/tv/$tvId/season/$seasonNumber?api_key=$_apiKey');
  return _getJson(url);
}

  static Future<Map<String, dynamic>?> _getJson(Uri url) async {
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    return null;
  }
}
