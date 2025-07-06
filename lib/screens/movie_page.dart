import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/tmdb_service.dart';
import 'actor_page.dart';
import '../widgets/unified_app_bar.dart';
import '../widgets/expandable_text_preview.dart';
import '../widgets/large_text_page.dart';

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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodyMedium,
          children: [
            TextSpan(text: "$job: ", style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: filtered.map((c) => c['name']).join(', '))
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    if (isLoading || movie == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final posterUrl = movie!['poster_path'] != null
        ? TMDbService.getImageUrl(movie!['poster_path'], size: 300)
        : null;

    final trailerKey = getTrailerYoutubeKey();

    return Scaffold(
      appBar: const UnifiedAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (posterUrl != null)
                  Container(
                    decoration: const BoxDecoration(boxShadow: [
                      BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(2, 4))
                    ]),
                    child: Image.network(posterUrl, height: 250),
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${movie!['title']} (${movie!['release_date']?.substring(0, 4) ?? 'N/A'})', style: textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: (movie!['genres'] as List?)?.map((g) => Chip(label: Text(g['name']))).toList() ?? [],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.schedule, size: 18),
                          const SizedBox(width: 4),
                          Text('${movie!['runtime']} min', style: textTheme.bodyMedium),
                          const SizedBox(width: 16),
                          const Icon(Icons.warning, size: 18),
                          const SizedBox(width: 4),
                          Text(getCertification(), style: textTheme.bodyMedium),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ExpandableTextPreview(
              title: 'Overview',
              text: movie!['overview'] ?? 'No summary available.',
              heroTag: 'movie_overview_${movie!['id']}',
            ),
            const SizedBox(height: 20),
            buildCrewList('Director'),
            buildCrewList('Writer'),
            buildCrewList('Original Music Composer'),
            const SizedBox(height: 20),
            Text('Cast', style: textTheme.titleLarge),
            const SizedBox(height: 8),
            SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: (credits?['cast'] ?? []).length.clamp(0, 10),
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, index) {
                  final actor = credits!['cast'][index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ActorPage(actorId: actor['id']),
                        ),
                      );
                    },
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundImage: actor['profile_path'] != null
                              ? NetworkImage(TMDbService.getImageUrl(actor['profile_path']))
                              : null,
                          child: actor['profile_path'] == null ? const Icon(Icons.person) : null,
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: 80,
                          child: Text(actor['name'], overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: textTheme.bodyMedium),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            if (trailerKey != null)
              Center(
                child: FilledButton.icon(
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Watch Trailer'),
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    textStyle: const TextStyle(fontSize: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  onPressed: () => _launchYouTubeTrailer(trailerKey),
                ),
              ),
            const SizedBox(height: 20),
            Text('Similar Movies', style: textTheme.titleLarge),
            const SizedBox(height: 8),
            SizedBox(
              height: 250,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: (similar?['results'] ?? []).length.clamp(0, 10),
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, index) {
                  final sm = similar!['results'][index];
                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => MoviePage(movieId: sm['id'])),
                      );
                    },
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: sm['poster_path'] != null
                              ? Image.network(
                                  TMDbService.getImageUrl(sm['poster_path']),
                                  height: 180,
                                )
                              : Container(
                                  height: 180,
                                  width: 120,
                                  color: Colors.grey,
                                  child: const Icon(Icons.movie, size: 48),
                                ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: 100,
                          child: Text(sm['title'], overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: textTheme.bodyMedium),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
