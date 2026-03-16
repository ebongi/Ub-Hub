import 'package:supabase_flutter/supabase_flutter.dart';

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
    await _supabase.from('friend_requests').insert({
      'sender_id': _myId,
      'receiver_id': receiverId,
      'status': 'pending',
    });
  }

  // ---------------------------------------------------------------------------
  // Respond to an incoming friend request
  // ---------------------------------------------------------------------------
  Future<void> respondToRequest(String requestId, bool accept) async {
    await _supabase
        .from('friend_requests')
        .update({'status': accept ? 'accepted' : 'declined'}).eq(
            'id', requestId);
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
        .or('and(sender_id.eq.$_myId,receiver_id.eq.$otherUserId),and(sender_id.eq.$otherUserId,receiver_id.eq.$_myId)');
  }

  // ---------------------------------------------------------------------------
  // Stream of accepted friends (both directions)
  // ---------------------------------------------------------------------------
  Stream<List<FriendProfile>> getFriendsStream() {
    // Fetch accepted requests where current user is sender or receiver
    return _supabase
        .from('friend_requests')
        .stream(primaryKey: ['id'])
        .eq('status', 'accepted')
        .asyncMap((rows) async {
          final myFriendRows = rows.where((r) =>
              r['sender_id'] == _myId || r['receiver_id'] == _myId).toList();

          if (myFriendRows.isEmpty) return <FriendProfile>[];

          final friendIds = myFriendRows
              .map((r) =>
                  r['sender_id'] == _myId ? r['receiver_id'] : r['sender_id'])
              .toSet()
              .toList();

          final profiles = await _supabase
              .from('profiles')
              .select('id, name, avatar_url')
              .filter('id', 'in', '(${friendIds.join(',')})');

          final friendProfiles = profiles.map((p) => FriendProfile.fromJson(p)).toList();

          // Fetch last message for each friend
          final List<FriendProfile> enrichedProfiles = [];
          for (var friend in friendProfiles) {
            final roomId = dmRoomId(_myId, friend.id);
            final lastMsgRow = await _supabase
                .from('messages')
                .select('content, created_at')
                .eq('room_id', roomId)
                .order('created_at', ascending: false)
                .limit(1)
                .maybeSingle();

            enrichedProfiles.add(FriendProfile(
              id: friend.id,
              name: friend.name,
              avatarUrl: friend.avatarUrl,
              lastMessage: lastMsgRow?['content'] as String?,
              lastMessageTime: lastMsgRow != null
                  ? DateTime.parse(lastMsgRow['created_at'] as String)
                  : null,
            ));
          }

          return enrichedProfiles;
        });
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
          final pendingRows = rows.where((r) => r['status'] == 'pending').toList();
          if (pendingRows.isEmpty) return <FriendRequest>[];

          final senderIds = pendingRows.map((r) => r['sender_id'] as String).toList();

          final profiles = await _supabase
              .from('profiles')
              .select('id, name, avatar_url')
              .filter('id', 'in', '(${senderIds.join(',')})');

          final profileMap = {
            for (final p in profiles)
              p['id'] as String: p,
          };

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

    return results
        .map((p) => FriendProfile.fromJson(p))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Get the status of the relationship with a specific user
  // Returns: 'none' | 'pending_sent' | 'pending_received' | 'accepted'
  // ---------------------------------------------------------------------------
  Future<String> getRelationshipStatus(String otherUserId) async {
    final rows = await _supabase
        .from('friend_requests')
        .select('id, sender_id, status')
        .or('and(sender_id.eq.$_myId,receiver_id.eq.$otherUserId),and(sender_id.eq.$otherUserId,receiver_id.eq.$_myId)')
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
}
