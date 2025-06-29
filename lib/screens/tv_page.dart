import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/tmdb_service.dart';
import 'actor_page.dart';
import 'episode_page.dart';

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

  Widget _buildMetadata() {
    final genres = tv?['genres']?.map((g) => g['name'])?.join(', ') ?? '';
    final date = tv?['first_air_date']?.toString().substring(0, 4) ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tv?['name'] ?? 'Unknown',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        if (genres.isNotEmpty || date.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '$genres • $date',
              style: const TextStyle(color: Colors.grey),
            ),
          ),
      ],
    );
  }

  Widget _buildPosterAndOverview() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (tv?['poster_path'] != null)
          Image.network(
            TMDbService.getImageUrl(tv!['poster_path'], size: 300),
            height: 180,
          ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            tv?['overview'] ?? 'No overview available.',
            textAlign: TextAlign.justify,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildCastList() {
    final cast = credits?['cast'] ?? [];

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
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ActorPage(actorName: actor['name']),
                  ),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      backgroundImage: actor['profile_path'] != null
                          ? NetworkImage(TMDbService.getImageUrl(actor['profile_path']))
                          : null,
                      radius: 30,
                      child: actor['profile_path'] == null
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 60,
                      child: Text(
                        actor['name'],
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
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

  Widget _buildTrailerButton() {
    final ytVideo = (videos?['results'] ?? [])
        .firstWhere((v) => v['site'] == 'YouTube' && v['type'] == 'Trailer', orElse: () => null);
    if (ytVideo == null) return const SizedBox();

    final url = 'https://www.youtube.com/watch?v=${ytVideo['key']}';
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.play_arrow),
          label: const Text('Watch Trailer'),
          onPressed: () async {
            if (await canLaunchUrl(Uri.parse(url))) {
              await launchUrl(Uri.parse(url));
            }
          },
        ),
      ),
    );
  }

  Widget _buildExternalLinks() {
    final imdbId = externalIds?['imdb_id'];
    if (imdbId == null) return const SizedBox();

    return TextButton.icon(
      onPressed: () async {
        final url = 'https://www.imdb.com/title/$imdbId';
        if (await canLaunchUrl(Uri.parse(url))) {
          await launchUrl(Uri.parse(url));
        }
      },
      icon: const Icon(Icons.open_in_new),
      label: const Text('View on IMDb'),
    );
  }

  Widget _buildSimilarShows() {
    final results = similar?['results'] ?? [];
    if (results.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text('Similar Shows', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: results.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, index) {
              final show = results[index];
              return GestureDetector(
                onTap: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TvPage(tvId: show['id']),
                  ),
                ),
                child: Column(
                  children: [
                    if (show['poster_path'] != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          TMDbService.getImageUrl(show['poster_path']),
                          height: 140,
                        ),
                      ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 100,
                      child: Text(
                        show['name'],
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
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

  Widget _buildSeasons() {
    final seasons = tv?['seasons'] ?? [];
    if (seasons.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text('Seasons', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...seasons.map<Widget>((season) {
          final seasonNumber = season['season_number'];
          final isExpanded = expandedSeasons.contains(seasonNumber);
          final seasonInfo = seasonDetails[seasonNumber];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: season['poster_path'] != null
                    ? Image.network(
                        TMDbService.getImageUrl(season['poster_path']),
                        width: 50,
                      )
                    : const Icon(Icons.tv),
                title: Text(season['name']),
                subtitle: Text(
                  '${season['episode_count']} episodes • ${season['air_date']?.toString().substring(0, 4) ?? 'N/A'}',
                ),
                trailing: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
                onTap: () async {
                  setState(() {
                    isExpanded
                        ? expandedSeasons.remove(seasonNumber)
                        : expandedSeasons.add(seasonNumber);
                  });

                  if (!seasonDetails.containsKey(seasonNumber)) {
                    final details = await TMDbService.getSeasonDetails(widget.tvId, seasonNumber);
                    if (details != null) {
                      setState(() {
                        seasonDetails[seasonNumber] = details;
                      });
                    }
                  }
                },
              ),
              if (isExpanded && seasonInfo != null)
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, bottom: 8),
                  child: Column(
                    children: (seasonInfo['episodes'] as List).map<Widget>((episode) {
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('Ep ${episode['episode_number']}: ${episode['name']}'),
                        subtitle: Text(episode['air_date'] ?? ''),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EpisodePage(
                                tvId: widget.tvId,
                                seasonNumber: seasonNumber,
                                episodeNumber: episode['episode_number'],
                              ),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  ),
                )
            ],
          );
        }).toList(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text(tv?['name'] ?? 'TV Show')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMetadata(),
            const SizedBox(height: 12),
            _buildPosterAndOverview(),
            _buildCastList(),
            _buildTrailerButton(),
            _buildExternalLinks(),
            _buildSeasons(),
            _buildSimilarShows(),
          ],
        ),
      ),
    );
  }
}
