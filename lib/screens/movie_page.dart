import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/tmdb_service.dart';
import 'actor_page.dart';

class MoviePage extends StatefulWidget {
  final int movieId;

  const MoviePage({super.key, required this.movieId});

  @override
  State<MoviePage> createState() => _MoviePageState();
}

class _MoviePageState extends State<MoviePage> {
  Map<String, dynamic>? movie;
  Map<String, dynamic>? credits;
  Map<String, dynamic>? videos;
  Map<String, dynamic>? externalIds;
  Map<String, dynamic>? releaseDates;
  Map<String, dynamic>? similar;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadMovieData();
  }

  Future<void> loadMovieData() async {
    final m = await TMDbService.getMovieDetails(widget.movieId);
    final c = await TMDbService.getMovieCredits(widget.movieId);
    final v = await TMDbService.getMovieVideos(widget.movieId);
    final e = await TMDbService.getExternalIds(widget.movieId);
    final r = await TMDbService.getReleaseDates(widget.movieId);
    final s = await TMDbService.getSimilarMovies(widget.movieId);

    if (!mounted) return;

    setState(() {
      movie = m;
      credits = c;
      videos = v;
      externalIds = e;
      releaseDates = r;
      similar = s;
      isLoading = false;
    });
  }

  String getCertification() {
    final results = releaseDates?['results'] ?? [];
    for (var entry in results) {
      if (entry['iso_3166_1'] == 'US') {
        final releases = entry['release_dates'];
        for (var r in releases) {
          if ((r['certification'] as String).isNotEmpty) {
            return r['certification'];
          }
        }
      }
    }
    return 'NR';
  }

  String? getTrailerYoutubeKey() {
    final results = videos?['results'] ?? [];
    for (var video in results) {
      if (video['type'] == 'Trailer' && video['site'] == 'YouTube') {
        return video['key'];
      }
    }
    return null;
  }

  Future<void> _launchYouTubeTrailer(String videoKey) async {
    final url = Uri.parse('https://www.youtube.com/watch?v=$videoKey');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch trailer')),
      );
    }
  }

  Widget buildCrewList(String job) {
    final crew = credits?['crew'] ?? [];
    final filtered = crew.where((c) => c['job'] == job).toList();
    if (filtered.isEmpty) return const SizedBox.shrink();
    return Text(
      "$job: ${filtered.map((c) => c['name']).join(', ')}",
      style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || movie == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final posterUrl = movie!['poster_path'] != null
        ? TMDbService.getImageUrl(movie!['poster_path'], size: 300)
        : null;

    final trailerKey = getTrailerYoutubeKey();

    return Scaffold(
      appBar: AppBar(title: Text(movie!['title'] ?? '')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (posterUrl != null)
              Center(
                child: Image.network(posterUrl, height: 300),
              ),
            const SizedBox(height: 16),
            Text(
              '${movie!['title']} (${movie!['release_date']?.toString().substring(0, 4) ?? 'N/A'})',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              movie!['genres'] != null
                  ? (movie!['genres'] as List).map((g) => g['name']).join(', ')
                  : 'No genre info',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Runtime: ${movie!['runtime']} min | Certification: ${getCertification()}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Text(
              movie!['overview'] ?? 'No summary available.',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            buildCrewList('Director'),
            buildCrewList('Writer'),
            buildCrewList('Original Music Composer'),
            const SizedBox(height: 20),
            const Text('Cast', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Column(
              children: (credits?['cast'] ?? [])
                  .take(10)
                  .map<Widget>(
                    (actor) => ListTile(
                      leading: actor['profile_path'] != null
                          ? CircleAvatar(
                              backgroundImage: NetworkImage(
                                TMDbService.getImageUrl(actor['profile_path']),
                              ),
                            )
                          : const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(actor['name']),
                      subtitle: Text('as ${actor['character']}'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ActorPage(actorName: actor['name']),
                          ),
                        );
                      },
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 20),
            if (trailerKey != null)
              TextButton.icon(
                icon: const Icon(Icons.play_circle_fill),
                label: const Text('Watch Trailer'),
                onPressed: () => _launchYouTubeTrailer(trailerKey),
              ),
            const SizedBox(height: 20),
            const Text('Similar Movies', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Column(
              children: (similar?['results'] ?? [])
                  .take(5)
                  .map<Widget>(
                    (movie) => ListTile(
                      leading: movie['poster_path'] != null
                          ? Image.network(
                              TMDbService.getImageUrl(movie['poster_path']),
                              width: 50,
                            )
                          : const Icon(Icons.movie),
                      title: Text(movie['title']),
                      subtitle: Text(movie['release_date']?.toString().substring(0, 4) ?? ''),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MoviePage(movieId: movie['id']),
                          ),
                        );
                      },
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
