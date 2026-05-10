class BotKnowledge {
  final String id;
  final String userId;
  final String title;
  final String content;
  final bool isGlobal;
  final DateTime createdAt;

  BotKnowledge({
    this.id = '',
    required this.userId,
    required this.title,
    required this.content,
    this.isGlobal = false,
    required this.createdAt,
  });

  factory BotKnowledge.fromSupabase(Map<String, dynamic> json) {
    return BotKnowledge(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      isGlobal: json['is_global'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'user_id': userId,
      'title': title,
      'content': content,
      'is_global': isGlobal,
      if (id.isNotEmpty) 'id': id,
    };
  }
}
