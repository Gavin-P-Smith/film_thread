import 'package:flutter/material.dart';
import 'movie_page.dart'; // ✅ Import the unified MoviePage

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '🎬 Film Thread',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.mic),
                    onPressed: () {
                      // Simulate a movie match — hardcoded TMDb movie ID
                      const int fakeMovieId = 24428; // Example: The Avengers
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MoviePage(movieId: fakeMovieId),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'News Section (Coming Soon)',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Social Media Feed (Coming Soon)',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Actor of the Day (Coming Soon)',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
