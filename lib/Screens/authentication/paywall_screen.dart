import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_study/Screens/Shared/animations.dart';
import 'package:go_study/Screens/UI/preview/Settings/subscription_plans_screen.dart';
import 'package:go_study/services/auth.dart';
import 'package:go_study/services/profile.dart';

class PaywallScreen extends StatelessWidget {
  final UserProfile profile;
  const PaywallScreen({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: Stack(
        children: [
          // Background Gradient Glow
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.primaryColor.withOpacity(0.1),
              ),
            ),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  
                  // Icon/Visual
                  FadeInSlide(
                    duration: const Duration(milliseconds: 600),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        size: 64,
                        color: theme.primaryColor,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Title
                  FadeInSlide(
                    delay: 200,
                    child: Text(
                      "Trial Period Ended",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Subtitle
                  FadeInSlide(
                    delay: 400,
                    child: Text(
                      "Your 4-day free access to  GoStudy has expired. Upgrade to a premium plan to unlock your academic dashboard, UB Support Bot, and unlimited materials.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        color: Colors.grey,
                        height: 1.5,
                      ),
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Upgrade Button
                  FadeInSlide(
                    delay: 600,
                    child: SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SubscriptionPlansScreen(userProfile: profile),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          "View Upgrade Plans",
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Logout Option
                  FadeInSlide(
                    delay: 800,
                    child: TextButton(
                      onPressed: () => Authentication().signUserOut(),
                      child: Text(
                        "Sign Out",
                        style: GoogleFonts.outfit(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
