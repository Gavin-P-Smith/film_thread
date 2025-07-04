import 'dart:async';
import 'package:flutter/material.dart';
import '../services/tmdb_service.dart';
import '../services/tmz_news_service.dart';
import 'media_page.dart';
import 'actor_page.dart';
import '../widgets/unified_app_bar.dart';
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

  void _onMicPressed() {
    final mediaType = testTv ? 'tv' : 'movie';
    final mediaId = testTv ? 1399 : 24428;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MediaPage(id: mediaId, mediaType: mediaType),
      ),
    );
  }

  Widget _buildNewsSection(TextTheme textTheme, ColorScheme colorScheme) {
    if (loadingNews) return const Center(child: CircularProgressIndicator());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
          child: Text('📰 Entertainment News', style: textTheme.titleLarge),
        ),
        SizedBox(
          height: 270,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: news.length,
            itemBuilder: (context, index) {
              final article = news[index];
              final imageUrl = article['imageUrl'] ?? '';
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
                    backgroundColor: colorScheme.background,
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
                            Text(title, style: textTheme.titleLarge),
                            const SizedBox(height: 12),
                            Text(description, style: textTheme.bodyMedium),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: () => launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication),
                              icon: const Icon(Icons.open_in_browser, color: Colors.white),
                              label: Text('Read Full Article', style: textTheme.labelLarge?.copyWith(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
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
                        imageUrl.isNotEmpty
                            ? Image.network(
                                imageUrl,
                                height: 140,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  height: 140,
                                  color: Colors.grey[800],
                                  child: const Center(child: Icon(Icons.broken_image, color: Colors.white)),
                                ),
                              )
                            : Container(
                                height: 140,
                                color: Colors.grey[800],
                                child: const Center(child: Icon(Icons.image, color: Colors.white)),
                              ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(title, style: textTheme.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(description, style: textTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
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

  Widget _buildTestToggleRow(TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Text('Test TV Show', style: textTheme.bodyMedium),
          const SizedBox(width: 8),
          Switch(
            value: testTv,
            onChanged: (val) => setState(() => testTv = val),
          ),
          Text(testTv ? 'TV Mode' : 'Movie Mode', style: textTheme.bodySmall),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: UnifiedAppBar(onMicPressed: _onMicPressed),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _buildTestToggleRow(textTheme),
          _buildNewsSection(textTheme, colorScheme),
        ],
      ),
    );
  }
}
