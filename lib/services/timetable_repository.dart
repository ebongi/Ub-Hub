import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:go_study/services/timetable_class.dart';

/// Supabase access for the published timetable and the signed-in user's
/// chosen courses (`timetable_classes`, `user_timetable_courses`).
class TimetableRepository {
  final SupabaseClient? _client;

  TimetableRepository({SupabaseClient? client}) : _client = client;

  // Resolved lazily so subclasses/fakes (tests) never touch Supabase.
  SupabaseClient get _supabase => _client ?? Supabase.instance.client;

  String? get _uid => _supabase.auth.currentUser?.id;

  Future<List<TimetableClass>> fetchClasses() async {
    final rows = await _supabase.from('timetable_classes').select();
    return (rows as List)
        .map((r) => TimetableClass.fromSupabase(r as Map<String, dynamic>))
        .toList();
  }

  Future<Set<String>> fetchSelectedCodes() async {
    final uid = _uid;
    if (uid == null) return {};
    final rows = await _supabase
        .from('user_timetable_courses')
        .select('course_code')
        .eq('user_id', uid);
    return (rows as List).map((r) => r['course_code'] as String).toSet();
  }

  Future<void> setSelected(String courseCode, bool selected) async {
    final uid = _uid;
    if (uid == null) return;
    if (selected) {
      await _supabase.from('user_timetable_courses').upsert({
        'user_id': uid,
        'course_code': courseCode,
      });
    } else {
      await _supabase
          .from('user_timetable_courses')
          .delete()
          .eq('user_id', uid)
          .eq('course_code', courseCode);
    }
  }
}
