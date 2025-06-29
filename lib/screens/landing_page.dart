import 'dart:async';
import 'package:flutter/material.dart';
import '../services/tmdb_service.dart';
import '../services/tmz_news_service.dart';
import 'media_page.dart';
import 'actor_page.dart';
import 'package:url_launcher/url_launcher.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  bool testTv = true;
  String searchQuery = '';
  List<dynamic> searchResults = [];
  bool isSearching = false;
  Timer? _debounce;
  List<Map<String, String>> news = [];
  bool loadingNews = true;

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  Future<void> _loadNews() async {
    final items = await TMZNewsService.fetchFilteredArticles();
    setState(() {
      news = items;
      loadingNews = false;
    });
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (query.trim().length > 2) {
        _performSearch(query);
      } else {
        setState(() {
          searchResults = [];
          searchQuery = query;
        });
      }
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      searchQuery = query;
      isSearching = true;
    });

    final results = await TMDbService.searchMulti(query);
    setState(() {
      searchResults = results;
      isSearching = false;
    });
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: TextField(
        decoration: const InputDecoration(
          hintText: 'Search movies, TV shows, or actors...',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(),
        ),
        onChanged: _onSearchChanged,
      ),
    );
  }

  Widget _buildSearchResults() {
    if (isSearching) return const Center(child: CircularProgressIndicator());
    if (searchQuery.isEmpty || searchResults.isEmpty) return const SizedBox.shrink();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: searchResults.length,
      itemBuilder: (_, index) {
        final item = searchResults[index];
        final mediaType = item['media_type'];
        final title = item['title'] ?? item['name'] ?? 'Untitled';
        final imagePath = item['poster_path'] ?? item['profile_path'];

        return ListTile(
          leading: imagePath != null
              ? Image.network(TMDbService.getImageUrl(imagePath), width: 50, fit: BoxFit.cover)
              : const Icon(Icons.movie),
          title: Text(title),
          subtitle: Text(mediaType.toString().toUpperCase()),
          onTap: () {
            if (mediaType == 'movie' || mediaType == 'tv') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MediaPage(id: item['id'], mediaType: mediaType),
                ),
              );
            } else if (mediaType == 'person') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ActorPage(actorName: item['name']),
                ),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildNewsSection() {
    if (loadingNews) return const Center(child: CircularProgressIndicator());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
          child: Text('📰 Entertainment News', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        SizedBox(
          height: 270,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: news.length,
            itemBuilder: (context, index) {
              final article = news[index];
              final imageUrl = article['imageUrl'];
              final title = article['title'] ?? '';
              final description = article['description'] ?? '';
              final link = article['link'] ?? '';

              return Container(
                width: 280,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                child: GestureDetector(
                  onTap: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    builder: (_) => DraggableScrollableSheet(
                      expand: false,
                      initialChildSize: 0.6,
                      minChildSize: 0.4,
                      maxChildSize: 0.9,
                      builder: (_, controller) => Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ListView(
                          controller: controller,
                          children: [
                            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            Text(description),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: () => launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication),
                              icon: const Icon(Icons.open_in_browser),
                              label: const Text('Read Full Article'),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        imageUrl != null && imageUrl.isNotEmpty
                            ? Image.network(
                                imageUrl,
                                height: 140,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  height: 140,
                                  color: Colors.grey[300],
                                  child: const Center(child: Icon(Icons.image_not_supported)),
                                ),
                              )
                            : Container(
                                height: 140,
                                color: Colors.grey[300],
                                child: const Center(child: Icon(Icons.image_not_supported)),
                              ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTestToggleRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          const Text('Test TV Show'),
          const SizedBox(width: 8),
          Switch(
            value: testTv,
            onChanged: (val) => setState(() => testTv = val),
          ),
          Text(testTv ? 'TV Mode' : 'Movie Mode', style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildTestMicButton() {
    return IconButton(
      icon: const Icon(Icons.mic),
      onPressed: () {
        if (testTv) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MediaPage(id: 1399, mediaType: 'tv'),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MediaPage(id: 24428, mediaType: 'movie'),
            ),
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('🎬 Film Thread', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  _buildTestMicButton(),
                ],
              ),
            ),
            _buildTestToggleRow(),
            _buildSearchBar(),
            _buildSearchResults(),
            _buildNewsSection(),
          ],
        ),
      ),
    );
  }
}
