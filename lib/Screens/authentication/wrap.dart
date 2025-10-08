import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
 
import 'package:neo/Screens/Shared/constanst.dart';
import 'package:neo/Screens/UI/preview/Navigation/navigationbar.dart';
import 'package:neo/Screens/authentication/authenticate.dart';
 
import 'package:provider/provider.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  User? _previousUser;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = Provider.of<User?>(context);

    // Check if the user state has changed from null to a logged-in user
    if (user != _previousUser) {
      if (user != null) {
        // User has just logged in or was already logged in on app start.
        // Update the UserModel with the user's display name.
        final userModel = Provider.of<UserModel>(context, listen: false);
        userModel.setName(user.displayName ?? '');
      }
      _previousUser = user;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);

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
