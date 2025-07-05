import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'package:html_unescape/html_unescape.dart';

class VarietyNewsService {
  static const String _rssUrl = 'https://variety.com/v/film/feed/';

  static Future<List<Map<String, String>>> fetchFilteredArticles() async {
    final response = await http.get(Uri.parse(_rssUrl));
    if (response.statusCode != 200) return [];

    final xmlDoc = XmlDocument.parse(response.body);
    final items = xmlDoc.findAllElements('item');
    final unescape = HtmlUnescape();

    return items.map((item) {
      final titleRaw = item.getElement('title')?.text ?? '';
      final descriptionRaw = item.getElement('description')?.text ?? '';
      final link = item.getElement('link')?.text ?? '';
      final pubDate = item.getElement('pubDate')?.text ?? '';

      // Unescape HTML entities
      final title = unescape.convert(titleRaw);
      final description = unescape.convert(
        descriptionRaw.replaceAll(RegExp(r'<[^>]*>'), '').trim(),
      );

      // Extract image if available from media:content
      final media = item.findAllElements('media:content').firstWhere(
        (el) {
          final url = el.getAttribute('url') ?? '';
          return url.endsWith('.jpg') || url.endsWith('.png');
        },
        orElse: () => XmlElement(XmlName('media:content')),
      );

      final imageUrl = media.getAttribute('url') ?? '';

      return {
        'title': title,
        'description': description,
        'link': link,
        'pubDate': pubDate,
        'imageUrl': imageUrl,
      };
    }).toList();
  }
}
