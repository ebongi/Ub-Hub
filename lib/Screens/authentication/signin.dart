import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neo/Screens/Shared/constanst.dart';
import 'package:neo/services/auth.dart';

class Signin extends StatefulWidget {
  final Authentication? authService;
  const Signin({super.key, required this.istoggle, this.authService});
  final Function istoggle;

  @override
  State<Signin> createState() => _SigninState();
}

class _SigninState extends State<Signin> {
  final _emailcontroller = TextEditingController();
  final _passwordcontroller = TextEditingController();
  final _formkey = GlobalKey<FormState>();
  late final Authentication _authentication;
  bool viewPassword = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _authentication = widget.authService ?? Authentication();
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
                          title: "Welcome Back",
                          subtitle:
                              "Sign in to your account to continue your academic journey.",
                        ),
                        const SizedBox(height: 40),
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
                          obscureText: !viewPassword,
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                viewPassword = !viewPassword;
                              });
                            },
                            icon: Icon(
                              viewPassword
                                  ? Icons.visibility_rounded
                                  : Icons.visibility_off_rounded,
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
                        const SizedBox(height: 40),
                        AuthButton(
                          label: "Sign In",
                          isLoading: _isLoading,
                          onPressed: () async {
                            if (_isLoading) return;

                            if (_formkey.currentState?.validate() ?? false) {
                              setState(() => _isLoading = true);
                              try {
                                await _authentication
                                    .signUserWithEmailAndPassword(
                                      email: _emailcontroller.text.trim(),
                                      password: _passwordcontroller.text.trim(),
                                    );
                              } on sb.AuthException catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(e.message),
                                      backgroundColor: Colors.redAccent,
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
                                      backgroundColor: Colors.redAccent,
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
                        "Don't have an account?",
                        style: GoogleFonts.outfit(
                          color: isDarkMode ? Colors.white70 : Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                      TextButton(
                        onPressed: () => widget.istoggle(),
                        child: Text(
                          "Sign Up",
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
}
