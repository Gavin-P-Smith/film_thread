import 'package:flutter/material.dart';
import '../services/tmdb_service.dart';
import 'movie_page.dart';
import 'tv_page.dart';
import 'actor_page.dart';
import '../widgets/unified_app_bar.dart';

class ResultsPage extends StatefulWidget {
  final String query;
  const ResultsPage({super.key, required this.query});

  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  List<dynamic> results = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    search();
  }

  Future<void> search() async {
    final res = await TMDbService.searchAll(widget.query);
    res.sort((a, b) => _relevanceScore(b).compareTo(_relevanceScore(a)));
    setState(() {
      results = res;
      isLoading = false;
    });
  }

  int _relevanceScore(dynamic item) {
    final query = widget.query.toLowerCase();
    final name = (item['title'] ?? item['name'] ?? '').toString().toLowerCase();

    int score = 0;

    if (name == query) score += 100;
    else if (name.startsWith(query)) score += 50;
    else if (name.contains(query)) score += 25;

    score += ((item['popularity'] ?? 0) as num).round();

    switch (item['media_type']) {
      case 'tv':
        score += 20;
        break;
      case 'movie':
        score += 10;
        break;
      case 'person':
        score += 5;
        break;
    }

    return score;
  }

  Widget _buildResultTile(dynamic result) {
    final mediaType = result['media_type'];
    final imagePath = result['poster_path'] ?? result['profile_path'];
    final imageUrl = imagePath != null ? TMDbService.getImageUrl(imagePath) : null;
    final name = result['title'] ?? result['name'] ?? 'Unknown';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      leading: SizedBox(
        width: 60,
        height: 90,
        child: imageUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(imageUrl, fit: BoxFit.cover),
              )
            : Container(
                color: Colors.grey[300],
                child: const Icon(Icons.image_not_supported, size: 40),
              ),
      ),
      title: Text(name),
      subtitle: Text(mediaType.toUpperCase()),
      onTap: () {
        if (mediaType == 'movie') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => MoviePage(movieId: result['id'])),
          );
        } else if (mediaType == 'tv') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TvPage(tvId: result['id'])),
          );
        } else if (mediaType == 'person') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ActorPage(actorId: result['id'])),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: const UnifiedAppBar(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : results.isEmpty
              ? Center(
                  child: Text(
                    'No results found for "${widget.query}"',
                    style: textTheme.bodyLarge,
                  ),
                )
              : ListView.separated(
                  itemCount: results.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (_, index) => _buildResultTile(results[index]),
                ),
    );
  }
}
