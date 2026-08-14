import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:go_study/core/app_config.dart';
import 'package:go_study/services/database.dart';

class Authentication {
  final SupabaseClient _supabase;

  Authentication({SupabaseClient? client})
    : _supabase = client ?? Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;

  // Register a new User with Email and password
  Future createUserWithEmailAndPassword({
    required String email,
    required String password,
    String? name,
    String? matricule,
    String? phoneNumber,
    String? level,
    String? institutionId,
    String? department,
    String? bio,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'name': name ?? ''},
      );

      final user = response.user;
      if (user != null) {
        // Also update profiles table if needed (AuthWrapper handles this but good to have)
        await DatabaseService(uid: user.id).updateUserData(
          name: name,
          matricule: matricule,
          phoneNumber: phoneNumber,
          level: level,
          institutionId: institutionId,
          department: department,
          bio: bio,
        );
      }
      return user;
    } catch (e) {
      debugPrint("SignUp Error: ${e.toString()}");
      rethrow;
    }
  }

  // SignIn User with email and password
  Future signUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response.user;
    } catch (e) {
      debugPrint("SignIn Error: ${e.toString()}");
      rethrow;
    }
  }

  //signOut User
  Future signUserOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      debugPrint("SignOut Error: ${e.toString()}");
      rethrow;
    }
  }

  /// Permanently deletes the current user's account and owned data via the
  /// `delete-account` Edge Function — removing an `auth.users` row requires
  /// the service-role key, which only ever lives server-side, so this can't
  /// be done directly from the client. Signs the user out locally once the
  /// server confirms deletion; [AuthWrapper]'s auth-state listener then
  /// routes back to the sign-in screen on its own.
  Future<void> deleteAccount() async {
    final session = _supabase.auth.currentSession;
    if (session == null) {
      throw Exception('No active session.');
    }

    final response = await http.post(
      Uri.parse('${AppConfig.supabaseUrl}/functions/v1/delete-account'),
      headers: {
        'Content-Type': 'application/json',
        'apikey': AppConfig.supabaseAnonKey,
        'Authorization': 'Bearer ${session.accessToken}',
      },
    );

    if (response.statusCode != 200) {
      String message = response.body;
      try {
        message = (jsonDecode(response.body) as Map)['error'] ?? message;
      } catch (_) {}
      throw Exception('Failed to delete account: $message');
    }

    await _supabase.auth.signOut();
  }
}
