import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:go_study/Screens/Shared/constanst.dart';
import 'package:go_study/Screens/UI/preview/Toolbox/news_composer_screen.dart';
import 'package:go_study/l10n/generated/app_localizations.dart';
import 'package:go_study/services/database.dart';
import 'package:go_study/services/news_post.dart';
import 'package:go_study/services/profile.dart';

class NewsPostDetailScreen extends StatefulWidget {
  const NewsPostDetailScreen({super.key, required this.post});

  final NewsPost post;

  @override
  State<NewsPostDetailScreen> createState() => _NewsPostDetailScreenState();
}

class _NewsPostDetailScreenState extends State<NewsPostDetailScreen> {
  late final DatabaseService _db;
  late final Stream<List<NewsComment>> _comments;
  final _commentController = TextEditingController();
  final _scrollController = ScrollController();
  final String? _uid = Supabase.instance.client.auth.currentUser?.id;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _db = DatabaseService(uid: _uid);
    _comments = _db.getNewsComments(widget.post.id);
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _sending) return;
    final userModel = context.read<UserModel>();
    setState(() => _sending = true);
    try {
      await _db.addNewsComment(
        postId: widget.post.id,
        content: text,
        authorName: userModel.name,
        authorAvatarUrl: userModel.avatarUrl,
      );
      _commentController.clear();
      if (mounted) FocusScope.of(context).unfocus();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.couldntFetchNews)),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _confirmDeleteComment(NewsComment comment) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          l10n.newsDeleteCommentTitle,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Text(l10n.newsDeleteCommentBody, style: GoogleFonts.outfit()),
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
        await _db.deleteNewsComment(comment.id);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final post = widget.post;
    final isAdmin = context.watch<UserModel>().role == UserRole.admin;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.universityNewsTitle,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (isAdmin)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_horiz_rounded),
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
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    try {
                      await _db.deleteNewsPost(post.id);
                      if (context.mounted) Navigator.pop(context);
                    } catch (_) {}
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
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<NewsComment>>(
              stream: _comments,
              builder: (context, snap) {
                final comments = snap.data ?? const <NewsComment>[];
                return ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    if (post.imageUrl != null && post.imageUrl!.isNotEmpty) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: CachedNetworkImage(
                          imageUrl: post.imageUrl!,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Text(
                      post.title,
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor:
                              theme.colorScheme.primary.withOpacity(0.12),
                          child: Icon(
                            Iconsax.d_cube_scan_copy,
                            size: 16,
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
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                DateFormat.yMMMMd().add_jm().format(
                                  post.createdAt.toLocal(),
                                ),
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: theme.hintColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      post.body,
                      style: GoogleFonts.outfit(fontSize: 15.5, height: 1.6),
                    ),
                    const SizedBox(height: 18),
                    _LikeRow(post: post, db: _db),
                    const Divider(height: 32),
                    Text(
                      l10n.newsCommentsHeader(comments.length),
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (snap.connectionState == ConnectionState.waiting)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (comments.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            l10n.newsNoCommentsYet,
                            style: GoogleFonts.outfit(color: theme.hintColor),
                          ),
                        ),
                      )
                    else
                      ...comments.map(
                        (c) => _CommentTile(
                          comment: c,
                          canDelete: c.userId == _uid || isAdmin,
                          onDelete: () => _confirmDeleteComment(c),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          _CommentComposer(
            controller: _commentController,
            sending: _sending,
            onSend: _sendComment,
          ),
        ],
      ),
    );
  }
}

/// Like button + count for the detail screen. Reads the current user's like
/// state from the same stream the feed uses.
class _LikeRow extends StatefulWidget {
  const _LikeRow({required this.post, required this.db});
  final NewsPost post;
  final DatabaseService db;

  @override
  State<_LikeRow> createState() => _LikeRowState();
}

class _LikeRowState extends State<_LikeRow> {
  late final Stream<Set<String>> _likedStream = widget.db.myLikedNewsPostIds();
  bool _busy = false;
  bool? _overrideLiked;
  int _delta = 0;

  Future<void> _toggle(bool current) async {
    if (_busy) return;
    final next = !current;
    setState(() {
      _busy = true;
      _overrideLiked = next;
      _delta += next ? 1 : -1;
    });
    HapticFeedback.lightImpact();
    try {
      await widget.db.setNewsLike(widget.post.id, next);
    } catch (_) {
      setState(() {
        _overrideLiked = current;
        _delta += next ? -1 : 1;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<Set<String>>(
      stream: _likedStream,
      initialData: const <String>{},
      builder: (context, snap) {
        final likedFromServer =
            (snap.data ?? const <String>{}).contains(widget.post.id);
        final liked = _overrideLiked ?? likedFromServer;
        final count =
            (widget.post.likeCount + _delta).clamp(0, 1 << 31);
        return Row(
          children: [
            InkWell(
              onTap: () => _toggle(liked),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                child: Row(
                  children: [
                    Icon(
                      liked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: liked ? Colors.redAccent : theme.hintColor,
                      size: 22,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$count',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600,
                        color: liked ? Colors.redAccent : theme.hintColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.comment,
    required this.canDelete,
    required this.onDelete,
  });

  final NewsComment comment;
  final bool canDelete;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasAvatar =
        comment.authorAvatarUrl != null && comment.authorAvatarUrl!.isNotEmpty;
    final name = comment.authorName?.trim().isNotEmpty == true
        ? comment.authorName!.trim()
        : AppLocalizations.of(context)!.unknownUserFallback;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
            backgroundImage:
                hasAvatar ? CachedNetworkImageProvider(comment.authorAvatarUrl!) : null,
            child: hasAvatar
                ? null
                : Text(
                    name.substring(0, 1).toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      newsTimeAgo(comment.createdAt),
                      style: GoogleFonts.outfit(
                        fontSize: 11.5,
                        color: theme.hintColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  comment.content,
                  style: GoogleFonts.outfit(fontSize: 13.5, height: 1.4),
                ),
              ],
            ),
          ),
          if (canDelete)
            InkWell(
              onTap: onDelete,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: theme.hintColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CommentComposer extends StatelessWidget {
  const _CommentComposer({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        8,
        8,
        8 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                style: GoogleFonts.outfit(fontSize: 14),
                decoration: InputDecoration(
                  hintText: l10n.newsCommentHintText,
                  hintStyle: GoogleFonts.outfit(color: theme.hintColor),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerLow,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: l10n.newsSendCommentTooltip,
              onPressed: sending ? null : onSend,
              icon: sending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.send_rounded, color: theme.colorScheme.primary),
            ),
          ],
        ),
      ),
    );
  }
}
