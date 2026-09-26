import 'package:flutter/material.dart';
import 'package:go_study/theme/app_text_styles.dart';

/// Bold section title with an optional trailing widget (typically a
/// "See All" button) — used above every horizontally-scrolling content
/// row on the home feed.
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0, left: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppText.sectionTitle(context)),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
