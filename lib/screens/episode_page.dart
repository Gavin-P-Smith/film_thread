import 'package:flutter/material.dart';
import '../services/tmdb_service.dart';
import 'actor_page.dart';
import '../widgets/unified_app_bar.dart';
import '../widgets/expandable_text_preview.dart';
import '../widgets/large_text_page.dart';

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

  Widget _buildEpisodeNavigation(TextTheme textTheme) {
    final currentIndex = episodesInSeason.indexWhere((e) => e['episode_number'] == widget.episodeNumber);
    if (currentIndex == -1) return const SizedBox();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (currentIndex > 0)
          TextButton.icon(
            icon: const Icon(Icons.arrow_back),
            label: Text(
              'Ep ${episodesInSeason[currentIndex - 1]['episode_number']}',
              style: textTheme.bodyMedium,
            ),
            onPressed: () => navigateToEpisode(episodesInSeason[currentIndex - 1]['episode_number']),
          ),
        if (currentIndex < episodesInSeason.length - 1)
          TextButton.icon(
            icon: Text(
              'Ep ${episodesInSeason[currentIndex + 1]['episode_number']}',
              style: textTheme.bodyMedium,
            ),
            label: const Icon(Icons.arrow_forward),
            onPressed: () => navigateToEpisode(episodesInSeason[currentIndex + 1]['episode_number']),
          ),
      ],
    );
  }

  Widget _buildMetadata(TextTheme textTheme) {
    final runtime = episode?['runtime'] ?? 0;
    final airDate = episode?['air_date'] ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(episode?['name'] ?? 'Untitled Episode', style: textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text('Season ${widget.seasonNumber}, Episode ${widget.episodeNumber}', style: textTheme.bodySmall),
        if (airDate.isNotEmpty || runtime > 0)
          Text('$airDate${runtime > 0 ? ' • ${runtime}m' : ''}', style: textTheme.bodySmall),
      ],
    );
  }

  Widget _buildGenres(TextTheme textTheme) {
    final genres = show?['genres']?.map((g) => g['name'])?.toList() ?? [];
    if (genres.isEmpty) return const SizedBox();
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: genres.map<Widget>((genre) {
        return Chip(
          label: Text(genre, style: textTheme.bodySmall),
          padding: const EdgeInsets.symmetric(horizontal: 8),
        );
      }).toList(),
    );
  }

  Widget _buildCrew(TextTheme textTheme) {
    final crew = episode?['crew'] ?? [];
    final directors = crew.where((c) => c['job'] == 'Director').map((c) => c['name']).toSet().toList();
    final writers = crew.where((c) => c['job'] == 'Writer' || c['job'] == 'Screenplay').map((c) => c['name']).toSet().toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (directors.isNotEmpty)
          Text('Director: ${directors.join(', ')}', style: textTheme.bodyMedium),
        if (writers.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text('Writer: ${writers.join(', ')}', style: textTheme.bodyMedium),
          ),
      ],
    );
  }

  Widget _buildOverviewWithImage(TextTheme textTheme) {
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
          child: ExpandableTextPreview(
            title: 'Episode Overview',
            text: (overview != null && overview.isNotEmpty) ? overview : 'No overview available.',
            heroTag: 'episode_overview_${widget.tvId}_${widget.seasonNumber}_${widget.episodeNumber}',
          ),
        ),
      ],
    );
  }

  Widget _buildCast(TextTheme textTheme) {
    final cast = episode?['guest_stars'] ?? [];
    if (cast.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text('Cast', style: textTheme.titleLarge),
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
                      builder: (_) => ActorPage(actorId: actor['id']),
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
                      child: actor['profile_path'] == null ? const Icon(Icons.person) : null,
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 60,
                      child: Text(
                        actor['name'],
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: textTheme.bodySmall,
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
    final textTheme = Theme.of(context).textTheme;

    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: const UnifiedAppBar(), // ✅ Mic now included consistently
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEpisodeNavigation(textTheme),
            const SizedBox(height: 12),
            _buildMetadata(textTheme),
            const SizedBox(height: 8),
            _buildGenres(textTheme),
            const SizedBox(height: 12),
            _buildCrew(textTheme),
            const SizedBox(height: 12),
            _buildOverviewWithImage(textTheme),
            _buildCast(textTheme),
          ],
        ),
      ),
    );
  }
}
