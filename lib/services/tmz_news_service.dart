import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

class TMZNewsService {
  static const String _rssUrl = 'https://www.tmz.com/rss.xml';

  static final Set<String> _blockedKeywords = {
    'kardashian',
    'jenner',
    'paparazzi',
    'romance',
    'dating',
    'baby bump',
    'baby shower',
    'split',
    'divorce',
    'spotted',
    'caught',
    'cheating',
    'hookup',
    'gossip',
    'breakup',
  };

  static Future<List<Map<String, String>>> fetchFilteredArticles() async {
    final response = await http.get(Uri.parse(_rssUrl));
    if (response.statusCode != 200) return [];

    final xmlDoc = XmlDocument.parse(response.body);
    final items = xmlDoc.findAllElements('item');

    return items.map((item) {
      final title = item.getElement('title')?.text ?? '';
      final link = item.getElement('link')?.text ?? '';
      final description = item.getElement('description')?.text ?? '';
      final pubDate = item.getElement('pubDate')?.text ?? '';

      // Search for any <media:content> tag with a valid image URL
      final media = item.findElements('media:content').firstWhere(
        (el) {
          final url = el.getAttribute('url') ?? '';
          return url.endsWith('.jpg') || url.endsWith('.png');
        },
        orElse: () => XmlElement(XmlName('media:content')),
      );

      final imageUrl = media.getAttribute('url') ?? '';

      return {
        'title': title,
        'link': link,
        'description': description,
        'pubDate': pubDate,
        'imageUrl': imageUrl,
      };
    }).where((article) {
      final content = '${article['title']} ${article['description']}'.toLowerCase();
      return !_blockedKeywords.any((term) => content.contains(term));
    }).toList();
  }
}
