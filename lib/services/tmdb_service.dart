import 'dart:convert';
import 'package:http/http.dart' as http;

class TMDbService {
  static const String _apiKey = '38f9ac0f23b36b7c64990e9711335610';
  static const String _baseUrl = 'https://api.themoviedb.org/3';

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

  static Future<Map<String, dynamic>?> _getJson(Uri url) async {
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    return null;
  }

  static String? genreName(int id) {
    const genreMap = {
      28: 'Action',
      12: 'Adventure',
      16: 'Animation',
      35: 'Comedy',
      80: 'Crime',
      99: 'Documentary',
      18: 'Drama',
      10751: 'Family',
      14: 'Fantasy',
      36: 'History',
      27: 'Horror',
      10402: 'Music',
      9648: 'Mystery',
      10749: 'Romance',
      878: 'Science Fiction',
      10770: 'TV Movie',
      53: 'Thriller',
      10752: 'War',
      37: 'Western',
    };
    return genreMap[id];
  }
}
