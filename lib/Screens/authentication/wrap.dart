import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:flutter/material.dart';

import 'package:neo/Screens/Shared/constanst.dart';
import 'package:neo/Screens/UI/preview/Navigation/navigationbar.dart';
import 'package:neo/Screens/authentication/authenticate.dart';

import 'package:provider/provider.dart';

import 'package:neo/services/database.dart';
import 'package:neo/services/profile.dart';
import 'dart:async';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  sb.User? _previousUser;
  StreamSubscription<UserProfile>? _profileSubscription;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = Provider.of<sb.User?>(context);

    // Check if the user state has changed from null to a logged-in user
    if (user != _previousUser) {
      if (user != null) {
        // Cancel existing subscription if any
        _profileSubscription?.cancel();

        final userModel = Provider.of<UserModel>(context, listen: false);

        // Listen to real-time profile updates
        _profileSubscription = DatabaseService(uid: user.id).userProfile.listen(
          (profile) {
            userModel.update(
              name: profile.name,
              matricule: profile.matricule,
              phoneNumber: profile.phoneNumber,
              avatarUrl: profile.avatarUrl,
            );
          },
        );

        // Set initial name from metadata as fallback
        if (userModel.name == null || userModel.name!.isEmpty) {
          final name = user.userMetadata?['name'] ?? user.email ?? '';
          userModel.setName(name);
        }
      } else {
        _profileSubscription?.cancel();
        _profileSubscription = null;
      }
      _previousUser = user;
    }
  }

  @override
  void dispose() {
    _profileSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<sb.User?>(context);

    // if the user is not logged in, show the signin screen
    if (user == null) {
      // Show the widget that toggles between Sign In and Register
      return const Authenticate();
    } else {
      // if the user is logged in, show the home screen
      return const NavBar();
    }
  }
}
