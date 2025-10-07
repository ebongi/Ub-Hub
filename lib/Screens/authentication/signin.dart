import 'package:flutter/material.dart'; // As you know it the material widget import
import 'package:google_fonts/google_fonts.dart';
import 'package:neo/Screens/Shared/constanst.dart'; // Custom reusable widgets
import 'package:neo/services/auth.dart'; // Register screen widget

class Signin extends StatefulWidget {
  const Signin({super.key, required this.istoggle});
  final Function istoggle;

  @override
  State<Signin> createState() => _SigninState();
}

class _SigninState extends State<Signin> {
  //controllers to manage and control Email and password in the signinScreen
  final _emailcontroller = TextEditingController();
  final _passwordcontroller = TextEditingController();
  final _formkey = GlobalKey<FormState>();
  final Authentication _authentication = Authentication();
  // ignore: non_constant_identifier_names
  bool view_password = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
                      path: "assets/images/signincolab.png",
                    ), // Custom image to display along side Email and Password field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Welcome Back",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                            fontSize: 35,
                            letterSpacing: 1.2,
                            color: Colors.blue
                          ),
                        ),
                        Text(
                          "       Sign in to continue",
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
                    // Email Text Field
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 10,
                      ),
                      child: TextFormField(
                        controller: _emailcontroller,

                        validator: (email) {
                          // checks if email field is Null or empty
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
                    //Password TextField
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 10,
                      ),
                      child: TextFormField(
                        controller: _passwordcontroller,
                        obscureText: view_password,
                        validator:
                            (
                              password,
                            ) => // Checks if password field is null or length is lesss than 6 characters
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
                                view_password = !view_password;
                              });
                            },
                            icon: Icon(
                              view_password
                                  ? Icons.remove_red_eye
                                  : Icons.remove_red_eye_outlined,
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
                      backgroundColor: Colors.lightBlue,
                      onPressed: () async {
                        if (_isLoading) return;

                        if (_formkey.currentState?.validate() ?? false) {
                          setState(() => _isLoading = true);
                          try {
                            // ignore: unused_local_variable
                            dynamic result = await _authentication
                                .signUserWithEmailAndPassword(
                                  email: _emailcontroller.text.trim(),
                                  password: _passwordcontroller.text.trim(),
                                );

                            // if (result != null) {
                            //   // The AuthWrapper will see the new user and navigate to Home.
                            //   // We just need to pop the registration screen.
                            //   if (mounted) Navigator.of(context).pop();
                            // }
                          } catch (e) {
                            // Show a user-friendly error message
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    " Error occured while signing in User: ${e.toString()}",
                                  ),
                                  backgroundColor: Colors.red,
                                ),
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
                          :  Text(
                              "                            Sign In                            ",
                              style:  theme.textTheme.bodyMedium!.copyWith(
                                fontSize: 20
                              )
                            ),
                    ),
                    SizedBox(height: 10),

                    Align(
                      alignment: Alignment.bottomRight,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't Have an acount?",
                            style: TextStyle(fontSize: 18),
                          ),
                          TextButton(
                            onPressed: () => setState(() {
                              widget.istoggle();
                            }),
                            child:   Text(
                              "Sign Up",
                              style:  theme.textTheme.bodyMedium!.copyWith(
                                color: Colors.blue,
                                fontSize: 19
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 10),
                  ],
                ),
              ), //Form widget ends Here!
            ),
          ),
        ),
      ),
    );
  }
}
