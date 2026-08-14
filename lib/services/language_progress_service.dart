import 'package:shared_preferences/shared_preferences.dart';

import 'language_exercise.dart';

class LanguageProgressService {
  String _keyFor(LanguageTrack track) => 'language_progress_${track.jsonValue}';

  Future<Set<String>> getCompleted(LanguageTrack track) async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_keyFor(track)) ?? const []).toSet();
  }

  Future<void> markCompleted(
    LanguageTrack track,
    Iterable<String> exerciseIds,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final current = (prefs.getStringList(_keyFor(track)) ?? const []).toSet();
    current.addAll(exerciseIds);
    await prefs.setStringList(_keyFor(track), current.toList());
  }
}
