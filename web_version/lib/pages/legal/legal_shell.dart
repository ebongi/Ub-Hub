import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_router/jaspr_router.dart';

import '../../components/corner_marks.dart';
import '../../constants/content.dart';
import '../../constants/theme.dart';

/// Shared shell for the Privacy Policy and Terms of Service pages: back
/// link, title, subtitle, a "remove before publishing" draft note, and a
/// numbered list of section placeholders ready for the real policy text.
class LegalShell extends StatelessComponent {
  final String title;
  final String intro;
  final String draftNote;
  final List<LegalSection> sections;
  final String sectionPlaceholder;
  final List<Component> trailing;

  const LegalShell({
    required this.title,
    required this.intro,
    required this.draftNote,
    required this.sections,
    required this.sectionPlaceholder,
    this.trailing = const [],
    super.key,
  });

  @override
  Component build(BuildContext context) {
    return main_(classes: 'gs-legal', [
      div(classes: 'gs-legal-container', [
        Link(to: '/', classes: 'gs-legal-back', child: .text('← BACK TO HOME')),
        h1(classes: 'gs-legal-title', [.text(title)]),
        div(classes: 'gs-legal-meta', [.text('GOSTUDY · UNIVERSITY OF BUEA · LAST UPDATED [DATE]')]),
        p(classes: 'gs-legal-intro', [.text(intro)]),
        div(classes: 'gs-legal-draft-note', [
          const CornerMarks(color: '#38BDF8'),
          div(classes: 'gs-legal-draft-label', [.text('DRAFT NOTE — REMOVE BEFORE PUBLISHING')]),
          p(classes: 'gs-legal-draft-text', [.text(draftNote)]),
        ]),
        for (final s in sections) LegalSectionBlock(entry: s, placeholder: sectionPlaceholder),
        ...trailing,
      ]),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    css('.gs-legal').styles(padding: .fromLTRB(24.px, 72.px, 24.px, 84.px)),
    css('.gs-legal-container').styles(maxWidth: 800.px, margin: .symmetric(horizontal: .auto)),
    css('.gs-legal-back').styles(fontFamily: monoFontFamily, fontSize: 11.px, letterSpacing: .16.em, color: accentLight),
    css('.gs-legal-title').styles(
      margin: .fromLTRB(0.px, 26.px, 0.px, 10.px),
      fontSize: .expression('clamp(32px,4.4vw,48px)'),
      fontWeight: .w800,
      letterSpacing: (-.025).em,
      color: heading,
    ),
    css('.gs-legal-meta').styles(margin: .only(bottom: 12.px), fontFamily: monoFontFamily, fontSize: 11.px, letterSpacing: .12.em, color: textMuted3),
    css('.gs-legal-intro').styles(margin: .fromLTRB(0.px, 0.px, 0.px, 44.px), fontSize: 17.px, lineHeight: 1.65.em, color: textMuted, maxWidth: ch(60)),
    css('.gs-legal-draft-note').styles(
      position: .relative(),
      padding: .symmetric(vertical: 22.px, horizontal: 24.px),
      border: .all(color: Color.rgba(56, 189, 248, .34), width: 1.px),
      raw: {'background-image': 'linear-gradient(rgba(56,189,248,.07),rgba(56,189,248,.02))'},
      margin: .only(bottom: 52.px),
    ),
    css('.gs-legal-draft-label').styles(fontFamily: monoFontFamily, fontSize: 10.px, letterSpacing: .16.em, color: accent, margin: .only(bottom: 8.px)),
    css('.gs-legal-draft-text').styles(margin: .zero, fontSize: 14.5.px, lineHeight: 1.6.em, color: Color('#C7D6E9')),
  ];
}

class LegalSectionBlock extends StatelessComponent {
  final LegalSection entry;
  final String placeholder;
  const LegalSectionBlock({required this.entry, required this.placeholder});

  @override
  Component build(BuildContext context) {
    return section(classes: 'gs-legal-section', [
      div(classes: 'gs-legal-section-head', [
        span(classes: 'gs-legal-section-n', [.text(entry.n)]),
        h2(classes: 'gs-legal-section-title', [.text(entry.title)]),
      ]),
      p(classes: 'gs-legal-section-hint', [.text(entry.hint)]),
      div(classes: 'gs-legal-placeholder', [.text(placeholder)]),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    css('.gs-legal-section').styles(margin: .only(bottom: 44.px)),
    css('.gs-legal-section-head').styles(display: .flex, gap: .all(14.px), alignItems: .baseline, margin: .only(bottom: 14.px)),
    css('.gs-legal-section-n').styles(fontFamily: monoFontFamily, fontSize: 11.px, letterSpacing: .14.em, color: accent),
    css('.gs-legal-section-title').styles(margin: .zero, fontSize: 23.px, fontWeight: .w700, letterSpacing: (-.015).em, color: heading),
    css('.gs-legal-section-hint').styles(margin: .fromLTRB(0.px, 0.px, 0.px, 14.px), fontSize: 15.px, lineHeight: 1.6.em, color: textMuted2, maxWidth: ch(62)),
    css('.gs-legal-placeholder').styles(
      padding: .all(26.px),
      border: .all(color: border(.28), width: 1.px, style: .dashed),
      fontFamily: monoFontFamily,
      fontSize: 11.px,
      letterSpacing: .10.em,
      color: textMuted3,
    ),
  ];
}
