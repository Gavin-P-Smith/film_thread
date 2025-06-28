import 'package:flutter/material.dart';
import 'actor_page.dart';

class ResultPage extends StatelessWidget {
  const ResultPage({super.key});

  // Mock actor list
  final List<Map<String, String>> cast = const [
    {
      'name': 'Scarlett Johansson',
      'image': 'https://via.placeholder.com/100x100.png?text=Scarlett'
    },
    {
      'name': 'Chris Evans',
      'image': 'https://via.placeholder.com/100x100.png?text=Chris'
    },
    {
      'name': 'Robert Downey Jr.',
      'image': 'https://via.placeholder.com/100x100.png?text=Robert'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Match Found'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🎥 The Avengers',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              height: 200,
              color: Colors.grey[800],
              child: const Center(child: Text('Poster Placeholder')),
            ),
            const SizedBox(height: 24),
            const Text(
              'Cast',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: cast.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  final actor = cast[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ActorPage(actorName: actor['name']!),
                        ),
                      );
                    },
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 35,
                          backgroundImage: NetworkImage(actor['image']!),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: 80,
                          child: Text(
                            actor['name']!,
                            style: const TextStyle(fontSize: 12),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
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
