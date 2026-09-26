import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../components/corner_marks.dart';
import '../../components/reveal.dart';
import '../../constants/content.dart';
import '../../constants/theme.dart';

class SupportSection extends StatefulComponent {
  const SupportSection({super.key});

  @override
  State<SupportSection> createState() => SupportSectionState();
}

class SupportSectionState extends State<SupportSection> {
  int openFaq = 0;

  void _toggle(int i) => setState(() => openFaq = openFaq == i ? -1 : i);

  @override
  Component build(BuildContext context) {
    return section(id: 'support', classes: 'gs-section gs-support', [
      div(classes: 'gs-container', [
        div(classes: 'gs-eyebrow', [.text('SUPPORT')]),
        h2(classes: 'gs-h2 gs-h2--tight', [.text('Stuck? Talk to a human')]),
        Reveal(classes: 'gs-support-grid', children: [
          div(classes: 'gs-contact-col', [
            a(href: 'mailto:$supportEmail', classes: 'gs-contact-card', [
              const CornerMarks(color: '#38BDF8'),
              div(classes: 'gs-contact-label', [.text('EMAIL')]),
              div(classes: 'gs-contact-value', [.text(supportEmail)]),
              div(classes: 'gs-contact-hint', [.text('Bugs, billing, account questions. We reply within 2 working days.')]),
            ]),
            a(href: whatsappUrl, classes: 'gs-contact-card', [
              const CornerMarks(color: '#38BDF8'),
              div(classes: 'gs-contact-label', [.text('WHATSAPP')]),
              div(classes: 'gs-contact-value', [.text(whatsappNumber)]),
              div(classes: 'gs-contact-hint', [.text('Fastest for transcript requests and payment confirmations.')]),
            ]),
          ]),
          div(classes: 'gs-faq-col', [
            div(classes: 'gs-faq-label', [.text('FREQUENT QUESTIONS')]),
            div(
              classes: 'gs-faq-list',
              [for (var i = 0; i < faqs.length; i++) FaqItem(faq: faqs[i], open: openFaq == i, onToggle: () => _toggle(i))],
            ),
          ]),
        ]),
      ]),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    css('.gs-h2--tight').styles(margin: .fromLTRB(0.px, 0.px, 0.px, 48.px)),
    css('.gs-support-grid').styles(display: .grid, gridTemplate: autoFitGrid(300), gap: .all(44.px), alignItems: .start),
    css('.gs-contact-col').styles(minWidth: 0.px, display: .flex, flexDirection: .column, gap: .all(16.px)),
    css('.gs-contact-card', [
      css('&').styles(
        position: .relative(),
        padding: .all(24.px),
        border: .all(color: border(.26), width: 1.px),
        display: .block,
        transition: Transition('all', duration: 200.ms),
      ),
      css('&:hover').styles(
        border: .all(color: accent, width: 1.px),
        backgroundColor: Color.rgba(56, 189, 248, .07),
        transform: .translate(y: (-3).px),
      ),
    ]),
    css('.gs-contact-label').styles(fontFamily: monoFontFamily, fontSize: 10.px, letterSpacing: .16.em, color: accentLight, margin: .only(bottom: 10.px)),
    css('.gs-contact-value').styles(fontSize: 18.px, fontWeight: .w600, color: heading, raw: {'word-break': 'break-all'}),
    css('.gs-contact-hint').styles(margin: .only(top: 8.px), fontSize: 14.px, color: textMuted2),
    css('.gs-faq-col').styles(minWidth: 0.px),
    css('.gs-faq-label').styles(fontFamily: monoFontFamily, fontSize: 10.px, letterSpacing: .16.em, color: accentLight, margin: .only(bottom: 18.px)),
    css('.gs-faq-list').styles(border: .only(top: .solid(color: border(.18), width: 1.px))),
  ];
}

class FaqItem extends StatelessComponent {
  final Faq faq;
  final bool open;
  final void Function() onToggle;
  const FaqItem({required this.faq, required this.open, required this.onToggle});

  @override
  Component build(BuildContext context) {
    return div(classes: 'gs-faq-item', [
      button(
        onClick: onToggle,
        classes: 'gs-faq-question',
        [
          span([.text(faq.q)]),
          span(classes: 'gs-faq-sign', [.text(open ? '−' : '+')]),
        ],
      ),
      if (open) p(classes: 'gs-faq-answer', [.text(faq.a)]),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    css('.gs-faq-item').styles(border: .only(bottom: .solid(color: border(.18), width: 1.px))),
    css('.gs-faq-question', [
      css('&').styles(
        width: 100.percent,
        display: .flex,
        gap: .all(16.px),
        alignItems: .center,
        justifyContent: .spaceBetween,
        padding: .symmetric(vertical: 20.px, horizontal: 2.px),
        backgroundColor: Colors.transparent,
        border: .none,
        cursor: .pointer,
        textAlign: .left,
        fontFamily: fontFamily,
        fontSize: 16.px,
        fontWeight: .w600,
        color: ink,
        transition: Transition('color', duration: 180.ms),
      ),
      css('&:hover').styles(color: accent),
    ]),
    css('.gs-faq-sign').styles(
      flex: Flex(grow: 0, shrink: 0),
      fontFamily: monoFontFamily,
      fontSize: 16.px,
      color: accent,
    ),
    css('.gs-faq-answer').styles(
      margin: .zero,
      padding: .fromLTRB(2.px, 0.px, 2.px, 22.px),
      maxWidth: ch(52),
      fontSize: 15.px,
      lineHeight: 1.65.em,
      color: textMuted,
    ),
  ];
}
