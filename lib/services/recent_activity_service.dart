import 'package:shared_preferences/shared_preferences.dart';

class RecentActivity {
  final String id;
  final String name;
  final String? imageUrl;
  final DateTime timestamp;

  RecentActivity({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.timestamp,
  });

  Map<String, String> toMap() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl ?? '',
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory RecentActivity.fromMap(Map<String, String> map) {
    return RecentActivity(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      imageUrl: map['imageUrl'],
      timestamp: DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class RecentActivityService {
  static const String _key = 'recent_department';

  Future<void> saveRecentDepartment({
    required String id,
    required String name,
    String? imageUrl,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, [id, name, imageUrl ?? '', DateTime.now().toIso8601String()]);
  }

  Future<RecentActivity?> getRecentDepartment() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_key);
    if (data == null || data.length < 4) return null;

    return RecentActivity(
      id: data[0],
      name: data[1],
      imageUrl: data[2].isEmpty ? null : data[2],
      timestamp: DateTime.parse(data[3]),
    );
  }

  Future<void> clearIfMatches(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_key);
    if (data != null && data.isNotEmpty && data[0] == id) {
      await prefs.remove(_key);
    }
  }
}
