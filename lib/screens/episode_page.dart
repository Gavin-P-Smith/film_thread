import 'package:flutter/material.dart';
import '../services/tmdb_service.dart';
import 'actor_page.dart';

class EpisodePage extends StatefulWidget {
  final int tvId;
  final int seasonNumber;
  final int episodeNumber;

  const EpisodePage({
    super.key,
    required this.tvId,
    required this.seasonNumber,
    required this.episodeNumber,
  });

  @override
  State<EpisodePage> createState() => _EpisodePageState();
}

class _EpisodePageState extends State<EpisodePage> {
  Map<String, dynamic>? episode;
  Map<String, dynamic>? show;
  List<dynamic> episodesInSeason = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadEpisode();
  }

  Future<void> loadEpisode() async {
    final ep = await TMDbService.getEpisodeDetails(
      tvId: widget.tvId,
      seasonNumber: widget.seasonNumber,
      episodeNumber: widget.episodeNumber,
    );

    final season = await TMDbService.getSeasonDetails(widget.tvId, widget.seasonNumber);
    final showDetails = await TMDbService.getTvDetails(widget.tvId);

    setState(() {
      episode = ep;
      episodesInSeason = season?['episodes'] ?? [];
      show = showDetails;
      isLoading = false;
    });
  }

  void navigateToEpisode(int episodeNumber) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => EpisodePage(
          tvId: widget.tvId,
          seasonNumber: widget.seasonNumber,
          episodeNumber: episodeNumber,
        ),
      ),
    );
  }

  Widget _buildEpisodeNavigation() {
    final currentIndex = episodesInSeason.indexWhere(
      (e) => e['episode_number'] == widget.episodeNumber,
    );
    if (currentIndex == -1) return const SizedBox();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (currentIndex > 0)
          TextButton.icon(
            icon: const Icon(Icons.arrow_back),
            label: Text('Ep ${episodesInSeason[currentIndex - 1]['episode_number']}'),
            onPressed: () => navigateToEpisode(episodesInSeason[currentIndex - 1]['episode_number']),
          ),
        if (currentIndex < episodesInSeason.length - 1)
          TextButton.icon(
            icon: Text('Ep ${episodesInSeason[currentIndex + 1]['episode_number']}'),
            label: const Icon(Icons.arrow_forward),
            onPressed: () => navigateToEpisode(episodesInSeason[currentIndex + 1]['episode_number']),
          ),
      ],
    );
  }

  Widget _buildMetadata() {
    final runtime = episode?['runtime'] ?? 0;
    final airDate = episode?['air_date'] ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          episode?['name'] ?? 'Untitled Episode',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Season ${widget.seasonNumber}, Episode ${widget.episodeNumber}',
          style: const TextStyle(color: Colors.grey),
        ),
        if (airDate.isNotEmpty || runtime > 0)
          Text(
            '$airDate${runtime > 0 ? ' • ${runtime}m' : ''}',
            style: const TextStyle(color: Colors.grey),
          ),
      ],
    );
  }

  Widget _buildGenres() {
    final genres = show?['genres']?.map((g) => g['name'])?.toList() ?? [];
    if (genres.isEmpty) return const SizedBox();
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: genres.map<Widget>((genre) {
        return Chip(
          label: Text(genre, style: const TextStyle(fontSize: 12)),
          padding: const EdgeInsets.symmetric(horizontal: 8),
        );
      }).toList(),
    );
  }

  Widget _buildCrew() {
    final crew = episode?['crew'] ?? [];
    final directors = crew.where((c) => c['job'] == 'Director').map((c) => c['name']).toSet().toList();
    final writers = crew.where((c) => c['job'] == 'Writer' || c['job'] == 'Screenplay').map((c) => c['name']).toSet().toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (directors.isNotEmpty)
          Text('Director: ${directors.join(', ')}', style: const TextStyle(fontSize: 14)),
        if (writers.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text('Writer: ${writers.join(', ')}', style: const TextStyle(fontSize: 14)),
          ),
      ],
    );
  }

  Widget _buildOverviewWithImage() {
    final overview = episode?['overview']?.toString().trim();
    final image = episode?['still_path'];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (image != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              TMDbService.getImageUrl(image, size: 300),
              height: 160,
            ),
          ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            (overview != null && overview.isNotEmpty)
                ? overview
                : 'No overview available.',
            style: const TextStyle(fontSize: 14),
            textAlign: TextAlign.justify,
          ),
        ),
      ],
    );
  }

  Widget _buildCast() {
    final cast = episode?['guest_stars'] ?? [];
    if (cast.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text('Cast', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: cast.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, index) {
              final actor = cast[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ActorPage(actorName: actor['name']),
                    ),
                  );
                },
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: actor['profile_path'] != null
                          ? NetworkImage(TMDbService.getImageUrl(actor['profile_path']))
                          : null,
                      child: actor['profile_path'] == null
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 60,
                      child: Text(
                        actor['name'],
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(episode?['name'] ?? 'Episode ${widget.episodeNumber}'),
            Text(
              'Season ${widget.seasonNumber}, Episode ${widget.episodeNumber}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEpisodeNavigation(),
            const SizedBox(height: 12),
            _buildMetadata(),
            const SizedBox(height: 8),
            _buildGenres(),
            const SizedBox(height: 12),
            _buildCrew(),
            const SizedBox(height: 12),
            _buildOverviewWithImage(),
            _buildCast(),
          ],
        ),
      ),
    );
  }
}
