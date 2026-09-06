import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_study/core/app_assets.dart';

/// The "GoStudy" wordmark: the brand icon stands in for the letter "G",
/// immediately followed by "oStudy" text. Use this instead of typing the
/// app name as plain text anywhere it's shown as a name/heading, so the
/// icon and the name never drift apart.
class AppWordmark extends StatelessWidget {
  const AppWordmark({
    super.key,
    this.fontSize = 20,
    double? iconSize,
    this.color = const Color(0xFF1656D8),
    this.fontWeight = FontWeight.w800,
  }) : iconSize = iconSize ?? fontSize * 1.7;

  final double fontSize;
  final double iconSize;
  final Color color;
  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(
          AppAssets.logo,
          width: iconSize,
          height: iconSize,
          fit: BoxFit.contain,
          cacheWidth: (iconSize * 2.5).round(),
        ),
        const SizedBox(width: 3),
        Text(
          'oStudy',
          style: GoogleFonts.outfit(
            fontSize: fontSize,
            fontWeight: fontWeight,
            fontStyle: FontStyle.italic,
            color: color,
            height: 1.0,
          ),
        ),
      ],
    );
  }
}
