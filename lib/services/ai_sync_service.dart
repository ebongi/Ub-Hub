import 'package:supabase_flutter/supabase_flutter.dart';
import '../Screens/UI/preview/Chatbot/chatbot_screen.dart';

class AISyncService {
  final _supabase = Supabase.instance.client;

  String? get _uid => _supabase.auth.currentUser?.id;

  // --- Sessions ---

  Future<List<ChatSession>> loadSessions() async {
    if (_uid == null) return [];

    final response = await _supabase
        .from('ai_sessions')
        .select('*, ai_messages(*)')
        .eq('user_id', _uid!)
        .order('created_at', ascending: false);

    return (response as List).map((sessionData) {
      final messages = (sessionData['ai_messages'] as List)
          .map((msgData) => ChatMessage.fromJson(msgData))
          .toList();
      // Sort messages by creation time
      messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return ChatSession.fromJson(sessionData, messages);
    }).toList();
  }

  Future<void> saveSession(ChatSession session) async {
    if (_uid == null) return;
    await _supabase.from('ai_sessions').upsert(session.toJson(_uid!));
  }

  Future<void> deleteSession(String sessionId) async {
    if (_uid == null) return;
    await _supabase.from('ai_sessions').delete().eq('id', sessionId);
  }

  Future<void> clearAllSessions() async {
    if (_uid == null) return;
    await _supabase.from('ai_sessions').delete().eq('user_id', _uid!);
  }

  // --- Messages ---

  Future<void> saveMessage(String sessionId, ChatMessage message) async {
    if (_uid == null) return;
    await _supabase
        .from('ai_messages')
        .upsert(message.toJson(sessionId, _uid!));
  }
}
