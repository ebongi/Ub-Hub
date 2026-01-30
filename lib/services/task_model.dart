class TodoTask {
  final String id;
  final String userId;
  final String title;
  final String description;
  final DateTime? deadline;
  final DateTime? reminder;
  final double progress; // 0.0 to 1.0
  final String priority; // Low, Medium, High
  final String category;
  final bool isDone;
  final DateTime? createdAt;

  TodoTask({
    this.id = '',
    required this.userId,
    required this.title,
    this.description = "",
    this.deadline,
    this.reminder,
    this.progress = 0.0,
    this.priority = "Medium",
    this.category = "Personal",
    this.isDone = false,
    this.createdAt,
  });

  factory TodoTask.fromSupabase(Map<String, dynamic> json) {
    return TodoTask(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      deadline: json['deadline'] != null
          ? DateTime.parse(json['deadline'])
          : null,
      reminder: json['reminder'] != null
          ? DateTime.parse(json['reminder'])
          : null,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      priority: json['priority'] ?? 'Medium',
      category: json['category'] ?? 'Personal',
      isDone: json['is_done'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'user_id': userId,
      'title': title,
      'description': description,
      if (deadline != null) 'deadline': deadline!.toIso8601String(),
      if (reminder != null) 'reminder': reminder!.toIso8601String(),
      'progress': progress,
      'priority': priority,
      'category': category,
      'is_done': isDone,
      if (id.isNotEmpty) 'id': id,
    };
  }
}
