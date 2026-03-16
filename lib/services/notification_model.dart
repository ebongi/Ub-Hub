import 'package:intl/intl.dart';

enum NotificationType {
  message,
  department,
  course,
  material,
  subscription,
  system;

  static NotificationType fromString(String? type) {
    switch (type?.toLowerCase()) {
      case 'message':
        return NotificationType.message;
      case 'department':
        return NotificationType.department;
      case 'course':
        return NotificationType.course;
      case 'material':
        return NotificationType.material;
      case 'subscription':
        return NotificationType.subscription;
      case 'system':
      default:
        return NotificationType.system;
    }
  }

  String get name => toString().split('.').last;
}

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime createdAt;
  final bool isRead;
  final Map<String, dynamic>? data;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.data,
  });

  factory NotificationModel.fromSupabase(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      type: NotificationType.fromString(json['type'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      isRead: json['is_read'] as bool? ?? false,
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      if (id.isNotEmpty) 'id': id,
      'user_id': userId,
      'title': title,
      'body': body,
      'type': type.name,
      'is_read': isRead,
      if (data != null) 'data': data,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get formattedDate => DateFormat.yMMMd().add_jm().format(createdAt);
}
