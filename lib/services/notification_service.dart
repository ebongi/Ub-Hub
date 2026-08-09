import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_study/services/notification_model.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:go_study/main.dart';
import 'package:go_study/Screens/UI/preview/Navigation/navigationbar.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // We need to initialize local notifications in the background isolate
  final FlutterLocalNotificationsPlugin localNotifications =
      FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: DarwinInitializationSettings(),
  );

  await localNotifications.initialize(initializationSettings);

  if (message.notification != null) {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'go_study_background',
          'GO Study Background',
          importance: Importance.max,
          priority: Priority.high,
        );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await localNotifications.show(
      message.hashCode,
      message.notification!.title,
      message.notification!.body,
      platformDetails,
    );
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final _supabase = Supabase.instance.client;
  final _fcm = FirebaseMessaging.instance;
  RealtimeChannel? _notificationChannel;

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
        _handleNotificationTap(details.payload);
      },
    );

    // Listen for Auth changes to start/stop the real-time listener
    _supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.signedIn || event == AuthChangeEvent.tokenRefreshed) {
        refresh(); // Start listening when user is available
      } else if (event == AuthChangeEvent.signedOut) {
        clear(); // Stop listening when user signs out
      }
    });

    // Initialize FCM
    await _initFCM();

    // Start listening for real-time notifications (foreground)
    if (_uid != null) {
      refresh();
    }

    // Handle when app is opened from a terminated state via notification
    final NotificationAppLaunchDetails? appLaunchDetails =
        await _notificationsPlugin.getNotificationAppLaunchDetails();
    if (appLaunchDetails?.didNotificationLaunchApp ?? false) {
      _handleNotificationTap(appLaunchDetails?.notificationResponse?.payload);
    }
  }

  void _handleNotificationTap(String? payload) {
    if (payload == null) return;

    // For friend requests or messages, navigate to the Messages tab (index 3)
    if (payload == 'friendRequest' || payload == 'message') {
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const NavBar(initialIndex: 3)),
        (route) => false,
      );
    } else {
      // Default navigation to Home
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const NavBar(initialIndex: 0)),
        (route) => false,
      );
    }
  }

  Future<void> _initFCM() async {
    // Request permissions for iOS
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Get token and save it
      String? token = await _fcm.getToken();
      if (token != null) {
        await _saveTokenToSupabase(token);
      }
    }

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        showAlert(
          id: message.hashCode,
          title: message.notification!.title ?? 'New Notification',
          body: message.notification!.body ?? '',
        );
      }
    });

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  Future<void> _saveTokenToSupabase(String token) async {
    if (_uid == null) return;
    try {
      await _supabase
          .from('profiles')
          .update({'fcm_token': token})
          .eq('id', _uid!);
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }

  void refresh() {
    _listenForNotifications();
    _updateFCMToken();
  }

  Future<void> _updateFCMToken() async {
    if (_uid == null) return;
    String? token = await _fcm.getToken();
    if (token != null) {
      await _saveTokenToSupabase(token);
    }
  }

  void clear() {
    _notificationChannel?.unsubscribe();
    _notificationChannel = null;
  }

  void _listenForNotifications() {
    if (_uid == null) return;

    // Cleanup existing channel if any
    _notificationChannel?.unsubscribe();

    _notificationChannel = _supabase
        .channel('public:notifications:user_id=eq.$_uid')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: _uid,
          ),
          callback: (payload) {
            final data = payload.newRecord;
            final title = data['title'] as String;
            final body = data['body'] as String;
            final type = data['type'] as String?;

            showAlert(
              id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
              title: title,
              body: body,
              payload: type,
            );
          },
        )
        .subscribe();
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

  /// Schedule study reminders for the next 7 days at 7:00 PM
  Future<void> scheduleStudyReminders() async {
    // Unique ID range for study reminders: 1000-1007
    final now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      var scheduledDate = DateTime(
        now.year,
        now.month,
        now.day,
        19,
        0,
      ).add(Duration(days: i));

      if (scheduledDate.isBefore(now)) {
        // If 7 PM today has passed, schedule for 7 PM tomorrow
        if (i == 0) continue;
      }

      await scheduleNotification(
        id: 1000 + i,
        title: "Study Time! 📚",
        body: "Consistency is key to success. Ready for a quick session?",
        scheduledDate: scheduledDate,
      );
    }
  }

  /// Cancel all scheduled study reminders
  Future<void> cancelStudyReminders() async {
    for (int i = 0; i < 7; i++) {
      await cancelNotification(1000 + i);
    }
  }

  // --- Supabase Persistence ---

  /// Get notifications stream for the current user
  Stream<List<NotificationModel>> get notifications {
    return _supabase.auth.onAuthStateChange.asyncMap((data) async {
      final user = data.session?.user ?? _supabase.auth.currentUser;
      if (user == null) return <NotificationModel>[];
      
      // We return the stream from Supabase for this specific user
      return _supabase
          .from('notifications')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);
    }).asyncExpand((listFuture) async* {
      // Since stream() doesn't easily compose with asyncMap, we use a different approach
      // or we just re-trigger the stream whenever auth changes.
      if (_uid == null) {
        yield [];
        return;
      }
      
      yield* _supabase
          .from('notifications')
          .stream(primaryKey: ['id'])
          .eq('user_id', _uid!)
          .order('created_at', ascending: false)
          .map((data) => data.map((json) => NotificationModel.fromSupabase(json)).toList());
    });
  }

  /// Get stream of unread notification count
  Stream<int> get unreadCountStream {
    return notifications.map((list) => list.where((n) => !n.isRead).length);
  }

  /// Create and save a new notification
  Future<void> createNotification({
    required String title,
    required String body,
    required NotificationType type,
    String? recipientId,
    Map<String, dynamic>? data,
    bool showLocal = true,
    bool notifySelf = false,
  }) async {
    final targetUserId = recipientId;

    // If no recipient and not notifying self, do nothing
    if (targetUserId == null && !notifySelf) return;

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
    // 2. We are notifying the current user (finalUserId == _uid)
    // This prevents the sender from getting a local alert for a message they just sent.
    if (showLocal && finalUserId == _uid) {
      await showAlert(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title: title,
        body: body,
        payload: type.name,
      );
    }
  }

  /// Create the same notification for multiple recipients at once (e.g.
  /// broadcasting new content to everyone in a department/institution).
  /// Each recipient's own realtime channel (see [_listenForNotifications])
  /// picks up their row and shows a local alert if their app is open, same
  /// as a 1:1 notification created via [createNotification] — this just
  /// fans the insert out to many users in a single bulk insert instead of
  /// one row.
  Future<void> createBroadcastNotification({
    required List<String> recipientIds,
    required String title,
    required String body,
    required NotificationType type,
    Map<String, dynamic>? data,
    String? excludeUserId,
  }) async {
    final targets = excludeUserId == null
        ? recipientIds
        : recipientIds.where((id) => id != excludeUserId).toList();
    if (targets.isEmpty) return;

    final rows = targets
        .map(
          (userId) => NotificationModel(
            id: '',
            userId: userId,
            title: title,
            body: body,
            type: type,
            createdAt: DateTime.now(),
            data: data,
          ).toSupabase(),
        )
        .toList();

    await _supabase.from('notifications').insert(rows);
  }

  /// Clear all notifications for the current user
  Future<void> clearAll() async {
    if (_uid == null) return;
    await _supabase.from('notifications').delete().eq('user_id', _uid!);
    await _notificationsPlugin.cancelAll();
  }

  /// Mark a notification as read
  Future<void> markAsRead(String id) async {
    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('id', id);
  }

  /// Mark all notifications as read for the current user
  Future<void> markAllAsRead() async {
    if (_uid == null) return;
    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', _uid!)
        .eq('is_read', false);
  }
}
