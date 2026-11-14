import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:go_study/l10n/generated/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:markdown_widget/markdown_widget.dart';

/// One chat message — the single bubble implementation shared by the online
/// [ChatbotScreen] and the offline GemmaChatScreen (which each used to carry
/// a near-identical private copy). Blue user bubble with white text, white
/// assistant card with a soft shadow; markdown + `$…$` LaTeX for assistant
/// text. Optional [thinking] toggle and [attachments] are online-only and
/// simply stay null offline.
class AssistantMessageBubble extends StatefulWidget {
  const AssistantMessageBubble({
    super.key,
    required this.text,
    required this.isUser,
    required this.createdAt,
    this.isError = false,
    this.thinking,
    this.showThinking = false,
    this.onThinkingToggled,
    this.attachments,
  });

  final String text;
  final bool isUser;
  final DateTime createdAt;
  final bool isError;

  /// Collapsed "thinking" text. When null the toggle row is not rendered.
  final String? thinking;
  final bool showThinking;
  final ValueChanged<bool>? onThinkingToggled;

  /// Caller-built attachment strip, rendered above the text.
  final Widget? attachments;

  @override
  State<AssistantMessageBubble> createState() => _AssistantMessageBubbleState();
}

class _AssistantMessageBubbleState extends State<AssistantMessageBubble> {
  late bool _showThinking = widget.showThinking;

  @override
  void didUpdateWidget(AssistantMessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.key != oldWidget.key) {
      _showThinking = widget.showThinking;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isUser = widget.isUser;
    final onSurface = theme.colorScheme.onSurface;
    final l10n = AppLocalizations.of(context)!;

    final Color bubbleColor = isUser
        ? theme.colorScheme.primary
        : (widget.isError
            ? Colors.red.withOpacity(0.05)
            : (isDark ? const Color(0xFF1E1F20) : Colors.white));

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          mainAxisAlignment:
              isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isUser)
              Padding(
                padding: const EdgeInsets.only(left: 2, right: 4, bottom: 2),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: 20,
                  color: Colors.blue.shade400,
                ),
              ),
            Flexible(
              child: Column(
                crossAxisAlignment: isUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width *
                          (isUser ? 0.78 : 0.94),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: isUser ? 18 : 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: bubbleColor,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(22),
                        topRight: const Radius.circular(22),
                        bottomLeft: Radius.circular(isUser ? 22 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 22),
                      ),
                      border: !isUser
                          ? Border.all(
                              color: widget.isError
                                  ? Colors.red.withOpacity(0.2)
                                  : (isDark
                                      ? Colors.white.withOpacity(0.06)
                                      : Colors.black.withOpacity(0.05)),
                            )
                          : null,
                      boxShadow: !isUser && !widget.isError
                          ? [
                              BoxShadow(
                                color: Colors.black.withOpacity(
                                  isDark ? 0.2 : 0.04,
                                ),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: isUser
                        ? _buildUserContent()
                        : _buildAssistantContent(theme, l10n, onSurface, isDark),
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      DateFormat('HH:mm').format(widget.createdAt),
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: isDark ? Colors.white30 : Colors.grey[400],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (widget.attachments != null) widget.attachments!,
        Text(
          widget.text,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 16,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildAssistantContent(
    ThemeData theme,
    AppLocalizations l10n,
    Color onSurface,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.thinking != null) ...[
          GestureDetector(
            onTap: () {
              setState(() => _showThinking = !_showThinking);
              widget.onThinkingToggled?.call(_showThinking);
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.auto_awesome_outlined,
                  size: 20,
                  color: Color(0xFF4285F4),
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.showThinkingLabel,
                  style: GoogleFonts.outfit(
                    color: onSurface.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
                Icon(
                  _showThinking
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 20,
                  color: onSurface.withOpacity(0.4),
                ),
              ],
            ),
          ),
          if (_showThinking)
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 16),
              child: Text(
                widget.thinking!,
                style: GoogleFonts.outfit(
                  color: onSurface.withOpacity(0.5),
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          const SizedBox(height: 12),
        ],
        if (widget.attachments != null) widget.attachments!,
        MarkdownBlock(
          data: widget.text,
          config: MarkdownConfig(
            configs: [
              PConfig(
                textStyle: GoogleFonts.outfit(
                  color: widget.isError ? Colors.red.shade400 : onSurface,
                  fontSize: 16,
                  height: 1.6,
                ),
              ),
              TableConfig(
                wrapper: (child) => SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: child,
                ),
              ),
              PreConfig(
                wrapper: (child, code, language) => AssistantCodeBlock(
                  code: code,
                  language: language,
                  child: child,
                ),
                // Radius/border are owned by AssistantCodeBlock's outer frame;
                // markdown_widget already gives `child` its own horizontal
                // scroll view, so this stays a plain filled box.
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.05),
                ),
                padding: const EdgeInsets.all(16),
              ),
            ],
          ),
          generator: MarkdownGenerator(
            generators: [assistantLatexGenerator],
            inlineSyntaxList: [AssistantLatexSyntax()],
          ),
        ),
      ],
    );
  }
}

/// Three-dot "assistant is typing" bubble, shown while the first chunk of a
/// response is still pending.
class AssistantTypingIndicator extends StatefulWidget {
  const AssistantTypingIndicator({super.key});

  @override
  State<AssistantTypingIndicator> createState() =>
      _AssistantTypingIndicatorState();
}

class _AssistantTypingIndicatorState extends State<AssistantTypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1F20) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(22),
            topRight: Radius.circular(22),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(22),
          ),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.black.withOpacity(0.05),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final delay = index * 0.2;
                final value = Curves.easeInOut.transform(
                  (_controller.value + delay) % 1.0,
                );
                return Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.primary.withOpacity(
                      0.3 + (value * 0.7),
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }
}

// --- Markdown / LaTeX support (shared single copy) ---------------------------

final assistantLatexGenerator = SpanNodeGeneratorWithTag(
  tag: 'latex',
  generator: (e, config, visitor) =>
      _LatexNode(e.attributes['content'] ?? '', config),
);

class _LatexNode extends SpanNode {
  final String content;
  final MarkdownConfig config;

  _LatexNode(this.content, this.config);

  @override
  InlineSpan build() {
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Material(
        color: Colors.transparent,
        child: Math.tex(
          content,
          mathStyle: MathStyle.text,
          textStyle: config.p.textStyle,
          onErrorFallback: (err) => Text(
            content,
            style: config.p.textStyle.copyWith(color: Colors.red),
          ),
        ),
      ),
    );
  }
}

/// Inline `$…$` / `$$…$$` matcher with a math-vs-currency guard so plain
/// prose like "it costs $5 and $10 shipping" isn't rendered as an equation.
class AssistantLatexSyntax extends md.InlineSyntax {
  AssistantLatexSyntax() : super(r'(\$\$?)([\s\S]+?)\1');

  static const _mathWords = {
    'sin', 'cos', 'tan', 'sec', 'csc', 'cot',
    'log', 'ln', 'exp', 'max', 'min', 'det',
    'lim', 'sup', 'inf', 'mod', 'gcd', 'lcm', 'arg',
  };

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final content = match.group(2) ?? '';
    if (!_looksLikeMath(content)) return false;
    parser.addNode(
      md.Element.withTag('latex')..attributes['content'] = content,
    );
    return true;
  }

  static bool _looksLikeMath(String content) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return false;
    if (trimmed.contains('\n\n')) return false; // spans a paragraph break
    if (trimmed.contains('\\')) return true; // a LaTeX command
    if (RegExp(r'[=^_+/<>]').hasMatch(trimmed)) return true; // an operator

    final plainWordCount = RegExp(r'[A-Za-z]{2,}')
        .allMatches(trimmed)
        .map((m) => m.group(0)!.toLowerCase())
        .where((w) => !_mathWords.contains(w))
        .length;
    return plainWordCount < 2;
  }
}

/// Fenced-code wrapper: a language label + copy button above the code.
///
/// [child] is markdown_widget's own code container — it is already
/// `width: double.infinity` wrapping its own horizontal `SingleChildScrollView`,
/// so it MUST NOT be wrapped in another horizontal scroll view (that feeds it
/// an unbounded width and throws "BoxConstraints forces an infinite width",
/// blanking the whole message list). It is placed directly in a stretched
/// column instead.
class AssistantCodeBlock extends StatelessWidget {
  final Widget child;
  final String code;
  final String language;

  const AssistantCodeBlock({
    super.key,
    required this.child,
    required this.code,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.10)
              : Colors.black.withOpacity(0.10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  (language.isEmpty ? 'code' : language).toUpperCase(),
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(context)!.codeCopiedToClipboard,
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.copy_rounded,
                        size: 14,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        AppLocalizations.of(context)!.copyButton,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }
}
