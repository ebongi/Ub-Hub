import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:go_study/Screens/Shared/animations.dart';
import 'package:go_study/Screens/Shared/constanst.dart';
import 'package:go_study/Screens/Shared/shimmer_loading.dart';
import 'package:go_study/Screens/UI/preview/Toolbox/news_composer_screen.dart';
import 'package:go_study/Screens/UI/preview/Toolbox/news_post_detail_screen.dart';
import 'package:go_study/l10n/generated/app_localizations.dart';
import 'package:go_study/services/database.dart';
import 'package:go_study/services/news_post.dart';
import 'package:go_study/services/profile.dart';

/// The News tool: an admin-authored announcement feed that students can like
/// and comment on. Replaces the old scraped-news view.
class NewsFeedScreen extends StatefulWidget {
  const NewsFeedScreen({super.key});

  @override
  State<NewsFeedScreen> createState() => _NewsFeedScreenState();
}

class _NewsFeedScreenState extends State<NewsFeedScreen> {
  late final DatabaseService _db;
  late Stream<List<NewsPost>> _feed;
  late Stream<Set<String>> _likedIds;

  @override
  void initState() {
    super.initState();
    _db = DatabaseService(uid: Supabase.instance.client.auth.currentUser?.id);
    _feed = _db.getNewsFeed();
    _likedIds = _db.myLikedNewsPostIds();
  }

  void _reload() {
    setState(() {
      _feed = _db.getNewsFeed();
      _likedIds = _db.myLikedNewsPostIds();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isAdmin = context.watch<UserModel>().role == UserRole.admin;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.universityNewsTitle,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              heroTag: 'newsComposeFAB',
              tooltip: l10n.newsAdminNewPostButton,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NewsComposerScreen()),
              ),
              child: const Icon(Icons.add_rounded),
            )
          : null,
      body: StreamBuilder<List<NewsPost>>(
        stream: _feed,
        builder: (context, postSnap) {
          if (postSnap.connectionState == ConnectionState.waiting &&
              !postSnap.hasData) {
            return const NewsCardShimmer();
          }
          if (postSnap.hasError) {
            return _ErrorState(onRetry: _reload);
          }

          final posts = postSnap.data ?? const <NewsPost>[];
          if (posts.isEmpty) return _EmptyState(l10n: l10n);

          return StreamBuilder<Set<String>>(
            stream: _likedIds,
            initialData: const <String>{},
            builder: (context, likeSnap) {
              final liked = likeSnap.data ?? const <String>{};
              return RefreshIndicator(
                onRefresh: () async {
                  await Future<void>.delayed(const Duration(milliseconds: 300));
                },
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return FadeInSlide(
                      delay: (index * 0.06).clamp(0, 0.4),
                      child: _NewsPostCard(
                        post: post,
                        likedByMe: liked.contains(post.id),
                        isAdmin: isAdmin,
                        db: _db,
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// A single feed card: author header, title, body preview, optional cover
/// image, and a like / comment action row.
class _NewsPostCard extends StatefulWidget {
  const _NewsPostCard({
    required this.post,
    required this.likedByMe,
    required this.isAdmin,
    required this.db,
  });

  final NewsPost post;
  final bool likedByMe;
  final bool isAdmin;
  final DatabaseService db;

  @override
  State<_NewsPostCard> createState() => _NewsPostCardState();
}

class _NewsPostCardState extends State<_NewsPostCard> {
  late bool _liked = widget.likedByMe;
  late int _likeCount = widget.post.likeCount;
  bool _busy = false;

  @override
  void didUpdateWidget(covariant _NewsPostCard old) {
    super.didUpdateWidget(old);
    // Re-sync with server truth when we're not mid-toggle.
    if (!_busy) {
      _liked = widget.likedByMe;
      _likeCount = widget.post.likeCount;
    }
  }

  Future<void> _toggleLike() async {
    if (_busy) return;
    final next = !_liked;
    setState(() {
      _busy = true;
      _liked = next;
      _likeCount = (_likeCount + (next ? 1 : -1)).clamp(0, 1 << 31);
    });
    HapticFeedback.lightImpact();
    try {
      await widget.db.setNewsLike(widget.post.id, next);
    } catch (_) {
      if (mounted) {
        setState(() {
          _liked = !next;
          _likeCount = (_likeCount + (next ? -1 : 1)).clamp(0, 1 << 31);
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _openDetail() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NewsPostDetailScreen(post: widget.post),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final post = widget.post;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? theme.colorScheme.surfaceContainerLow
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.3),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _openDetail,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 6, 0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
                      child: Icon(
                        Iconsax.d_cube_scan_copy,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.authorName?.trim().isNotEmpty == true
                                ? post.authorName!
                                : l10n.newsAuthorFallback,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            newsTimeAgo(post.createdAt),
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: theme.hintColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.isAdmin)
                      _AdminPostMenu(post: post, db: widget.db),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.title,
                      style: GoogleFonts.outfit(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      post.body,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        height: 1.45,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (post.imageUrl != null && post.imageUrl!.isNotEmpty) ...[
                const SizedBox(height: 12),
                CachedNetworkImage(
                  imageUrl: post.imageUrl!,
                  width: double.infinity,
                  height: 190,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    height: 190,
                    color: theme.colorScheme.primary.withOpacity(0.06),
                  ),
                  errorWidget: (_, __, ___) => const SizedBox.shrink(),
                ),
              ],
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 4, 14, 4),
                child: Row(
                  children: [
                    _ActionButton(
                      icon: _liked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: _liked ? Colors.redAccent : theme.hintColor,
                      label: '$_likeCount',
                      onTap: _toggleLike,
                    ),
                    _ActionButton(
                      icon: Iconsax.message_copy,
                      color: theme.hintColor,
                      label: '${post.commentCount}',
                      onTap: _openDetail,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 19, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The "..." menu on a card / detail screen — admins only. Edit + delete.
class _AdminPostMenu extends StatelessWidget {
  const _AdminPostMenu({required this.post, required this.db});

  final NewsPost post;
  final DatabaseService db;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_horiz_rounded, color: Theme.of(context).hintColor),
      onSelected: (value) async {
        if (value == 'edit') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => NewsComposerScreen(existing: post),
            ),
          );
        } else if (value == 'delete') {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Text(
                l10n.newsDeletePostTitle,
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              ),
              content: Text(
                l10n.newsDeletePostBody,
                style: GoogleFonts.outfit(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(l10n.cancel, style: GoogleFonts.outfit()),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(
                    l10n.deleteButton,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          );
          if (confirmed == true) {
            try {
              await db.deleteNewsPost(post.id);
            } catch (_) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.couldntFetchNews)),
                );
              }
            }
          }
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(value: 'edit', child: Text(l10n.editButton)),
        PopupMenuItem(
          value: 'delete',
          child: Text(
            l10n.deleteButton,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
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
            l10n.noAnnouncementsYet,
            style: GoogleFonts.outfit(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;

  Future<bool> _isOffline() async {
    final result = await Connectivity().checkConnectivity();
    return result.contains(ConnectivityResult.none);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<bool>(
      future: _isOffline(),
      builder: (context, snap) {
        final offline = snap.data == true;
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  offline ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
                  size: 60,
                  color: Colors.red.withOpacity(0.5),
                ),
                const SizedBox(height: 14),
                Text(
                  offline ? l10n.noConnectionTitle : l10n.couldntFetchNews,
                  style: GoogleFonts.outfit(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(l10n.retryButton),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
