import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neo/services/database.dart';
import 'package:neo/services/campus_models.dart';
import 'package:neo/services/news_scraper_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class NewsFeedScreen extends StatefulWidget {
  const NewsFeedScreen({super.key});

  @override
  State<NewsFeedScreen> createState() => _NewsFeedScreenState();
}

class _NewsFeedScreenState extends State<NewsFeedScreen> {
  late final DatabaseService _dbService;
  final NewsScraperService _scraperService = NewsScraperService();
  final String? _uid = Supabase.instance.client.auth.currentUser?.id;

  List<NewsArticle>? _allNews;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _dbService = DatabaseService(uid: _uid);
    _loadNews();
  }

  Future<void> _loadNews() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 1. Fetch from Website (RSS)
      final scraperNews = await _scraperService.fetchLatestNews();

      // 2. Fetch from Supabase with safety
      List<NewsArticle> supabaseNews = [];
      try {
        // Use timeout to prevent hanging if the network is flaky
        supabaseNews = await _dbService.getUniversityNews().first.timeout(
          const Duration(seconds: 5),
          onTimeout: () => [],
        );
      } catch (e) {
        print("Supabase news fetch error: $e");
      }

      // 3. Combine and filter duplicates (by title or ID)
      final Map<String, NewsArticle> uniqueNews = {};
      for (var n in scraperNews) {
        uniqueNews[n.title] = n;
      }
      for (var n in supabaseNews) {
        uniqueNews[n.title] = n;
      }

      final combined = uniqueNews.values.toList();
      combined.sort((a, b) => b.date.compareTo(a.date));

      if (mounted) {
        setState(() {
          _allNews = combined;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      print("Global news fetch error: $e");
      print(stackTrace);
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "University News",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _loadNews,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: "Refresh News",
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null && (_allNews == null || _allNews!.isEmpty)
          ? _buildErrorState()
          : _allNews == null || _allNews!.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _loadNews,
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: _allNews!.length,
                itemBuilder: (context, index) {
                  final item = _allNews![index];
                  return _buildNewsCard(item, theme);
                },
              ),
            ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 64,
              color: Colors.red.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              "Couldn't fetch latest news",
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Please check your internet connection or try again later.",
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _loadNews, child: const Text("Retry")),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.newspaper_rounded,
            size: 64,
            color: Colors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            "No announcements yet.",
            style: GoogleFonts.outfit(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsCard(NewsArticle article, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: () => _showNewsDetail(article),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (article.imageUrl != null)
              Image.network(
                article.imageUrl!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 180,
                  color: theme.colorScheme.primaryContainer,
                  child: Icon(
                    Icons.image_not_supported_rounded,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          article.source.replaceAll('_', ' ').toUpperCase(),
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      Text(
                        DateFormat('MMM d, yyyy').format(article.date),
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    article.title,
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    article.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      color: Colors.grey[700],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNewsDetail(NewsArticle article) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                article.title,
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "${article.source.toUpperCase()} • ${DateFormat('MMMM d, yyyy').format(article.date)}",
                style: GoogleFonts.outfit(
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              if (article.imageUrl != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(article.imageUrl!),
                ),
                const SizedBox(height: 24),
              ],
              Text(
                article.content,
                style: GoogleFonts.outfit(fontSize: 16, height: 1.6),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final uri = Uri.parse(article.id);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: Text(
                    "Read Full Article",
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
