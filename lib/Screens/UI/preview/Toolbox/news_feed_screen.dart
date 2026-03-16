import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_study/services/database.dart';
import 'package:go_study/services/campus_models.dart';
import 'package:go_study/services/news_scraper_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_study/Screens/Shared/shimmer_loading.dart';
import 'package:go_study/Screens/Shared/animations.dart';
import 'package:go_study/Screens/Shared/constanst.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:go_study/Screens/Shared/premium_dialog.dart';

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

  Future<bool> _isInternetConnected() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
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
        final institutionId = context.read<UserModel>().institutionId;
        // Use timeout to prevent hanging if the network is flaky
        supabaseNews = await _dbService.getUniversityNews(
          institutionId: institutionId,
        ).first.timeout(
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
          ? const NewsCardShimmer()
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
                  return FadeInSlide(
                    delay: index * 0.1,
                    child: _buildNewsCard(item, theme),
                  );
                },
              ),
            ),
    );
  }

  Widget _buildErrorState() {
    return FutureBuilder<bool>(
      future: _isInternetConnected(),
      builder: (context, snapshot) {
        final hasNoInternet =
            snapshot.connectionState == ConnectionState.done &&
            snapshot.data == false;

        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  hasNoInternet ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
                  size: 64,
                  color: Colors.red.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  hasNoInternet ? "No Connection" : "Couldn't fetch news",
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  hasNoInternet
                      ? "Check your internet and try again."
                      : "An unexpected error occurred. Please try again later.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _loadNews,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text("Retry"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, controller) => Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: controller,
                    padding: const EdgeInsets.all(24),
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          article.source.toUpperCase(),
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        article.title,
                        style: GoogleFonts.outfit(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded,
                              size: 14, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('MMMM d, yyyy').format(article.date),
                            style: GoogleFonts.outfit(
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      if (article.imageUrl != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.network(
                            article.imageUrl!,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      Text(
                        article.content,
                        style: GoogleFonts.outfit(
                          fontSize: 17,
                          height: 1.6,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 40),
                      PremiumSubmitButton(
                        label: "Read Full Article",
                        isLoading: false,
                        onPressed: () async {
                          final uri = Uri.parse(article.id);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
