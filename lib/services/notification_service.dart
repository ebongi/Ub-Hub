import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_study/services/notification_model.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final _supabase = Supabase.instance.client;

  String? get _uid => _supabase.auth.currentUser?.id;

  Future<void> init() async {
    // Initialize timezones
    tz.initializeTimeZones();
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings(
          '@mipmap/ic_launcher',
        ); // Standard launcher icon

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap
      },
    );
  }

  Future<void> showAlert({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'go_study_alerts',
          'GO Study Alerts',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          playSound: true,
          enableVibration: true,
        );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _notificationsPlugin.show(
      id,
      title,
      body,
      platformDetails,
      payload: payload,
    );
  }

  Future<void> showChatNotification({
    required String senderName,
    required String message,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'go_study_chat',
          'GO Study Chat',
          channelDescription: 'Real-time chat notifications',
          importance: Importance.max,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(''),
        );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        categoryIdentifier: 'chat',
      ),
    );

    await _notificationsPlugin.show(
      999, // Static ID for chat to avoid spamming the tray
      "New message from $senderName",
      message,
      platformDetails,
      payload: payload,
    );
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    if (scheduledDate.isBefore(DateTime.now())) return;

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'go_study_reminders',
          'GO Study Reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  // --- Supabase Persistence ---

  /// Get notifications stream for the current user
  Stream<List<NotificationModel>> get notifications {
    if (_uid == null) return Stream.value([]);
    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', _uid!)
        .order('created_at', ascending: false)
        .map(
          (data) =>
              data.map((json) => NotificationModel.fromSupabase(json)).toList(),
        );
  }

  /// Create and save a new notification
  Future<void> createNotification({
    required String title,
    required String body,
    required NotificationType type,
    String? recipientId,
    Map<String, dynamic>? data,
    bool showLocal = true,
    bool notifySelf = false, // New parameter to control self-notifications
  }) async {
    final targetUserId = recipientId;
    if (targetUserId == null && !notifySelf) return; // Don't notify self by default

    final finalUserId = targetUserId ?? _uid;
    if (finalUserId == null) return;

    final notification = NotificationModel(
      id: '', // Generated by Supabase
      userId: finalUserId,
      title: title,
      body: body,
      type: type,
      createdAt: DateTime.now(),
      data: data,
    );

    await _supabase.from('notifications').insert(notification.toSupabase());

    // Only show local alert if:
    // 1. showLocal is true AND
    // 2. We are notifying someone else (recipientId != null) OR we explicitly want to notify self
    if (showLocal && (recipientId != null || notifySelf)) {
      await showAlert(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title: title,
        body: body,
      );
    }
  }

  /// Clear all notifications for the current user
  Future<void> clearAll() async {
    if (_uid == null) return;
    await _supabase.from('notifications').delete().eq('user_id', _uid!);
  }

  /// Mark a notification as read
  Future<void> markAsRead(String id) async {
    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('id', id);
  }
}
