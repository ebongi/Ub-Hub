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
import 'package:go_study/Screens/UI/preview/Toolbox/news_feed_screen.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Runs in a separate isolate when a push arrives while the app is
  // backgrounded or terminated. The Edge Function sends data-only messages
  // (no `notification` block), so nothing is shown unless we show it here —
  // which is exactly why there is never a duplicate from an OS auto-display.
  final localNotifications = FlutterLocalNotificationsPlugin();

  const initializationSettings = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    iOS: DarwinInitializationSettings(),
  );
  await localNotifications.initialize(initializationSettings);

  final data = message.data;
  final title = data['title'] ?? message.notification?.title;
  final body = data['body'] ?? message.notification?.body ?? '';
  if (title == null) return;

  await localNotifications.show(
    message.hashCode,
    title,
    body,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'go_study_alerts',
        'GoStudy Alerts',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    ),
    payload: data['type'],
  );
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

    // Create the Android channels up-front. A push can arrive before the app
    // has ever shown an in-app notification (fresh install, first run while
    // backgrounded); without an existing channel Android 8+ silently drops it.
    await _createAndroidChannels();

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

    // For friend requests or messages, navigate to the Messages tab (index 2)
    if (payload == 'friendRequest' || payload == 'message') {
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const NavBar(initialIndex: 2)),
        (route) => false,
      );
    } else if (payload == 'news') {
      // Reset to Home, then open the News feed on top.
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const NavBar(initialIndex: 0)),
        (route) => false,
      );
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => const NewsFeedScreen()),
      );
    } else {
      // Default navigation to Home
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const NavBar(initialIndex: 0)),
        (route) => false,
      );
    }
  }

  /// Android notification channels. Kept in sync with the channel IDs used by
  /// [showAlert] ('go_study_alerts'), [showChatNotification] ('go_study_chat'),
  /// [scheduleNotification] ('go_study_reminders') and the FCM background
  /// handler. Pre-creating them means a push has somewhere to land even before
  /// the first in-app notification.
  static const List<AndroidNotificationChannel> _androidChannels = [
    AndroidNotificationChannel(
      'go_study_alerts',
      'GoStudy Alerts',
      description: 'General alerts and push notifications',
      importance: Importance.max,
    ),
    AndroidNotificationChannel(
      'go_study_chat',
      'GoStudy Chat',
      description: 'Real-time chat messages',
      importance: Importance.max,
    ),
    AndroidNotificationChannel(
      'go_study_reminders',
      'GoStudy Reminders',
      description: 'Scheduled study reminders and deadlines',
      importance: Importance.max,
    ),
  ];

  Future<void> _createAndroidChannels() async {
    final android =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;
    for (final channel in _androidChannels) {
      await android.createNotificationChannel(channel);
    }
    // Android 13+: without a granted POST_NOTIFICATIONS nothing is ever shown.
    // firebase_messaging.requestPermission() also prompts, but asking here
    // covers the plain local-notifications path too.
    await android.requestNotificationsPermission();
  }

  Future<void> _initFCM() async {
    // Prompts on iOS, and on Android 13+ (POST_NOTIFICATIONS).
    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    // Save the token regardless of the permission result — it stays valid, and
    // the user may enable notifications later from system settings.
    final token = await _fcm.getToken();
    if (token != null) {
      await _saveTokenToSupabase(token);
    }
    _fcm.onTokenRefresh.listen(_saveTokenToSupabase);

    // Foreground messages. Broadcast types (material/course/department) also
    // arrive as `notifications` table rows, whose realtime subscription
    // (_listenForNotifications) already shows an alert — showing them here too
    // would double up. Chat ('message') has no such row, so show it.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final data = message.data;
      final type = (data['type'] ?? '').toString();
      const shownViaRealtime = {'material', 'course', 'department', 'news'};
      if (shownViaRealtime.contains(type)) return;

      final title = data['title'] ?? message.notification?.title;
      if (title == null) return;
      showAlert(
        id: message.hashCode,
        title: title,
        body: data['body'] ?? message.notification?.body ?? '',
        payload: type.isEmpty ? null : type,
      );
    });

    // Background / terminated messages.
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Taps on a push delivered while backgrounded or terminated.
    FirebaseMessaging.onMessageOpenedApp.listen(
      (message) => _handleNotificationTap(message.data['type']),
    );
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage.data['type']);
    }
  }

  Future<void> _saveTokenToSupabase(String token) async {
    if (_uid == null) return;
    try {
      await _supabase
          .from('profiles')
          .update({'fcm_token': token})
          .eq('id', _uid!);
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
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
          'GoStudy Alerts',
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
          'GoStudy Chat',
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

  /// Whether the OS currently lets us post exact alarms. Exact alarms are gated
  /// behind the SCHEDULE_EXACT_ALARM special access on Android 12+ (auto-granted
  /// through API 32, revocable and denied-by-default on API 33+). Anything other
  /// than Android has no such notion.
  Future<bool> _canScheduleExactAlarms() async {
    final android =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return true;
    return await android.canScheduleExactNotifications() ?? false;
  }

  /// Send the user to the system "Alarms & reminders" screen to grant exact
  /// alarms (Android 13+). Returns the resulting permission state. Scheduling
  /// still works without this — it just falls back to an inexact alarm.
  Future<bool> requestExactAlarmPermission() async {
    final android =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return true;
    return await android.requestExactAlarmsPermission() ?? false;
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    if (scheduledDate.isBefore(DateTime.now())) return;

    // A reminder scheduled minutes/hours ahead does not need alarm-clock
    // precision, so drop to an inexact alarm (needs no permission, delivery is
    // still guaranteed within a maintenance window) rather than letting the
    // plugin throw PlatformException(exact alarms not permitted).
    final scheduleMode = await _canScheduleExactAlarms()
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'go_study_reminders',
          'GoStudy Reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: scheduleMode,
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

  // ---------------------------------------------------------------------------
  // FCM push via Supabase Edge Function
  // ---------------------------------------------------------------------------

  /// Trigger a Firebase Cloud Messaging push for background / terminated devices.
  ///
  /// The Edge Function resolves (and authorizes) the actual recipient list
  /// itself from [scope]/[scopeId] — the caller's own verified JWT identity,
  /// never a client-supplied id list, decides who the request is allowed to
  /// reach. Valid scopes: 'room' (scopeId = room id; 'global' or a
  /// department id), 'dm' (scopeId = the `dm_<uid>_<uid>` room id), 'department'
  /// (scopeId = department id — caller must belong to it), 'institution'
  /// (scopeId = institution id — admin only), 'all' (admin only).
  ///
  /// [insertNotification] tells the Edge Function whether to also write rows to
  /// the `notifications` table (set false when [createBroadcastNotification] has
  /// already done that).
  ///
  /// All errors are caught and logged — a push failure must never break the
  /// action that triggered it.
  Future<void> triggerPushViaEdgeFunction({
    required String title,
    required String body,
    required NotificationType type,
    required String scope,
    String? scopeId,
    Map<String, dynamic>? data,
    bool insertNotification = false,
  }) async {
    try {
      await _supabase.functions.invoke(
        'send-push-notification',
        body: {
          'scope': scope,
          if (scopeId != null) 'scope_id': scopeId,
          'title': title,
          'body': body,
          'type': type.name,
          if (data != null && data.isNotEmpty) 'data': data,
          'insert_notification': insertNotification,
        },
      );
    } catch (e) {
      debugPrint('NotificationService.triggerPushViaEdgeFunction error: $e');
    }
  }
}
