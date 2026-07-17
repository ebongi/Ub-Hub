import 'package:flutter/material.dart';
import 'package:go_study/Screens/authentication/register_flow.dart';

class Register extends StatelessWidget {
  const Register({super.key, required this.istoggle});

  final Function istoggle;

  @override
  Widget build(BuildContext context) {
    return RegisterFlow(istoggle: istoggle);
  }
}
