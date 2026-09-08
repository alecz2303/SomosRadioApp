import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

class LatestContentItem {
  const LatestContentItem({
    required this.title,
    required this.link,
    required this.description,
    required this.publishedAt,
  });

  final String title;
  final Uri link;
  final String description;
  final DateTime? publishedAt;
}

class LatestContentService {
  const LatestContentService();

  static final Uri _feedUri = Uri.parse('https://somosradiochiapas.com/feed/');

  Future<List<LatestContentItem>> fetchLatest() async {
    final response = await http.get(_feedUri).timeout(const Duration(seconds: 12));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('No fue posible consultar el contenido de Somos Radio.');
    }

    final document = XmlDocument.parse(response.body);
    final items = document.findAllElements('item');

    return items.take(12).map((item) {
      final title = _text(item, 'title');
      final linkText = _text(item, 'link');
      final description = _cleanHtml(_text(item, 'description'));
      final published = _text(item, 'pubDate');

      return LatestContentItem(
        title: title.isEmpty ? 'Publicación de Somos Radio' : title,
        link: Uri.tryParse(linkText) ?? Uri.parse('https://somosradiochiapas.com/'),
        description: description,
        publishedAt: DateTime.tryParse(published),
      );
    }).toList(growable: false);
  }

  static String _text(XmlElement parent, String name) {
    final matches = parent.findElements(name);
    if (matches.isEmpty) return '';
    return matches.first.innerText.trim();
  }

  static String _cleanHtml(String value) {
    return value
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#8217;', '’')
        .replaceAll('&#8220;', '“')
        .replaceAll('&#8221;', '”')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
