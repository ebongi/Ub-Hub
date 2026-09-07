import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../components/corner_marks.dart';
import '../../constants/content.dart';
import '../../constants/theme.dart';

class PricingSection extends StatelessComponent {
  const PricingSection({super.key});

  @override
  Component build(BuildContext context) {
    return section(id: 'pricing', classes: 'gs-section', [
      div(classes: 'gs-container', [
        div(classes: 'gs-eyebrow', [.text('PRICING')]),
        h2(classes: 'gs-h2', [.text('Student pricing, student payments')]),
        p(classes: 'gs-lede', [
          .text(
            'Pay with the money you already have on your phone — MTN Mobile Money or Orange Money. '
            'No card, no bank visit, no minimum.',
          ),
        ]),
        div(classes: 'gs-pricing-grid', [
          div(classes: 'gs-plan-card', [
            const CornerMarks(color: '#38BDF8'),
            div(classes: 'gs-plan-tag', [.text('PLAN 01')]),
            h3(classes: 'gs-plan-name', [.text('Monthly')]),
            div(classes: 'gs-plan-price', [
              span(classes: 'gs-plan-amount', [.text('500')]),
              span(classes: 'gs-plan-unit', [.text('XAF / month')]),
            ]),
            p(classes: 'gs-plan-desc', [
              .text('Full access, renewed month to month. Stop any time — nothing auto-charges without you.'),
            ]),
            a(href: playStoreUrl, classes: 'gs-plan-cta gs-plan-cta--outline', [.text('Choose monthly')]),
          ]),
          div(classes: 'gs-plan-card gs-plan-card--highlight', [
            const CornerMarks(color: '#38BDF8'),
            div(classes: 'gs-plan-top-row', [
              div(classes: 'gs-plan-tag', [.text('PLAN 02')]),
              div(classes: 'gs-plan-badge', [.text('BEST VALUE')]),
            ]),
            h3(classes: 'gs-plan-name', [.text('Yearly')]),
            div(classes: 'gs-plan-price', [
              span(classes: 'gs-plan-amount', [.text('3,500')]),
              span(classes: 'gs-plan-unit', [.text('XAF / year')]),
            ]),
            p(classes: 'gs-plan-desc gs-plan-desc--light', [
              .text(
                'Roughly 292 XAF a month — you save 2,500 XAF over paying monthly. '
                'Best if you are here for the full academic year.',
              ),
            ]),
            a(href: playStoreUrl, classes: 'gs-plan-cta gs-plan-cta--solid', [.text('Choose yearly')]),
          ]),
          div(classes: 'gs-payment-card', [
            div(classes: 'gs-plan-tag', [.text('PAYMENT')]),
            h3(classes: 'gs-plan-name', [.text('Mobile money')]),
            p(classes: 'gs-payment-desc', [
              .text(
                'Checkout runs on the mobile money you already use. Approve the prompt on your phone and '
                'your plan activates immediately.',
              ),
            ]),
            div(classes: 'gs-payment-methods', [
              div(classes: 'gs-payment-method', [.text('MTN Mobile Money')]),
              div(classes: 'gs-payment-method', [.text('Orange Money')]),
            ]),
            p(classes: 'gs-payment-footnote', [
              .text('PROCESSED BY FAPSHI. GOSTUDY NEVER SEES OR STORES YOUR MOBILE MONEY PIN.'),
            ]),
          ]),
        ]),
        p(classes: 'gs-pricing-footnote', [
          .text('PRICES SHOWN IN XAF AND MAY BE ADJUSTED — THE APP ALWAYS SHOWS THE CURRENT RATE AT CHECKOUT.'),
        ]),
      ]),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    css('.gs-pricing-grid').styles(display: .grid, gridTemplate: autoFitGrid(260), gap: .all(24.px), alignItems: .stretch),
    css('.gs-plan-card').styles(
      position: .relative(),
      padding: .fromLTRB(30.px, 34.px, 30.px, 36.px),
      border: .all(color: border(.26), width: 1.px),
      display: .flex,
      flexDirection: .column,
    ),
    css('.gs-plan-card--highlight').styles(
      border: .all(color: accent, width: 1.px),
      raw: {'background-image': 'linear-gradient(rgba(56,189,248,.07),rgba(56,189,248,.02))'},
    ),
    css('.gs-plan-top-row').styles(display: .flex, justifyContent: .spaceBetween, alignItems: .center, gap: .all(12.px)),
    css('.gs-plan-tag').styles(fontFamily: monoFontFamily, fontSize: 10.px, letterSpacing: .16.em, color: accentLight),
    css('.gs-plan-badge').styles(
      padding: .symmetric(vertical: 4.px, horizontal: 9.px),
      backgroundColor: accent,
      color: bg,
      fontFamily: monoFontFamily,
      fontSize: 10.px,
      letterSpacing: .10.em,
      fontWeight: .w700,
    ),
    css('.gs-plan-name').styles(margin: .fromLTRB(0.px, 16.px, 0.px, 0.px), fontSize: 22.px, fontWeight: .w700, color: heading),
    css('.gs-plan-price').styles(margin: .fromLTRB(0.px, 18.px, 0.px, 6.px), display: .flex, alignItems: .baseline, gap: .all(8.px)),
    css('.gs-plan-amount').styles(fontSize: 44.px, fontWeight: .w800, letterSpacing: (-.03).em, color: heading),
    css('.gs-plan-unit').styles(fontSize: 15.px, fontWeight: .w600, color: accentLight),
    css('.gs-plan-desc').styles(margin: .fromLTRB(0.px, 10.px, 0.px, 26.px), fontSize: 14.5.px, lineHeight: 1.6.em, color: textMuted2),
    css('.gs-plan-desc--light').styles(color: textMuted),
    css('.gs-plan-cta', [
      css('&').styles(
        margin: .only(top: .auto),
        padding: .symmetric(vertical: 13.px, horizontal: 18.px),
        textAlign: .center,
        transition: Transition('all', duration: 200.ms),
        fontSize: 15.px,
        fontWeight: .w600,
      ),
    ]),
    css('.gs-plan-cta--outline', [
      css('&').styles(border: .all(color: border(.34), width: 1.px), color: accentLight),
      css('&:hover').styles(border: .all(color: accent, width: 1.px), backgroundColor: Color.rgba(56, 189, 248, .10), color: accent),
    ]),
    css('.gs-plan-cta--solid', [
      css('&').styles(backgroundColor: blue, border: .all(color: blue, width: 1.px), color: Colors.white),
      css('&:hover').styles(backgroundColor: blueDark, border: .all(color: blueDark, width: 1.px), color: Colors.white),
    ]),
    css('.gs-payment-card').styles(
      position: .relative(),
      padding: .fromLTRB(30.px, 34.px, 30.px, 36.px),
      border: .all(color: border(.20), width: 1.px),
      display: .flex,
      flexDirection: .column,
    ),
    css('.gs-payment-desc').styles(margin: .fromLTRB(0.px, 14.px, 0.px, 20.px), fontSize: 14.5.px, lineHeight: 1.6.em, color: textMuted2),
    css('.gs-payment-methods').styles(
      display: .flex,
      flexDirection: .column,
      gap: .all(1.px),
      backgroundColor: border(.16),
      border: .all(color: border(.16), width: 1.px),
      margin: .only(bottom: 20.px),
    ),
    css('.gs-payment-method').styles(padding: .symmetric(vertical: 12.px, horizontal: 14.px), backgroundColor: bg, fontSize: 14.px, fontWeight: .w600, color: ink),
    css('.gs-payment-footnote').styles(
      margin: .fromLTRB(0.px, .auto, 0.px, 0.px),
      fontFamily: monoFontFamily,
      fontSize: 10.5.px,
      lineHeight: 1.7.em,
      letterSpacing: .08.em,
      color: textMuted3,
    ),
    css('.gs-pricing-footnote').styles(
      margin: .fromLTRB(0.px, 22.px, 0.px, 0.px),
      fontFamily: monoFontFamily,
      fontSize: 10.5.px,
      letterSpacing: .10.em,
      color: textMuted3,
    ),
  ];
}
