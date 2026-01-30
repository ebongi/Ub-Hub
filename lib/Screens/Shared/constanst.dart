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
    return Container(
      height: MediaQuery.sizeOf(context).height / 3.5,
      width: MediaQuery.sizeOf(context).width / 2.275,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 100,
            width: MediaQuery.sizeOf(context).width / 2.5,
            child: Image.asset(imageurl, fit: BoxFit.cover),
          ),
          SizedBox(height: 2),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 18)),
              Text(description),
              Text(hostid),
            ],
          ),
        ],
      ),
    );
  }
}

List<Map<String, String>> computersciencecourses = [
  {'CSC205': 'Introduction to Computer Science'},
  {'CSC207': 'Introduction to  Algorithms'},
  {'CSC208': 'Programming in Python and C'},
  {'CSC209': 'Mathematical Foundations of Computer Science'},
  {'CSC210': 'Matrices and Linear Transformations'},
  {'CSC211': 'Probability and Statistics'},
  {'CSC212': 'Issues in Computing'},
  {'CSC214': 'Internet Technology and Web Design'},
  {'CSC301': 'Data Structures and Algorithms'},
  {'CSC303': 'Computer Organization and Architecture'},
  {'CSC304': 'Database Design'},
  {'CSC305': 'Object Oriented Programming'},
  {'CSC308': 'Java Programming'},
  {'CSC310': 'Database Design'},
  {'CSC311': 'Introduction to Computer Networks'},
  {'CSC314': 'Operating Systems'},
  {'CSC316': 'Functional Programming'},
  {'CSC402': 'Languages and Compilers'},
  {'CSC403': 'Numerical Analysis'},
  {'CSC404': 'Software Engineering'},
  {'CSC405': 'Artificial Intelligence'},
  {'CSC407': 'Programming and Language Paradigms'},
  {'CSC498': 'Computer Science Project'},
];

List<Map<String, String>> mathematicsCourses = [
  {'MAT201': 'Calculus I'},
  {'MAT202': 'Calculus II'},
  {'MAT203': 'Abstract Algebra'},
  {'MAT204': 'Linear Methods'},
  {'MAT207': 'Mathematical Methods IA'},
  {'MAT208': 'Mathematical Methods IIA'},
  {'MAT211': 'Mathematical Methods'},
  {'MAT301': 'Analysis I'},
  {'MAT302': 'Analysis II'},
  {'MAT303': 'Linear Algebra I'},
  {'MAT304': 'Linear Algebra II'},
  {'MAT305': 'Mathematical Probability I'},
  {'MAT306': 'Introduction to Mathematical Statistics'},
  {'MAT307': 'Introduction to Differential Equations'},
  {'MAT310': 'Mathematical Methods III'},
  {'MAT311': 'Analytical Mechanics'},
  {'MAT312': 'Electromagnetism'},
  {'MAT314': 'Analytic Geometry'},
  {'MAT401': 'Analysis III'},
  {'MAT402': 'General Topology'},
  {'MAT403': 'Set Theory'},
  {'MAT404': 'Group Theory'},
  {'MAT406': 'Mathematical Probability II'},
  {'MAT407': 'Complex Analysis I'},
  {'MAT409': 'Ordinary Differential Equations'},
  {'MAT411': 'Analytical Dynamics'},
  {'MAT412': 'Hydromechanics'},
  {'MAT413': 'Affine and Projective Geometry'},
  {'MAT415': 'Differential Geometry'},
  {'MAT416': 'Measure Theory and Integration'},
  {'MAT417': 'Calculus of Variations'},
  {'MAT418': 'Numerical Methods'},
  {'MAT419': 'Elements of Stochastic Processes'},
  {'MAT420': 'Elements of Queuing Theory'},
  {'MAT421': 'Multivariate Statistics'},
  {'MAT422': 'Introduction to Optimization'},
  {'MAT423': 'Combinatorics and Graph Theory'},
  {'MAT498': 'Research Project'},
];

List<Map<String, String>> physicsCourses = [
  {'ELT201': 'Electronic Devices'},
  {'ELT204': 'Analogue Electronics and basic circuit analysis'},
  {'ELT301': 'Digital Electronics'},
  {'ELT302': 'Microprocessors'},
  {'ELT303': 'Applied Electronics and Workshop Practice'},
  {'ELT304': 'Digital design laboratory'},
  {'ELT307': 'RF and Microwave Systems'},
  {'ELT401': 'Power Electronics'},
  {'ELT402': 'Communication systems'},
  {'ELT403': 'Analogue Integrated circuits'},
  {'ELT404': 'Introduction to control systems'},
  {'ELT406': 'Digital signal processing'},
  {'ELT408': 'Introduction toPHYsical design and Integrated circuits'},
  {'ELT410': 'Signal and systems'},
  {'ELT412': 'Computer architecture and data networks'},
  {'ELT426': 'Analogue Integrated circuits laboratory'},
  {'ELT491': 'Professional Internship'},
  {'ELT498': 'Project'},
  {'PHY202': 'Mechanics I'},
  {'PHY205': 'Thermodynamics and Structure of Matter'},
  {'PHY207': 'Mathematical Methods forPHYsics I'},
  {'PHY208': 'Electricity and Magnetism I'},
  {'PHY211': 'Waves and Optics I'},
  {'PHY212': 'GeneralPHYsics'},
  {'PHY215': 'Basic Concepts of Waves and Optics'},
  {'PHY218': 'Principles of Electricity and Magnetism'},
  {'PHY220': 'GeneralPHYsics'},
  {'PHY301': 'Mechanics II'},
  {'PHY305': 'Electricity and Magnetism II'},
  {'PHY306': 'Mathematical Methods of PHYsics II'},
  {'PHY308': 'Quantum Mechanics I'},
  {'PHY311': 'General Physics IIA'},
  {'PHY312': 'ThermalPHYsics'},
  {'PHY314': 'Special Relativity'},
  {'PHY317': 'Electronics I'},
  {'PHY405': 'Solid StatePHYsics'},
  {'PHY406': 'Atomic and NuclearPHYsics'},
  {'PHY410': 'Quantum Mechanics II'},
  {'PHY411': 'Electrodynamics'},
  {'PHY412': 'Waves and Optics II'},
  {'PHY417': 'Introduction to General Relativity and Cosmology'},
  {'PHY419': 'Introduction to Geophysics'},
  {'PHY420': 'Introduction to StatisticalPHYsics and Applications'},
  {'PHY422': 'Electronics II'},
  {'PHY424': 'Introduction to fluid mechanics'},
  {'PHY498': 'Physics project'},
];

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
    final isDarkMode = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : theme.colorScheme.primary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: GoogleFonts.outfit(
            fontSize: 16,
            color: isDarkMode ? Colors.white70 : Colors.grey[600],
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
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? theme.cardTheme.color : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(isDarkMode ? 0.05 : 0),
        ),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        validator: validator,
        keyboardType: keyboardType,
        style: GoogleFonts.outfit(fontSize: 16),
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: Icon(
            prefixIcon,
            color: isDarkMode ? Colors.cyanAccent : theme.colorScheme.primary,
          ),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 20,
            horizontal: 16,
          ),
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
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDarkMode
              ? Colors.cyanAccent
              : theme.colorScheme.primary,
          foregroundColor: isDarkMode ? Colors.black : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: isDarkMode ? 0 : 2,
        ),
        child: isLoading
            ? CircularProgressIndicator(
                color: isDarkMode ? Colors.black : Colors.white,
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
