import 'package:flutter/material.dart';
import 'package:neo/services/auth.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final Authentication _authentication = Authentication();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () async {
            await _authentication.signUserOut();
          },
          child: Text("SignOut"),
        ),
      ),
    );
  }
}
