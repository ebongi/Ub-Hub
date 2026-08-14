import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'language_exercise.dart';

class LanguageExerciseService {
  static const String _assetPath = 'assets/data/language_courses.json';
  static List<LanguageExercise>? _cache;

  Future<List<LanguageExercise>> loadAll() async {
    final cached = _cache;
    if (cached != null) return cached;

    final raw = await rootBundle.loadString(_assetPath);
    final decoded = json.decode(raw) as List<dynamic>;
    final exercises = decoded
        .map((e) => LanguageExercise.fromJson(e as Map<String, dynamic>))
        .toList();
    _cache = exercises;
    return exercises;
  }

  Future<List<LanguageExercise>> forTrackAndLevel(
    LanguageTrack track,
    String level,
  ) async {
    final all = await loadAll();
    return all.where((e) => e.track == track && e.level == level).toList();
  }

  Future<Map<String, List<LanguageExercise>>> byLevelForTrack(
    LanguageTrack track,
  ) async {
    final all = await loadAll();
    return {
      for (final level in LanguageExercise.levels)
        level: all.where((e) => e.track == track && e.level == level).toList(),
    };
  }
}
