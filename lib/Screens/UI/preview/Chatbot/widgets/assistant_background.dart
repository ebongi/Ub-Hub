import 'package:flutter/material.dart';

/// Soft blue → lavender wash that sits behind the assistant chat screens
/// (online [ChatbotScreen] and offline GemmaChatScreen). Pure decoration —
/// no blur, no interactivity — so it can wrap a whole `SafeArea`/`Column`.
class AssistantBackground extends StatelessWidget {
  const AssistantBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final colors = isDark
        ? [
            theme.scaffoldBackgroundColor,
            Color.alphaBlend(
              theme.colorScheme.primary.withOpacity(0.06),
              theme.scaffoldBackgroundColor,
            ),
          ]
        : const [Color(0xFFEDF2FF), Color(0xFFF4EDFF)];

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: child,
    );
  }
}
