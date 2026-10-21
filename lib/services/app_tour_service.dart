import 'package:shared_preferences/shared_preferences.dart';

/// Tracks whether a given user has already seen the first-launch guided
/// tour (see [AppTourKeys]), so it only ever plays once per account per
/// device. Local-only by design, matching the app's other device-scoped
/// flags (e.g. the rating prompt in [Home]).
class AppTourService {
  AppTourService._();

  static const _prefix = 'hasSeenAppTour_';

  static Future<bool> hasSeenTour(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_prefix$uid') ?? false;
  }

  static Future<void> markSeen(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefix$uid', true);
  }

  static Future<void> reset(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix$uid');
  }
}
