import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:neo/services/database.dart';

class Authentication {
  // Make the FirebaseAuth instance static to ensure it's a singleton.
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Register a new User with Email and password
  Future createUserWithEmailAndPassword({
    String? email,
    String? password,
  }) async {
    try {
      UserCredential? result = email != null && password != null
          ? await _auth.createUserWithEmailAndPassword(
              email: email,
              password: password,
            )
          : null;
      User? user = result!.user;
      await DatabaseService().updateUserData();
      return user;
    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }

  //Stream to monitor change

  static Stream<User?> get getUserStatus {
    return _auth.authStateChanges();
  }

  //SignIn User with email and password

  Future signUserWithEmailAndPassword({String? email, String? password}) async {
    try {
      UserCredential? result = email != null && password != null
          ? await _auth.signInWithEmailAndPassword(
              email: email,
              password: password,
            )
          : null;
      User? user = result!.user;
      return user;
    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }

  //signOut User
  Future signUserOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }
}
