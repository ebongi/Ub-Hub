class ExamEvent {
  final String id;
  final String userId;
  final String name;
  final String category;
  final String? venue;
  final DateTime startTime;
  final DateTime endTime;
  final String? description;
  final String? imageUrl;
  final String status;
  final DateTime? createdAt;

  ExamEvent({
    this.id = '',
    required this.userId,
    required this.name,
    required this.category,
    this.venue,
    required this.startTime,
    required this.endTime,
    this.description,
    this.imageUrl,
    this.status = 'active',
    this.createdAt,
  });

  factory ExamEvent.fromSupabase(Map<String, dynamic> json) {
    return ExamEvent(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      venue: json['venue'],
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      description: json['description'],
      imageUrl: json['image_url'],
      status: json['status'] ?? 'active',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'user_id': userId,
      'name': name,
      'category': category,
      if (venue != null) 'venue': venue,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      if (description != null) 'description': description,
      if (imageUrl != null) 'image_url': imageUrl,
      'status': status,
      if (id.isNotEmpty) 'id': id,
    };
  }
}
