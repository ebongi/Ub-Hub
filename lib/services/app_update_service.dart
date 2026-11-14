import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform, debugPrint;
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';

/// Checks Google Play for a newer app version and applies it via the
/// Play Core In-App Updates API. Android-only — `in_app_update` throws on
/// other platforms.
class AppUpdateService {
  AppUpdateService._();

  // Play Console lets a release be tagged with an update priority (0-5).
  // At or above this threshold we block with an immediate (full-screen)
  // update instead of downloading flexibly in the background.
  static const int _immediatePriorityThreshold = 4;

  static Future<void> checkForUpdate(GlobalKey<NavigatorState> navigatorKey) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;

    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability != UpdateAvailability.updateAvailable) {
        return;
      }

      if (info.immediateUpdateAllowed &&
          info.updatePriority >= _immediatePriorityThreshold) {
        await InAppUpdate.performImmediateUpdate();
        return;
      }

      if (info.flexibleUpdateAllowed) {
        await InAppUpdate.startFlexibleUpdate();
        _promptToRestart(navigatorKey);
      }
    } catch (e) {
      debugPrint('In-app update check failed: $e');
    }
  }

  static void _promptToRestart(GlobalKey<NavigatorState> navigatorKey) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(days: 1),
        content: const Text('An update has been downloaded.'),
        action: SnackBarAction(
          label: 'RESTART',
          onPressed: () => InAppUpdate.completeFlexibleUpdate(),
        ),
      ),
    );
  }
}
