import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Small pill shown next to a course wherever a student picks where to
/// upload — signals that an approved submission to this course currently
/// earns boosted points (courses.bounty_multiplier; see
/// reward_material_approval_and_points_redemption.sql).
class BountyBadge extends StatelessWidget {
  const BountyBadge({super.key, required this.multiplier});

  final double multiplier;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = multiplier == multiplier.roundToDouble()
        ? '${multiplier.toInt()}x'
        : '${multiplier}x';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.amber.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt_rounded, size: 12, color: Colors.amber),
          const SizedBox(width: 2),
          Text(
            'Bounty $label',
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: theme.brightness == Brightness.dark
                  ? Colors.amber[200]
                  : Colors.amber[800],
            ),
          ),
        ],
      ),
    );
  }
}
