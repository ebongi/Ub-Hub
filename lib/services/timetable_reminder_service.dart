import 'package:go_study/services/notification_service.dart';
import 'package:go_study/services/timetable_catalog.dart';
import 'package:go_study/services/timetable_class.dart';
import 'package:go_study/services/timetable_entry.dart';
import 'package:go_study/services/timetable_repository.dart';

/// Keeps the device's weekly class reminders in step with the user's chosen
/// courses. Reminders are local notifications (work offline, no server job):
/// one weekly-repeating alert per class slot, [leadMinutes] before it starts.
class TimetableReminderService {
  /// Reserved id block for class reminders, so rescheduling never touches
  /// other notifications.
  static const idBase = 800000;
  static const idMax = 899999;
  static const leadMinutes = 15;

  const TimetableReminderService._();

  static (String, String) _text(TimetableClass c) {
    final title = '${c.courseCode} starts in $leadMinutes min';
    final where = c.hall == null ? '' : ' · ${c.hall}';
    final body = '${TimetableEntry.formatTime(c.startMinutes)}'
        '–${TimetableEntry.formatTime(c.endMinutes)}$where';
    return (title, body);
  }

  /// Replaces all class reminders with ones for [slots].
  static Future<void> schedule(List<TimetableClass> slots) async {
    final service = NotificationService();
    await service.cancelNotificationsInRange(idBase, idMax);

    var i = 0;
    for (final c in slots) {
      if (idBase + i > idMax) break;
      // Remind [leadMinutes] early; a slot starting within that window of
      // midnight rolls back to the previous day.
      var weekday = c.dayOfWeek;
      var minutes = c.startMinutes - leadMinutes;
      if (minutes < 0) {
        minutes += 24 * 60;
        weekday = weekday == 1 ? 7 : weekday - 1;
      }
      final (title, body) = _text(c);
      await service.scheduleWeeklyReminder(
        id: idBase + i++,
        title: title,
        body: body,
        weekday: weekday,
        minutesOfDay: minutes,
        payload: 'timetable',
      );
    }
  }

  /// Re-syncs from the server (picks up a reloaded timetable). Best effort:
  /// offline or signed-out leaves the existing reminders as they are.
  static Future<void> syncFromServer({TimetableRepository? repository}) async {
    try {
      final repo = repository ?? TimetableRepository();
      final codes = await repo.fetchSelectedCodes();
      if (codes.isEmpty) {
        await NotificationService()
            .cancelNotificationsInRange(idBase, idMax);
        return;
      }
      final catalog = TimetableCatalog.from(await repo.fetchClasses());
      await schedule(catalog.slotsFor(codes));
    } catch (_) {
      // Keep whatever is already scheduled.
    }
  }
}
