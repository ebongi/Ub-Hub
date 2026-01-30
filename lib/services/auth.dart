import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:neo/services/database.dart';

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
        await DatabaseService(uid: user.id).updateUserData(name: name);
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
}
