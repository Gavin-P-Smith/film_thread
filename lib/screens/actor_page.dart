import 'package:flutter/material.dart';
import '../services/tmdb_service.dart';
import 'media_page.dart';
import 'bacon_path_result_page.dart';
import '../widgets/unified_app_bar.dart';
import '../widgets/expandable_text_preview.dart';
import '../widgets/large_text_page.dart';

class ActorPage extends StatefulWidget {
  final int actorId;

  const ActorPage({super.key, required this.actorId});

  @override
  State<ActorPage> createState() => _ActorPageState();
}

class _ActorPageState extends State<ActorPage> {
  Map<String, dynamic>? actorData;
  List<dynamic> filmography = [];
  Map<String, List<dynamic>> groupedByDecade = {};
  Set<String> expandedDecades = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchActor();
  }

  Future<void> fetchActor() async {
    final details = await TMDbService.getActorDetails(widget.actorId);
    final movieCredits = await TMDbService.getFilmography(widget.actorId);
    final tvCredits = await TMDbService.getTvFilmography(widget.actorId);

    for (var m in movieCredits) {
      m['media_type'] = 'movie';
    }
    for (var t in tvCredits) {
      t['media_type'] = 'tv';
    }

    final combined = [...movieCredits, ...tvCredits]
      ..sort((a, b) => (b['release_date'] ?? b['first_air_date'] ?? '')
          .compareTo(a['release_date'] ?? a['first_air_date'] ?? ''));

    groupedByDecade = _groupByDecade(combined);
    if (groupedByDecade.isNotEmpty) {
      expandedDecades.add(groupedByDecade.keys.first);
    }

    setState(() {
      actorData = details;
      filmography = combined;
      isLoading = false;
    });
  }

  Map<String, List<dynamic>> _groupByDecade(List<dynamic> credits) {
    final Map<String, List<dynamic>> grouped = {};
    for (var entry in credits) {
      final date = entry['release_date'] ?? entry['first_air_date'];
      if (date == null || date.isEmpty) continue;
      final year = int.tryParse(date.substring(0, 4));
      if (year == null) continue;
      final decade = '${(year ~/ 10) * 10}s';
      grouped.putIfAbsent(decade, () => []).add(entry);
    }

    final sorted = grouped.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    return Map.fromEntries(sorted);
  }

  Widget _buildHeader(TextTheme textTheme) {
    final profilePath = actorData?['profile_path'];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (profilePath != null)
          Container(
            decoration: const BoxDecoration(boxShadow: [
              BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(2, 4))
            ]),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                TMDbService.getImageUrl(profilePath, size: 300),
                height: 160,
              ),
            ),
          )
        else
          const Icon(Icons.person, size: 160),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (actorData?['birthday'] != null)
                Text('Born: ${actorData!['birthday']}', style: textTheme.bodyMedium),
              if (actorData?['place_of_birth'] != null)
                Text(actorData!['place_of_birth'],
                    style: textTheme.bodySmall?.copyWith(color: Colors.grey)),
              const SizedBox(height: 8),
              ExpandableTextPreview(
                title: 'Biography',
                text: actorData?['biography'] ?? 'No biography available.',
                heroTag: 'actor_bio_${actorData?['id'] ?? actorData?['name']}',
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildFilmography(TextTheme textTheme) {
    return ListView(
      children: [
        ...groupedByDecade.entries.map((entry) {
          final decade = entry.key;
          final movies = entry.value;
          final isExpanded = expandedDecades.contains(decade);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                title: Text(decade,
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                trailing: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
                onTap: () {
                  setState(() {
                    isExpanded ? expandedDecades.remove(decade) : expandedDecades.add(decade);
                  });
                },
              ),
              if (isExpanded)
                ...movies.map((item) => ListTile(
                      leading: item['poster_path'] != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.network(
                                TMDbService.getImageUrl(item['poster_path']),
                                width: 50,
                                height: 75,
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Icon(Icons.movie),
                      title: Text(item['title'] ?? item['name'], style: textTheme.bodyLarge),
                      subtitle: Text(
                        (item['release_date'] ?? item['first_air_date'] ?? '')
                            .toString()
                            .substring(0, 4),
                        style: textTheme.bodySmall,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MediaPage(
                              id: item['id'],
                              mediaType: item['media_type'] ?? 'movie',
                            ),
                          ),
                        );
                      },
                    )),
            ],
          );
        }),
        const SizedBox(height: 20),
        if (actorData != null)
          Center(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BaconPathResultPage(
                      startActorId: actorData!['id'],
                      startActorName: actorData!['name'],
                    ),
                  ),
                );
              },
              child: Image.asset(
                'assets/kevin_bacon.png',
                height: 60,
              ),
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
      appBar: const UnifiedAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (actorData != null) _buildHeader(textTheme),
            const SizedBox(height: 16),
            Expanded(child: _buildFilmography(textTheme)),
          ],
        ),
      ),
    );
  }
}
