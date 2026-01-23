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
  final _formkey = GlobalKey<FormState>();
  bool _isPasswordObscured = true;
  bool _isLoading = false;
  final Authentication _authentication = Authentication();

  @override
  void dispose() {
    _usernamecontroller.dispose();
    _emailcontroller.dispose();
    _passwordcontroller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Form(
              key: _formkey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        border: Border.all(
                          color: theme.colorScheme.primary.withOpacity(0.2),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.person_add_rounded,
                        size: 80,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const AuthHeader(
                    title: "Create Account",
                    subtitle:
                        "Sign up to get started and explore all our features.",
                  ),
                  const SizedBox(height: 32),
                  AuthTextField(
                    controller: _usernamecontroller,
                    hintText: "Full Name",
                    prefixIcon: Icons.person_rounded,
                    validator: (username) =>
                        username == null || username.isEmpty
                        ? 'Username is required'
                        : null,
                  ),
                  const SizedBox(height: 16),
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
                  const SizedBox(height: 16),
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
                        color: theme.colorScheme.primary,
                      ), // Removed cyanAccent check to enforce brand blue
                    ),
                    validator: (password) =>
                        password == null || password.length < 6
                        ? 'Password must be at least 6 characters'
                        : null,
                  ),
                  const SizedBox(height: 32),
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
                                content: Text(e.message),
                                backgroundColor: theme.colorScheme.error,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  "An unexpected error occurred",
                                ),
                                backgroundColor: theme.colorScheme.error,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
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
                  const SizedBox(height: 24),
                  Center(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          "Already have an account?",
                          style: GoogleFonts.outfit(
                            color: theme.textTheme.bodyMedium?.color
                                ?.withOpacity(0.7),
                            fontSize: 15,
                          ),
                        ),
                        TextButton(
                          onPressed: () => widget.istoggle(),
                          child: Text(
                            "Sign In",
                            style: GoogleFonts.outfit(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
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
      ),
    );
  }
}
