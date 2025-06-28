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
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchActor();
  }

  Future<void> fetchActor() async {
    final result = await TMDbService.searchActorByName(widget.actorName);

    if (result != null) {
      final personId = result['id'];
      final credits = await TMDbService.getFilmography(personId);

      credits.sort((a, b) {
        final dateA = DateTime.tryParse(a['release_date'] ?? '') ?? DateTime(1900);
        final dateB = DateTime.tryParse(b['release_date'] ?? '') ?? DateTime(1900);
        return dateB.compareTo(dateA);
      });

      setState(() {
        actorData = result;
        filmography = credits;
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.actorName)),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : actorData == null
              ? const Center(child: Text('Actor not found.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: actorData!['profile_path'] != null
                            ? CircleAvatar(
                                radius: 50,
                                backgroundImage: NetworkImage(
                                  TMDbService.getImageUrl(actorData!['profile_path']),
                                ),
                              )
                            : const CircleAvatar(
                                radius: 50,
                                child: Icon(Icons.person, size: 40),
                              ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: Text(
                          actorData!['name'] ?? 'No name',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: Text(
                          actorData!['known_for_department'] ?? 'No department info',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: Text(
                          actorData!['popularity'] != null
                              ? 'Popularity: ${actorData!['popularity'].toStringAsFixed(1)}'
                              : 'No popularity score',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 30),
                      const Text(
                        'Filmography',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filmography.length,
                        itemBuilder: (context, index) {
                          final film = filmography[index];
                          final title = film['title'] ?? 'Untitled';
                          final year = (film['release_date'] != null && film['release_date'].toString().isNotEmpty)
                              ? ' (${film['release_date'].toString().substring(0, 4)})'
                              : '';

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MoviePage(movieId: film['id']),
                                ),
                              );
                            },
                            child: ListTile(
                              leading: film['poster_path'] != null
                                  ? Image.network(
                                      TMDbService.getImageUrl(film['poster_path']),
                                      width: 50,
                                      fit: BoxFit.cover,
                                    )
                                  : const Icon(Icons.movie),
                              title: Text('$title$year'),
                              subtitle: film['character'] != null
                                  ? Text('as ${film['character']}')
                                  : null,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
    );
  }
}
