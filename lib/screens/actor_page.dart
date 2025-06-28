import 'package:flutter/material.dart';
import '../services/tmdb_service.dart';

class ActorPage extends StatefulWidget {
  final String actorName;

  const ActorPage({super.key, required this.actorName});

  @override
  State<ActorPage> createState() => _ActorPageState();
}

class _ActorPageState extends State<ActorPage> {
  Map<String, dynamic>? actorData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchActor();
  }

  Future<void> fetchActor() async {
    final result = await TMDbService.searchActorByName(widget.actorName);
    setState(() {
      actorData = result;
      isLoading = false;
    });
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
                    children: [
                      if (actorData!['profile_path'] != null)
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: NetworkImage(
                            TMDbService.getProfileImageUrl(actorData!['profile_path']),
                          ),
                        )
                      else
                        const CircleAvatar(
                          radius: 50,
                          child: Icon(Icons.person, size: 40),
                        ),
                      const SizedBox(height: 20),
                      Text(
                        actorData!['name'] ?? 'No name',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        actorData!['known_for_department'] ?? 'No department info',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        actorData!['popularity'] != null
                            ? 'Popularity: ${actorData!['popularity'].toStringAsFixed(1)}'
                            : 'No popularity score',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
    );
  }
}
