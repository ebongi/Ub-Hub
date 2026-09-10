import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_study/services/notification_service.dart';
import 'package:go_study/services/notification_model.dart';

/// A single friend's profile data
class FriendProfile {
  final String id;
  final String? name;
  final String? avatarUrl;
  final String? requestId; // the friend_request row id, if relevant

  final String? lastMessage;
  final DateTime? lastMessageTime;

  FriendProfile({
    required this.id,
    this.name,
    this.avatarUrl,
    this.requestId,
    this.lastMessage,
    this.lastMessageTime,
  });

  factory FriendProfile.fromJson(Map<String, dynamic> json) {
    return FriendProfile(
      id: json['id'] as String,
      name: json['name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}

/// An incoming (pending) friend request
class FriendRequest {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderAvatarUrl;
  final DateTime createdAt;

  FriendRequest({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderAvatarUrl,
    required this.createdAt,
  });
}

class FriendsService {
  final SupabaseClient _supabase;

  FriendsService({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  String get _myId => _supabase.auth.currentUser!.id;

  // ---------------------------------------------------------------------------
  // Deterministic DM room ID shared by both users
  // ---------------------------------------------------------------------------
  static String dmRoomId(String uidA, String uidB) {
    final sorted = [uidA, uidB]..sort();
    return 'dm_${sorted[0]}_${sorted[1]}';
  }

  // ---------------------------------------------------------------------------
  // Send a friend request
  // ---------------------------------------------------------------------------
  Future<void> sendFriendRequest(String receiverId) async {
    // 1. Fetch my profile to get my name
    final myProfile = await _supabase
        .from('profiles')
        .select('name')
        .eq('id', _myId)
        .maybeSingle();

    final myName = myProfile?['name'] ?? 'Someone';

    // 2. Insert the request
    await _supabase.from('friend_requests').insert({
      'sender_id': _myId,
      'receiver_id': receiverId,
      'status': 'pending',
    });

    // 3. Trigger notification
    await NotificationService().createNotification(
      title: 'New Friend Request',
      body: '$myName sent you a friend request.',
      type: NotificationType.friendRequest,
      recipientId: receiverId,
      data: {'senderId': _myId},
    );
  }

  // ---------------------------------------------------------------------------
  // Respond to an incoming friend request
  // ---------------------------------------------------------------------------
  Future<void> respondToRequest(String requestId, bool accept) async {
    // 1. Fetch request details to get sender_id and receiver (me) name
    final request = await _supabase
        .from('friend_requests')
        .select('sender_id, receiver_id')
        .eq('id', requestId)
        .single();

    final senderId = request['sender_id'] as String;

    // 2. Fetch my profile to get my name
    final myProfile = await _supabase
        .from('profiles')
        .select('name')
        .eq('id', _myId)
        .maybeSingle();

    final myName = myProfile?['name'] ?? 'Someone';

    // 3. Update the request status
    await _supabase
        .from('friend_requests')
        .update({'status': accept ? 'accepted' : 'declined'})
        .eq('id', requestId);

    // 4. Trigger notification to the original sender
    if (accept) {
      await NotificationService().createNotification(
        title: 'Friend Request Accepted',
        body: '$myName accepted your friend request.',
        type: NotificationType.friendRequest,
        recipientId: senderId,
        data: {'receiverId': _myId},
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Remove a friend (delete the accepted request row)
  // ---------------------------------------------------------------------------
  Future<void> removeFriend(String otherUserId) async {
    // Delete whichever direction the accepted row exists
    await _supabase
        .from('friend_requests')
        .delete()
        .eq('status', 'accepted')
        .or(
          'and(sender_id.eq.$_myId,receiver_id.eq.$otherUserId),and(sender_id.eq.$otherUserId,receiver_id.eq.$_myId)',
        );
  }

  // ---------------------------------------------------------------------------
  // Stream of accepted friends (both directions), with each friend's last
  // DM message. Rebuilds whenever the friend_requests table changes (a new
  // friend accepted/removed) OR a relevant DM message is inserted — the
  // latter is needed because a new message never touches friend_requests,
  // so without it the conversation list's preview/ordering would only ever
  // refresh incidentally, not in response to the message that caused it.
  // ---------------------------------------------------------------------------
  Stream<List<FriendProfile>> getFriendsStream() {
    final controller = StreamController<List<FriendProfile>>.broadcast();

    List<Map<String, dynamic>> latestAcceptedRows = [];
    var hasRequestsSnapshot = false;
    var rebuildSequence = 0;

    Future<void> rebuild() async {
      final sequence = ++rebuildSequence;

      final myFriendRows = latestAcceptedRows
          .where((r) => r['sender_id'] == _myId || r['receiver_id'] == _myId)
          .toList();

      if (myFriendRows.isEmpty) {
        if (sequence == rebuildSequence) controller.add(<FriendProfile>[]);
        return;
      }

      final friendIds = myFriendRows
          .map(
            (r) => r['sender_id'] == _myId ? r['receiver_id'] : r['sender_id'],
          )
          .toSet()
          .toList();

      final profiles = await _supabase
          .from('profiles')
          .select('id, name, avatar_url')
          .filter('id', 'in', '(${friendIds.join(',')})');

      final friendProfiles =
          profiles.map((p) => FriendProfile.fromJson(p)).toList();

      // Fetch each friend's last message in parallel instead of one at a
      // time — this ran serially before, so render time grew linearly with
      // friend count on every single emission.
      final lastMessages = await Future.wait(
        friendProfiles.map((friend) {
          final roomId = dmRoomId(_myId, friend.id);
          return _supabase
              .from('messages')
              .select('content, created_at')
              .eq('room_id', roomId)
              .order('created_at', ascending: false)
              .limit(1)
              .maybeSingle();
        }),
      );

      // A slower, now-stale rebuild finishing after a newer one must not
      // clobber it with older data.
      if (sequence != rebuildSequence) return;

      final enrichedProfiles = [
        for (var i = 0; i < friendProfiles.length; i++)
          FriendProfile(
            id: friendProfiles[i].id,
            name: friendProfiles[i].name,
            avatarUrl: friendProfiles[i].avatarUrl,
            lastMessage: lastMessages[i]?['content'] as String?,
            lastMessageTime: lastMessages[i] != null
                ? DateTime.parse(lastMessages[i]!['created_at'] as String)
                : null,
          ),
      ];

      controller.add(enrichedProfiles);
    }

    final requestsSubscription = _supabase
        .from('friend_requests')
        .stream(primaryKey: ['id'])
        .eq('status', 'accepted')
        .listen((rows) {
          latestAcceptedRows = rows;
          hasRequestsSnapshot = true;
          rebuild();
        });

    final messagesChannel = _supabase
        .channel('friends_last_message_$_myId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          callback: (payload) {
            if (!hasRequestsSnapshot) return;
            final roomId = payload.newRecord['room_id'] as String? ?? '';
            final isRelevantDm = roomId.startsWith('dm_') &&
                roomId.split('_').skip(1).contains(_myId);
            if (isRelevantDm) rebuild();
          },
        )
        .subscribe();

    controller.onCancel = () async {
      await requestsSubscription.cancel();
      await messagesChannel.unsubscribe();
    };

    return controller.stream;
  }

  // ---------------------------------------------------------------------------
  // Stream of pending incoming requests
  // ---------------------------------------------------------------------------
  Stream<List<FriendRequest>> getPendingRequestsStream() {
    return _supabase
        .from('friend_requests')
        .stream(primaryKey: ['id'])
        .eq('receiver_id', _myId)
        .asyncMap((rows) async {
          // Filter by status manually as SupabaseStreamBuilder might not support multiple eq filters
          final pendingRows = rows
              .where((r) => r['status'] == 'pending')
              .toList();
          if (pendingRows.isEmpty) return <FriendRequest>[];

          final senderIds = pendingRows
              .map((r) => r['sender_id'] as String)
              .toList();

          final profiles = await _supabase
              .from('profiles')
              .select('id, name, avatar_url')
              .filter('id', 'in', '(${senderIds.join(',')})');

          final profileMap = {for (final p in profiles) p['id'] as String: p};

          return pendingRows.map((r) {
            final profile = profileMap[r['sender_id']] ?? {};
            return FriendRequest(
              id: r['id'] as String,
              senderId: r['sender_id'] as String,
              senderName: (profile['name'] as String?) ?? 'Unknown',
              senderAvatarUrl: profile['avatar_url'] as String?,
              createdAt: DateTime.parse(r['created_at'] as String),
            );
          }).toList();
        });
  }

  // ---------------------------------------------------------------------------
  // Search users by name (excludes self)
  // ---------------------------------------------------------------------------
  Future<List<FriendProfile>> searchUsers(String query) async {
    if (query.trim().isEmpty) return [];

    final results = await _supabase
        .from('profiles')
        .select('id, name, avatar_url')
        .ilike('name', '%$query%')
        .neq('id', _myId)
        .limit(30);

    return results.map((p) => FriendProfile.fromJson(p)).toList();
  }

  // ---------------------------------------------------------------------------
  // Get the status of the relationship with a specific user
  // Returns: 'none' | 'pending_sent' | 'pending_received' | 'accepted'
  // ---------------------------------------------------------------------------
  Future<String> getRelationshipStatus(String otherUserId) async {
    final rows = await _supabase
        .from('friend_requests')
        .select('id, sender_id, status')
        .or(
          'and(sender_id.eq.$_myId,receiver_id.eq.$otherUserId),and(sender_id.eq.$otherUserId,receiver_id.eq.$_myId)',
        )
        .limit(1);

    if ((rows as List).isEmpty) return 'none';
    final row = rows.first;
    final status = row['status'] as String;
    if (status == 'accepted') return 'accepted';
    if (status == 'pending') {
      return row['sender_id'] == _myId ? 'pending_sent' : 'pending_received';
    }
    return 'none';
  }

  // ---------------------------------------------------------------------------
  // Stream of ALL friend requests involving the current user (any status)
  // ---------------------------------------------------------------------------
  Stream<List<Map<String, dynamic>>> getAllRequestsStream() {
    return _supabase
        .from('friend_requests')
        .stream(primaryKey: ['id']);
  }
}
