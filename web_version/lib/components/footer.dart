import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_router/jaspr_router.dart';

import '../constants/content.dart';
import '../constants/theme.dart';

class Footer extends StatelessComponent {
  const Footer({super.key});

  @override
  Component build(BuildContext context) {
    return footer(classes: 'gs-footer', [
      div(classes: 'gs-footer-grid', [
        div([
          div(classes: 'gs-footer-brand', [
            img(src: 'images/logo-mark.png', alt: 'G', classes: 'gs-logo-mark gs-logo-mark--footer'),
            span(classes: 'gs-logo-word gs-logo-word--footer', [.text('oStudy')]),
          ]),
          p(classes: 'gs-footer-tagline', [.text('Your Academic Companion. Built for University of Buea students.')]),
        ]),
        div([
          div(classes: 'gs-footer-heading', [.text('PRODUCT')]),
          div(classes: 'gs-footer-links', [
            a(href: '/#features', [.text('Features')]),
            a(href: '/#pricing', [.text('Pricing')]),
            a(href: '/#support', [.text('Support')]),
          ]),
        ]),
        div([
          div(classes: 'gs-footer-heading', [.text('LEGAL')]),
          div(classes: 'gs-footer-links', [
            Link(to: '/privacy', child: .text('Privacy Policy')),
            Link(to: '/terms', child: .text('Terms of Service')),
            Link(to: '/delete-account', child: .text('Delete My Account')),
          ]),
        ]),
        div([
          div(classes: 'gs-footer-heading', [.text('CONTACT')]),
          div(classes: 'gs-footer-links', [
            a(href: 'mailto:$supportEmail', classes: 'gs-footer-email', [.text(supportEmail)]),
            a(href: whatsappUrl, [.text('WhatsApp support')]),
          ]),
        ]),
      ]),
      div(classes: 'gs-footer-bottom', [
        span([.text('© 2026 GOSTUDY. ALL RIGHTS RESERVED.')]),
        span([.text(playLabel)]),
      ]),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    css('.gs-footer').styles(
      border: .only(top: .solid(color: border(.18), width: 1.px)),
      padding: .fromLTRB(24.px, 56.px, 24.px, 40.px),
    ),
    css('.gs-footer-grid').styles(
      maxWidth: 1160.px,
      margin: .symmetric(horizontal: .auto),
      display: .grid,
      gridTemplate: autoFitGrid(220),
      gap: .all(40.px),
    ),
    css('.gs-footer-brand').styles(display: .flex, alignItems: .end, margin: .only(bottom: 14.px)),
    css('.gs-logo-mark--footer').styles(height: 26.px, width: .auto, display: .block, margin: .only(bottom: (-3).px)),
    css('.gs-logo-word--footer').styles(fontSize: 20.px, margin: .only(left: 1.px)),
    css('.gs-footer-tagline').styles(margin: .zero, fontSize: 14.px, lineHeight: 1.6.em, color: textMuted2, maxWidth: ch(30)),
    css('.gs-footer-heading').styles(
      fontFamily: monoFontFamily,
      fontSize: 10.px,
      letterSpacing: .16.em,
      color: accentLight,
      margin: .only(bottom: 14.px),
    ),
    css('.gs-footer-links').styles(display: .flex, flexDirection: .column, gap: .all(9.px), fontSize: 14.5.px),
    css('.gs-footer-email').styles(raw: {'word-break': 'break-all'}),
    css('.gs-footer-bottom').styles(
      maxWidth: 1160.px,
      margin: .fromLTRB(.auto, 44.px, .auto, 0.px),
      padding: .only(top: 22.px),
      border: .only(top: .solid(color: border(.12), width: 1.px)),
      display: .flex,
      flexWrap: .wrap,
      gap: .all(12.px),
      justifyContent: .spaceBetween,
      fontFamily: monoFontFamily,
      fontSize: 10.5.px,
      letterSpacing: .10.em,
      color: textMuted3,
    ),
  ];
}
