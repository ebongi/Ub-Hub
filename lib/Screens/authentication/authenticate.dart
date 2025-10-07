import 'package:flutter/material.dart';
import 'package:neo/Screens/authentication/register.dart';
import 'package:neo/Screens/authentication/signin.dart';

class Authenticate extends StatefulWidget {
  const Authenticate({super.key});

  @override
  State<Authenticate> createState() => _AuthenticateState();
}

class _AuthenticateState extends State<Authenticate> {
  bool istoggle = false;
  void changeAuthView() {
    setState(() {
      istoggle = !istoggle;
    });
  }

  @override
  Widget build(BuildContext context) {
    return  istoggle ? Signin(istoggle:changeAuthView) : Register(istoggle: changeAuthView ,);
  }
}
