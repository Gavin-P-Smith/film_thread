import 'package:flutter/material.dart';
import '../services/tmdb_service.dart';
import 'movie_page.dart';

class ActorPage extends StatefulWidget {
  final String actorName;

  const ActorPage({super.key, required this.actorName});

  @override
  State<ActorPage> createState() => _ActorPageState();
}

class _ActorPageState extends State<ActorPage> {
  Map<String, dynamic>? actorData;
  List<dynamic> filmography = [];
  Map<String, List<dynamic>> groupedByDecade = {};
  Set<String> expandedDecades = {};
  String? selectedGenre;
  List<String> topGenres = [];

  bool isLoading = true;
  bool isBioExpanded = false;

  @override
  void initState() {
    super.initState();
    fetchActor();
  }

  Future<void> fetchActor() async {
    final result = await TMDbService.searchActorByName(widget.actorName);
    if (result == null) {
      setState(() => isLoading = false);
      return;
    }

    final personId = result['id'];
    final details = await TMDbService.getActorDetails(personId);
    final credits = await TMDbService.getFilmography(personId);

    final sorted = [...credits]
      ..sort((a, b) => (b['release_date'] ?? '').compareTo(a['release_date'] ?? ''));

    final genreMap = <String, int>{};
    for (var movie in sorted) {
      for (var genre in movie['genre_ids'] ?? []) {
        final name = TMDbService.genreName(genre);
        if (name != null) genreMap[name] = (genreMap[name] ?? 0) + 1;
      }
    }

    final genreEntries = genreMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    topGenres = genreEntries.take(5).map((e) => e.key).toList();

    groupedByDecade = _groupByDecade(sorted);
    if (groupedByDecade.isNotEmpty) {
      expandedDecades.add(groupedByDecade.keys.first);
    }

    setState(() {
      actorData = details;
      filmography = sorted;
      isLoading = false;
    });
  }

  Map<String, List<dynamic>> _groupByDecade(List<dynamic> credits) {
    final Map<String, List<dynamic>> grouped = {};
    for (var movie in credits) {
      final date = movie['release_date'];
      if (date == null || date.isEmpty) continue;
      final year = int.tryParse(date.substring(0, 4));
      if (year == null) continue;
      final decade = '${(year ~/ 10) * 10}s';
      grouped.putIfAbsent(decade, () => []).add(movie);
    }

    final sorted = grouped.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    return Map.fromEntries(sorted);
  }

  List<dynamic> _filterByGenre(List<dynamic> movies) {
    if (selectedGenre == null) return movies;
    return movies.where((m) {
      final ids = m['genre_ids'] ?? [];
      return ids.any((id) => TMDbService.genreName(id) == selectedGenre);
    }).toList();
  }

  Widget _buildHeader() {
    final profilePath = actorData?['profile_path'];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        profilePath != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  TMDbService.getImageUrl(profilePath, size: 200),
                  height: 120,
                ),
              )
            : const Icon(Icons.person, size: 120),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (actorData?['birthday'] != null)
                Text('Born: ${actorData!['birthday']}', style: const TextStyle(fontSize: 14)),
              if (actorData?['place_of_birth'] != null)
                Text(actorData!['place_of_birth'], style: const TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 8),
              _buildBiography()
            ],
          ),
        )
      ],
    );
  }

  Widget _buildBiography() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            actorData?['biography'] ?? 'No biography available.',
            style: const TextStyle(fontSize: 14),
            maxLines: isBioExpanded ? null : 4,
            overflow: isBioExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Center(
            child: IconButton(
              icon: Icon(isBioExpanded ? Icons.expand_less : Icons.expand_more),
              onPressed: () => setState(() => isBioExpanded = !isBioExpanded),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildGenres() {
    if (topGenres.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      children: topGenres.map((genre) {
        return FilterChip(
          label: Text(genre),
          selected: selectedGenre == genre,
          onSelected: (val) => setState(() {
            selectedGenre = val ? genre : null;
          }),
        );
      }).toList(),
    );
  }

  Widget _buildFilmography() {
    return ListView(
      children: groupedByDecade.entries.map((entry) {
        final decade = entry.key;
        final movies = _filterByGenre(entry.value);
        final isExpanded = expandedDecades.contains(decade);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: Text(decade, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              trailing: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
              onTap: () {
                setState(() {
                  isExpanded
                      ? expandedDecades.remove(decade)
                      : expandedDecades.add(decade);
                });
              },
            ),
            if (isExpanded)
              ...movies.map((movie) => ListTile(
                    leading: movie['poster_path'] != null
                        ? Image.network(
                            TMDbService.getImageUrl(movie['poster_path']),
                            width: 50,
                          )
                        : const Icon(Icons.movie),
                    title: Text(movie['title']),
                    subtitle: Text(movie['release_date']?.toString().substring(0, 4) ?? ''),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MoviePage(movieId: movie['id']),
                      ),
                    ),
                  )),
          ],
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.actorName)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (actorData != null) _buildHeader(),
            const SizedBox(height: 16),
            _buildGenres(),
            const SizedBox(height: 12),
            Expanded(child: _buildFilmography()),
          ],
        ),
      ),
    );
  }
}
