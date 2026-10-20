import 'package:go_study/services/notification_service.dart';

/// Class reminders are Firebase push notifications sent by the
/// `send-class-reminders` Edge Function (supabase/migrations/
/// 20261020120000_schedule_class_reminders.sql) from the user's saved course
/// choices, so the app has nothing to schedule. This only retires the weekly
/// local alarms that earlier versions scheduled, which would otherwise fire
/// alongside the push and double up.
class TimetableReminderService {
  /// Id block the old local class reminders used.
  static const legacyIdBase = 800000;
  static const legacyIdMax = 899999;

  const TimetableReminderService._();

  /// Cancels leftover local class reminders. Best effort and idempotent.
  static Future<void> retireLocalReminders() async {
    try {
      await NotificationService().cancelNotificationsInRange(
        legacyIdBase,
        legacyIdMax,
      );
    } catch (_) {
      // Nothing to cancel, or the plugin isn't ready; try again next launch.
    }
  }
}
