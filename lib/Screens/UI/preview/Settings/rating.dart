import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Since this is just a dialog logic, we can make it a function or a simple widget
Future<void> showRatingDialog(BuildContext context) async {
  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Column(
        children: [
          const Icon(Icons.star_rounded, size: 60, color: Colors.amber),
          const SizedBox(height: 8),
          Text(
            "Rate Us!",
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: Text(
        "If you enjoy using Ub-Hub, please take a moment to rate us. It helps us improve!",
        textAlign: TextAlign.center,
        style: GoogleFonts.outfit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Later", style: GoogleFonts.outfit(color: Colors.grey)),
        ),
        FilledButton(
          onPressed: () {
            // Mock rating action
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Thank you for your rating! ⭐")),
            );
          },
          child: Text("Rate Now", style: GoogleFonts.outfit()),
        ),
      ],
      actionsAlignment: MainAxisAlignment.spaceEvenly,
    ),
  );
}
