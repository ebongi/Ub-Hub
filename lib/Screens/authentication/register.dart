import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neo/Screens/Shared/constanst.dart'; // Reusable widgets
import 'package:neo/services/auth.dart';
import 'package:provider/provider.dart';

class Register extends StatefulWidget {
  const Register({super.key, required this.istoggle});
  final Function istoggle;

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final _usernamecontroller = TextEditingController();
  final _emailcontroller = TextEditingController();
  final _passwordcontroller = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _matriculeController = TextEditingController();
  String _selectedLevel = "";
  final List<String> _levels = ["200", "300", "400", "500", "600", "Resit"];
  final _formkey = GlobalKey<FormState>();
  bool _isPasswordObscured = true;
  bool _isLoading = false;
  final Authentication _authentication = Authentication();

  @override
  void dispose() {
    _usernamecontroller.dispose();
    _emailcontroller.dispose();
    _passwordcontroller.dispose();
    _phoneNumberController.dispose();
    _matriculeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Form(
                    key: _formkey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const AuthHeader(
                          title: "Create Account",
                          subtitle:
                              "Sign up to get started and explore all our features.",
                        ),
                        const SizedBox(height: 40),

                        _buildSectionTitle(theme, "Account Access"),
                        const SizedBox(height: 16),
                        AuthTextField(
                          controller: _usernamecontroller,
                          hintText: "Full Name",
                          prefixIcon: Icons.person_rounded,
                          validator: (username) =>
                              username == null || username.isEmpty
                              ? 'Username is required'
                              : null,
                        ),
                        const SizedBox(height: 20),
                        AuthTextField(
                          controller: _emailcontroller,
                          hintText: "Email Address",
                          prefixIcon: Icons.email_rounded,
                          keyboardType: TextInputType.emailAddress,
                          validator: (email) {
                            if (email == null || email.isEmpty) {
                              return 'Please enter your email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        AuthTextField(
                          controller: _passwordcontroller,
                          hintText: "Password",
                          prefixIcon: Icons.lock_rounded,
                          obscureText: _isPasswordObscured,
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _isPasswordObscured = !_isPasswordObscured;
                              });
                            },
                            icon: Icon(
                              _isPasswordObscured
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              color: isDarkMode
                                  ? Colors.cyanAccent
                                  : theme.colorScheme.primary,
                            ),
                          ),
                          validator: (password) =>
                              password == null || password.length < 6
                              ? 'Password must be at least 6 characters'
                              : null,
                        ),

                        const SizedBox(height: 32),
                        const Divider(height: 1, thickness: 0.5),
                        const SizedBox(height: 32),

                        _buildSectionTitle(theme, "University Details"),
                        const SizedBox(height: 16),
                        AuthTextField(
                          controller: _matriculeController,
                          hintText: "Matricule (Student ID)",
                          prefixIcon: Icons.badge_rounded,
                          validator: (matricule) =>
                              matricule == null || matricule.isEmpty
                              ? 'Matricule is required'
                              : null,
                        ),
                        const SizedBox(height: 20),
                        AuthTextField(
                          controller: _phoneNumberController,
                          hintText: "Phone Number",
                          prefixIcon: Icons.phone_rounded,
                          keyboardType: TextInputType.phone,
                          validator: (phone) => phone == null || phone.isEmpty
                              ? 'Phone number is required'
                              : null,
                        ),
                        const SizedBox(height: 20),
                        AuthDropdown(
                          value: _selectedLevel,
                          hintText: "Select Level",
                          prefixIcon: Icons.school_rounded,
                          items: _levels,
                          onChanged: (val) {
                            setState(() {
                              _selectedLevel = val ?? "";
                            });
                          },
                          validator: (val) => val == null || val.isEmpty
                              ? 'Please select your level'
                              : null,
                        ),

                        const SizedBox(height: 48),
                        AuthButton(
                          label: "Sign Up",
                          isLoading: _isLoading,
                          onPressed: () async {
                            if (_isLoading) return;

                            if (_formkey.currentState?.validate() ?? false) {
                              setState(() => _isLoading = true);
                              try {
                                final user = await _authentication
                                    .createUserWithEmailAndPassword(
                                      email: _emailcontroller.text.trim(),
                                      password: _passwordcontroller.text.trim(),
                                      name: _usernamecontroller.text.trim(),
                                      matricule: _matriculeController.text
                                          .trim(),
                                      phoneNumber: _phoneNumberController.text
                                          .trim(),
                                      level: _selectedLevel,
                                    );

                                if (user != null && mounted) {
                                  Provider.of<UserModel>(
                                    context,
                                    listen: false,
                                  ).setName(_usernamecontroller.text.trim());
                                  Navigator.of(context).pop();
                                }
                              } on sb.AuthException catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      content: Text(e.message),
                                      backgroundColor: Colors.redAccent,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      content: const Text(
                                        "An unexpected error occurred",
                                      ),
                                      backgroundColor: Colors.redAccent,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  );
                                }
                              } finally {
                                if (mounted) {
                                  setState(() => _isLoading = false);
                                }
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        "Already have an account?",
                        style: GoogleFonts.outfit(
                          color: isDarkMode ? Colors.white70 : Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                      TextButton(
                        onPressed: () => widget.istoggle(),
                        child: Text(
                          "Sign In",
                          style: GoogleFonts.outfit(
                            color: isDarkMode
                                ? Colors.cyanAccent
                                : theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    final isDarkMode = theme.brightness == Brightness.dark;
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: isDarkMode ? Colors.cyanAccent : theme.colorScheme.primary,
      ),
    );
  }
}
