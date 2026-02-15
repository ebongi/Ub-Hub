import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:neo/services/campus_models.dart';
import 'package:neo/core/app_config.dart';

class NewsScraperService {
  static const String baseUrl = 'https://newsapi.org/v2/everything';

  Future<List<NewsArticle>> fetchLatestNews() async {
    final apiKey = AppConfig.newsApiKey;
    if (apiKey.isEmpty || apiKey == 'YOUR_NEWS_API_KEY') {
      print("NewsAPI Key missing or invalid. Falling back to empty news.");
      return [];
    }

    try {
      // Broaden search: No quotes, and add related terms
      final query = Uri.encodeComponent(
        'University of Buea OR "UB Buea" OR "University of Buea Cameroon"',
      );
      final url = Uri.parse(
        '$baseUrl?q=$query&sortBy=publishedAt&pageSize=20&apiKey=$apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode != 200) {
        print("NewsAPI error: Status ${response.statusCode}");
        return [];
      }

      final data = json.decode(response.body);
      final List articles = data['articles'] ?? [];

      return articles.map((article) {
        final source = article['source']?['name'] ?? 'News';
        return NewsArticle(
          id: article['url'] ?? '',
          title: article['title'] ?? 'No Title',
          content:
              article['description'] ??
              article['content'] ??
              'Read more at the source.',
          source: source,
          date: article['publishedAt'] != null
              ? DateTime.parse(article['publishedAt'])
              : DateTime.now(),
          imageUrl: article['urlToImage'],
        );
      }).toList();
    } catch (e) {
      print("NewsAPI fetch error: $e");
      return [];
    }
  }
}
