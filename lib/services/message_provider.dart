import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:neo/services/notification_service.dart';

class MessageProvider with ChangeNotifier {
  int _unreadCount = 0;
  bool _isChatOpen = false;
  RealtimeChannel? _channel;

  int get unreadCount => _unreadCount;
  bool get isChatOpen => _isChatOpen;

  MessageProvider() {
    _initRealtimeListener();
  }

  void _initRealtimeListener() {
    final supabase = Supabase.instance.client;

    _channel = supabase
        .channel('public:messages')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          callback: (payload) {
            if (!_isChatOpen) {
              final newUserId = payload.newRecord['user_id'];
              final currentUserId = supabase.auth.currentUser?.id;

              // Only increment if the message is from someone else
              if (newUserId != currentUserId) {
                _unreadCount++;

                // Trigger immediate notification alert
                final senderName =
                    payload.newRecord['sender_name'] ?? 'Someone';
                final content = payload.newRecord['content'] ?? 'New message';

                NotificationService().showAlert(
                  id: payload.newRecord['id'].hashCode,
                  title: senderName,
                  body: content,
                );

                notifyListeners();
              }
            }
          },
        )
        .subscribe();
  }

  void setChatOpen(bool isOpen) {
    _isChatOpen = isOpen;
    if (isOpen) {
      _unreadCount = 0;
      notifyListeners();
    }
  }

  void resetUnreadCount() {
    _unreadCount = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}
