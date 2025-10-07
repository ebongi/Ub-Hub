import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:neo/Screens/Shared/constanst.dart'; // Reusable widgets
import 'package:neo/services/auth.dart';
import 'package:provider/provider.dart';
// signin screen widget

class Register extends StatefulWidget {
   const Register({super.key, required this.istoggle});
  final Function istoggle;

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final _usernamecontroller =
      TextEditingController(); // controller to manage and control username field
  final _emailcontroller =
      TextEditingController(); // controller for email field
  final _passwordcontroller =
      TextEditingController(); // controller for password field
  final _formkey = GlobalKey<FormState>(); // key for validating form
  // ignore: non_constant_identifier_names
  bool _isPasswordObscured = true;
  bool _isLoading = false;
  final Authentication _authentication = Authentication();

  @override
  void dispose() {
    // Dispose controllers to prevent memory leaks
    _usernamecontroller.dispose();
    _emailcontroller.dispose();
    _passwordcontroller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 30),
              child: Form(
                key: _formkey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    buildImage(
                      path: "assets/images/registerimage.png",
                    ), // image to display
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Create Account",
                          style: TextStyle(
                            fontSize: 35,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[600],
                            letterSpacing: 1.5,
                          ),
                        ),
                        Text(
                          "      Signup to get started",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 10,
                      ),
                      child: TextFormField(
                        controller: _usernamecontroller,

                        validator:
                            (username) => // USER_NAME VALIDATION
                            username == null || username.isEmpty
                            ? 'Username is required'
                            : null,
                        style: TextStyle(fontSize: 20),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),

                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          hintText: "Username",
                          hintStyle: TextStyle(
                            letterSpacing: 1.3,
                            fontSize: 20,
                            color: Colors.grey.shade400,
                          ),
                          prefixIcon: Icon(
                            Icons.account_circle,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 10,
                      ),
                      child: TextFormField(
                        controller: _emailcontroller,
                        validator: (email) {
                          // EMAIL VALIDATION
                          if (email == null || email.isEmpty) {
                            return 'Please enter email';
                          }
                          return null;
                        },
                        style: TextStyle(fontSize: 20),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),

                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          hintText: "Email",
                          hintStyle: TextStyle(
                            letterSpacing: 1.3,
                            fontSize: 20,
                            color: Colors.grey.shade400,
                          ),
                          prefixIcon: Icon(Icons.email, color: Colors.blue),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 10,
                      ),
                      child: TextFormField(
                        controller: _passwordcontroller,
                        obscureText: _isPasswordObscured,
                        validator:
                            (password) => // PASSWORD VALIDATION
                            password == null || password.length < 6
                            ? 'Password must be more than 6 characters'
                            : null,
                        style: TextStyle(fontSize: 20),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),

                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _isPasswordObscured = !_isPasswordObscured;
                              });
                            },
                            icon: Icon(
                              _isPasswordObscured
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                          ),
                          hintText: "Password",
                          hintStyle: TextStyle(
                            letterSpacing: 1.3,
                            fontSize: 20,
                            color: Colors.grey.shade400,
                          ),
                          prefixIcon: Icon(Icons.lock, color: Colors.blue),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    FloatingActionButton.extended(
                      backgroundColor: Colors.blue,
                      onPressed: () async {
                        // Don't do anything if already loading
                        if (_isLoading) return;

                        if (_formkey.currentState?.validate() ?? false) {
                          setState(() => _isLoading = true);
                          try {
                            // Create the user in Firebase Auth
                            User? user = await _authentication
                                .createUserWithEmailAndPassword(
                                  email: _emailcontroller.text.trim(),
                                  password: _passwordcontroller.text.trim(),
                                );

                            if (user != null) {
                              // Update the user's display name
                              await user.updateDisplayName(
                                  _usernamecontroller.text.trim());
                              // Update the local UserModel state
                              Provider.of<UserModel>(context, listen: false)
                                  .setName(_usernamecontroller.text.trim());

                              // Pop the registration screen to reveal the AuthWrapper,
                              // which will then navigate to the NavBar.
                              // We check `mounted` to avoid errors if the widget is already disposed.
                              if (mounted) Navigator.of(context).pop();
                            }
                          } on FirebaseAuthException catch (e) {
                            // Show a user-friendly error message
                            if (mounted) {
                              String message = "An error occurred.";
                              if (e.code == 'weak-password') {
                                message = 'The password provided is too weak.';
                              } else if (e.code == 'email-already-in-use') {
                                message = 'An account already exists for that email.';
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(message), backgroundColor: Colors.red),
                              );
                            }
                          } finally {
                            // Ensure loading state is always turned off
                            if (mounted) {
                              setState(() => _isLoading = false);
                            }
                          }
                        }
                      },
                      label: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "                            Sign Up                            ",
                              style: TextStyle(fontSize: 20),
                            ),
                    ),
                    SizedBox(height: 10),

                    Align(
                      alignment: Alignment.bottomRight,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Already Have an acount?",
                            style: TextStyle(fontSize: 18),
                          ),
                          TextButton(
                            onPressed: ()  =>setState(() {
                              widget.istoggle();
                            }),
                            child:   Text(
                              "Sign In",
                              style: theme.textTheme.bodyMedium!.copyWith(
                                fontSize: 20,
                                color: Colors.blue,
                                fontWeight: FontWeight.bold
                              ) 
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
