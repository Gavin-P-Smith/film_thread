// media_page.dart
import 'package:flutter/material.dart';
import 'movie_page.dart';
import 'tv_page.dart';

class MediaPage extends StatelessWidget {
  final int id;
  final String mediaType;

  const MediaPage({super.key, required this.id, required this.mediaType});

  @override
  Widget build(BuildContext context) {
    if (mediaType == 'tv') {
      return TvPage(tvId: id);
    } else {
      return MoviePage(movieId: id);
    }
  }
}
