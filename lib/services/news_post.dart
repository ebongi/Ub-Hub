/// Models for the News feature: admin-authored [NewsPost]s that students can
/// like and comment on. Backed by the `news_posts` / `news_comments` /
/// `news_likes` tables (see supabase/migrations/create_news_posts.sql).
///
/// Replaces the old scraped-news feed (formerly `NewsArticle` in
/// campus_models.dart, removed as dead code).
library;

class NewsPost {
  final String id;
  final String? authorId;
  final String? authorName;
  final String title;
  final String body;
  final String? imageUrl;
  final bool isPublished;
  final int likeCount;
  final int commentCount;
  final DateTime createdAt;
  final DateTime? updatedAt;

  NewsPost({
    this.id = '',
    this.authorId,
    this.authorName,
    required this.title,
    required this.body,
    this.imageUrl,
    this.isPublished = true,
    this.likeCount = 0,
    this.commentCount = 0,
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory NewsPost.fromSupabase(Map<String, dynamic> json) {
    return NewsPost(
      id: json['id'] ?? '',
      authorId: json['author_id'],
      authorName: json['author_name'],
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      imageUrl: json['image_url'],
      isPublished: json['is_published'] ?? true,
      likeCount: json['like_count'] ?? 0,
      commentCount: json['comment_count'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  /// Only the columns an admin client is allowed to write. Counts, timestamps
  /// and id are managed by the DB (defaults + triggers).
  Map<String, dynamic> toSupabase() {
    return {
      if (id.isNotEmpty) 'id': id,
      if (authorId != null) 'author_id': authorId,
      if (authorName != null) 'author_name': authorName,
      'title': title,
      'body': body,
      'image_url': imageUrl,
      'is_published': isPublished,
    };
  }

  NewsPost copyWith({
    String? title,
    String? body,
    String? imageUrl,
    bool? isPublished,
    int? likeCount,
    int? commentCount,
  }) {
    return NewsPost(
      id: id,
      authorId: authorId,
      authorName: authorName,
      title: title ?? this.title,
      body: body ?? this.body,
      imageUrl: imageUrl ?? this.imageUrl,
      isPublished: isPublished ?? this.isPublished,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class NewsComment {
  final String id;
  final String postId;
  final String userId;
  final String? authorName;
  final String? authorAvatarUrl;
  final String content;
  final DateTime createdAt;

  NewsComment({
    this.id = '',
    required this.postId,
    required this.userId,
    this.authorName,
    this.authorAvatarUrl,
    required this.content,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory NewsComment.fromSupabase(Map<String, dynamic> json) {
    return NewsComment(
      id: json['id'] ?? '',
      postId: json['post_id'] ?? '',
      userId: json['user_id'] ?? '',
      authorName: json['author_name'],
      authorAvatarUrl: json['author_avatar_url'],
      content: json['content'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      if (id.isNotEmpty) 'id': id,
      'post_id': postId,
      'user_id': userId,
      if (authorName != null) 'author_name': authorName,
      if (authorAvatarUrl != null) 'author_avatar_url': authorAvatarUrl,
      'content': content,
    };
  }
}

/// Compact "time ago" label for feed cards and comments ("now", "4m", "9h",
/// "3d", then a short date). Deliberately terse to match the news feed design.
String newsTimeAgo(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inSeconds < 60) return 'now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  if (diff.inDays < 7) return '${diff.inDays}d';
  final d = date;
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final sameYear = d.year == DateTime.now().year;
  return sameYear
      ? '${months[d.month - 1]} ${d.day}'
      : '${months[d.month - 1]} ${d.day}, ${d.year}';
}
