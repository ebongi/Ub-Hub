import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_study/services/notification_service.dart';

class MessageProvider with ChangeNotifier {
  int _unreadCount = 0;
  bool _isChatOpen = false;
  RealtimeChannel? _channel;

  int get unreadCount => _unreadCount;
  bool get isChatOpen => _isChatOpen;

  MessageProvider() {
    final supabase = Supabase.instance.client;
    
    // Handle auth changes seamlessly
    supabase.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn || event == AuthChangeEvent.tokenRefreshed) {
        _initRealtimeListener();
      } else if (event == AuthChangeEvent.signedOut) {
        _channel?.unsubscribe();
        _channel = null;
        _unreadCount = 0;
        notifyListeners();
      }
    });

    // Initial check if user is already logged in
    if (supabase.auth.currentUser != null) {
      _initRealtimeListener();
    }
  }

  void _initRealtimeListener() {
    final supabase = Supabase.instance.client;
    
    // Cleanup any existing subscription
    _channel?.unsubscribe();

    _channel = supabase
        .channel('public:messages')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
      callback: (payload) {
        final currentUserId = supabase.auth.currentUser?.id;
        final senderId = payload.newRecord['sender_id'];

        // 1. NEVER notify or increment for self-sent messages
        // If currentUserId is null, we safely assume it might be a self-message 
        // that hasn't synced auth yet, or just skip to be safe.
        if (senderId == null || currentUserId == null || senderId == currentUserId) return;

        // 2. Only proceed if the chat UI is not active
        if (!_isChatOpen) {
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
