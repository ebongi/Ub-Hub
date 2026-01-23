import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:introduction_screen/introduction_screen.dart';

// Custom widget for image customization
Widget buildImage({String? path}) {
  return Center(
    child: Image.asset(
      path.toString(),
      width: 400,
      height: 300,
      fit: BoxFit.fitWidth,
    ),
  );
}

// custom Scrolldecoration
PageDecoration pageDecoration() {
  return PageDecoration(
    titleTextStyle: TextStyle(fontSize: 35, color: Colors.black),
    bodyTextStyle: TextStyle(fontSize: 20, color: Colors.grey[600]),
    bodyPadding: EdgeInsets.all(16),
    pageColor: Colors.white,
    imagePadding: EdgeInsets.all(2),
  );
}

class UserModel extends ChangeNotifier {
  final String? _uid;
  String? _name;
  final String? _email;
  String? _matricule;
  String? _phonenumber;

  UserModel({
    String? uid,
    String? name,
    String? email,
    String? matricule,
    String? phonenumber,
  }) : _uid = uid,
       _name = name,
       _email = email,
       _matricule = matricule,
       _phonenumber = phonenumber;
  // Gettters
  String? get uid => _uid;
  String? get name => _name;
  String? get email => _email;
  String? get matricule => _matricule;
  String? get phoneNumber => _phonenumber;
  void setName(String name) {
    _name = name;
    notifyListeners(); //Notify listeners when the code changes
  }

  void update({String? name, String? matricule, String? phoneNumber}) {
    if (name != null) _name = name;
    if (matricule != null) _matricule = matricule;
    if (phoneNumber != null) _phonenumber = phoneNumber;
    notifyListeners();
  }
}

class DepartmentUI extends StatelessWidget {
  const DepartmentUI({
    super.key,
    required this.color,
    required this.imageurl,
    required this.title,
    required this.description,
    required this.hostid,
  });
  final Color color;
  final String imageurl, title, description, hostid;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shadowColor: color.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {}, // Make sure it's interactive if needed, or remove
        borderRadius: BorderRadius.circular(16),
        child: Container(
          // Removing fixed height/width to let GridView handle it, or keeping constraints flexible
          // Original had fixed dimensions which is bad for responsiveness.
          // I'll keep it containerized but responsive.
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            // Gradient or solid color background? Let's use white (from CardTheme)
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 120,
                  width: double.infinity,
                  child: Image.asset(imageurl, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Row(
                children: [
                  Icon(
                    Icons.school,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    hostid,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ... keeping lists as is ...

Future<Map<String, dynamic>> getquestions() async {
  await Future.delayed(Duration(seconds: 2));
  final url = Uri.parse("https://opentdb.com/api.php?amount=50&category=18");
  try {
    final response = await http.get(url);
    if (response.statusCode == 200) {
      // If the server returns a 200 OK response, parse the JSON.
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      print("Error: ${response.body}");
      // If the server did not return a 200 OK response, throw an exception.
      throw Exception('Failed to load questions: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Error fetching questions: $e');
  }
}

class AuthHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const AuthHeader({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: GoogleFonts.outfit(
            fontSize: 16,
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      keyboardType: keyboardType,
      style: GoogleFonts.outfit(fontSize: 16),
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(prefixIcon, size: 20),
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 20,
          horizontal: 16,
        ),
      ),
    );
  }
}

class AuthButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;

  const AuthButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}

// Helper to map department names to UI properties
class DepartmentUIData {
  final IconData icon;
  final Color color;

  DepartmentUIData({required this.icon, required this.color});

  static DepartmentUIData fromDepartmentName(String name) {
    switch (name.toLowerCase()) {
      case 'computer science':
        return DepartmentUIData(
          icon: Icons.computer_rounded,
          color: Colors.blue.shade800,
        );
      case 'mathematics':
        return DepartmentUIData(
          icon: Icons.functions_rounded,
          color: Colors.green.shade800,
        );
      case 'physics':
        return DepartmentUIData(
          icon: Icons.science_rounded,
          color: Colors.purple.shade800,
        );
      default:
        return DepartmentUIData(
          icon: Icons.account_balance_rounded,
          color: Colors.grey.shade800,
        );
    }
  }
}
