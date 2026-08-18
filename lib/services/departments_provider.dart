import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'database.dart';
import 'department.dart';

/// Loads the departments list once (not re-subscribed on every rebuild,
/// unlike the old `StreamProvider<List<Department>?>.value(...)` this
/// replaces) and caches the last successful result to disk, so a student
/// opening the app offline sees their last-known department list instead
/// of an infinite spinner.
class DepartmentsProvider with ChangeNotifier {
  static const String _cacheKey = 'cached_departments';

  List<Department>? departments;
  bool isLoading = true;
  bool hasError = false;
  bool isShowingCachedData = false;

  StreamSubscription<List<Department>>? _subscription;
  String? _institutionId;
  bool _hasLoadedOnce = false;

  /// Called from a `ChangeNotifierProxyProvider`'s `update` whenever the
  /// upstream `UserModel` changes. Only actually re-subscribes when
  /// `institutionId` itself changed (e.g. it wasn't loaded yet on the first
  /// call and just became available) — NOT on every unrelated `UserModel`
  /// change, which was the root cause of the old provider re-querying on
  /// every rebuild.
  Future<void> updateInstitutionId(String? institutionId) async {
    if (_hasLoadedOnce && institutionId == _institutionId) return;
    _hasLoadedOnce = true;
    _institutionId = institutionId;

    if (departments == null) {
      final cached = await _readCache();
      if (cached != null && cached.isNotEmpty) {
        departments = cached;
        isShowingCachedData = true;
        isLoading = false;
        notifyListeners();
      }
    }

    await _subscribe();
  }

  Future<void> retry() => _subscribe();

  Future<void> _subscribe() async {
    await _subscription?.cancel();

    if (departments == null) {
      isLoading = true;
      notifyListeners();
    }

    try {
      _subscription = DatabaseService()
          .getDepartments(institutionId: _institutionId)
          .listen(
            (data) {
              departments = data;
              isLoading = false;
              hasError = false;
              isShowingCachedData = false;
              notifyListeners();
              _writeCache(data);
            },
            onError: (_) {
              isLoading = false;
              // Keep showing whatever we already have (cached or
              // previously-fetched) rather than blowing it away on a
              // transient/offline error; only surface a hard error state
              // when there's nothing to show at all.
              hasError = departments == null;
              notifyListeners();
            },
          );
    } catch (_) {
      isLoading = false;
      hasError = departments == null;
      notifyListeners();
    }
  }

  Future<List<Department>?> _readCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null) return null;
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => Department.fromSupabase(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCache(List<Department> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(data.map((d) => d.toSupabase()).toList());
      await prefs.setString(_cacheKey, encoded);
    } catch (_) {
      // Caching is a nice-to-have; ignore failures (e.g. disk full).
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
