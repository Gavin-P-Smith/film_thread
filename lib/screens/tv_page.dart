import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/tmdb_service.dart';
import 'actor_page.dart';
import 'episode_page.dart';
import '../widgets/unified_app_bar.dart';
import '../widgets/expandable_text_preview.dart';

class TvPage extends StatefulWidget {
  final int tvId;
  const TvPage({super.key, required this.tvId});

  @override
  State<TvPage> createState() => _TvPageState();
}

class _TvPageState extends State<TvPage> {
  Map<String, dynamic>? tv;
  Map<String, dynamic>? credits;
  Map<String, dynamic>? videos;
  Map<String, dynamic>? externalIds;
  Map<String, dynamic>? similar;
  Map<int, Map<String, dynamic>> seasonDetails = {};
  Set<int> expandedSeasons = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadTvData();
  }

  Future<void> loadTvData() async {
    final tvDetails = await TMDbService.getTvDetails(widget.tvId);
    final cast = await TMDbService.getTvCredits(widget.tvId);
    final vids = await TMDbService.getMovieVideos(widget.tvId);
    final ext = await TMDbService.getExternalIds(widget.tvId);
    final sim = await TMDbService.getSimilarMovies(widget.tvId);

    setState(() {
      tv = tvDetails;
      credits = cast;
      videos = vids;
      externalIds = ext;
      similar = sim;
      isLoading = false;
    });
  }

  Future<void> toggleSeason(int seasonNumber) async {
    if (seasonDetails.containsKey(seasonNumber)) {
      setState(() {
        expandedSeasons.contains(seasonNumber)
            ? expandedSeasons.remove(seasonNumber)
            : expandedSeasons.add(seasonNumber);
      });
      return;
    }

    final seasonData =
        await TMDbService.getSeasonDetails(widget.tvId, seasonNumber);

    if (seasonData != null) {
      setState(() {
        seasonDetails[seasonNumber] = seasonData;
        expandedSeasons.add(seasonNumber);
      });
    }
  }

  Widget _buildHeader(TextTheme textTheme) {
    final genres = tv?['genres']?.map((g) => g['name'])?.join(', ') ?? '';
    final date = tv?['first_air_date']?.toString().substring(0, 4) ?? '';
    final poster = tv?['poster_path'] != null
        ? TMDbService.getImageUrl(tv!['poster_path'], size: 300)
        : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (poster != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(poster, height: 180),
          )
        else
          const Icon(Icons.tv, size: 180),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tv?['name'] ?? 'Unknown', style: textTheme.headlineLarge),
              const SizedBox(height: 4),
              if (genres.isNotEmpty || date.isNotEmpty)
                Text('$genres • $date', style: textTheme.bodyMedium),
              const SizedBox(height: 12),
              ExpandableTextPreview(
                title: 'Overview',
                text: tv?['overview'] ?? 'No overview available.',
                heroTag: 'tv_overview_${tv?['id']}',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCastList(TextTheme textTheme) {
    final cast = credits?['cast'] ?? [];
    if (cast.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text('Cast', style: textTheme.titleLarge),
        const SizedBox(height: 8),
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: cast.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, index) {
              final actor = cast[index];
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ActorPage(actorId: actor['id']),
                  ),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: actor['profile_path'] != null
                          ? NetworkImage(
                              TMDbService.getImageUrl(actor['profile_path']))
                          : null,
                      child: actor['profile_path'] == null
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 80,
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

  Widget _buildTrailerButton(ColorScheme colorScheme) {
    final ytVideo = (videos?['results'] ?? [])
        .firstWhere((v) => v['site'] == 'YouTube' && v['type'] == 'Trailer',
            orElse: () => null);
    if (ytVideo == null) return const SizedBox();

    final url = 'https://www.youtube.com/watch?v=${ytVideo['key']}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: FilledButton.icon(
          icon: const Icon(Icons.play_arrow),
          label: const Text('Watch Trailer'),
          style: FilledButton.styleFrom(backgroundColor: colorScheme.primary),
          onPressed: () async {
            if (await canLaunchUrl(Uri.parse(url))) {
              await launchUrl(Uri.parse(url));
            }
          },
        ),
      ),
    );
  }

  Widget _buildSeasonList(TextTheme textTheme) {
    final seasons = tv?['seasons'] ?? [];
    if (seasons.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Seasons', style: textTheme.titleLarge),
        const SizedBox(height: 12),
        ...seasons.map<Widget>((season) {
          final seasonNumber = season['season_number'];
          final seasonName = season['name'];
          final seasonPoster = season['poster_path'];
          final isExpanded = expandedSeasons.contains(seasonNumber);
          final seasonEpisodes =
              seasonDetails[seasonNumber]?['episodes'] ?? [];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(seasonName,
                    style: textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                trailing: Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more),
                onTap: () => toggleSeason(seasonNumber),
              ),
              if (isExpanded)
                ...seasonEpisodes.map<Widget>((ep) {
                  return ListTile(
                    title: Text(
                        'Episode ${ep['episode_number']}: ${ep['name'] ?? 'Untitled'}'),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EpisodePage(
                          tvId: widget.tvId,
                          seasonNumber: seasonNumber,
                          episodeNumber: ep['episode_number'],
                        ),
                      ),
                    ),
                  );
                }).toList(),
            ],
          );
        }).toList(),
      ],
    );
  }

  Widget _buildSimilarShows(TextTheme textTheme) {
    final results = similar?['results'] ?? [];
    if (results.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text('Similar Shows', style: textTheme.titleLarge),
        const SizedBox(height: 8),
        SizedBox(
          height: 250,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: results.length.clamp(0, 10),
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, index) {
              final show = results[index];
              return GestureDetector(
                onTap: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => TvPage(tvId: show['id'])),
                ),
                child: Column(
                  children: [
                    if (show['poster_path'] != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          TMDbService.getImageUrl(show['poster_path']),
                          height: 180,
                        ),
                      )
                    else
                      Container(
                        height: 180,
                        width: 120,
                        color: Colors.grey,
                        child: const Icon(Icons.tv, size: 48),
                      ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: 100,
                      child: Text(
                        show['name'],
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium,
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
    final colorScheme = Theme.of(context).colorScheme;

    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: const UnifiedAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(textTheme),
            _buildCastList(textTheme),
            _buildTrailerButton(colorScheme),
            const SizedBox(height: 12),
            _buildSeasonList(textTheme),
            const SizedBox(height: 12),
            _buildSimilarShows(textTheme),
          ],
        ),
      ),
    );
  }
}
