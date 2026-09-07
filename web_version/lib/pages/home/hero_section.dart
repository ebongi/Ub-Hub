import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../components/corner_marks.dart';
import '../../constants/content.dart';
import '../../constants/theme.dart';

class HeroSection extends StatelessComponent {
  const HeroSection({super.key});

  @override
  Component build(BuildContext context) {
    return section(id: 'top', classes: 'gs-hero', [
      span(classes: 'gs-hero-glow', []),
      div(classes: 'gs-hero-grid', [
        div(classes: 'gs-hero-copy', [
          div(classes: 'gs-hero-wordmark', [
            img(src: 'images/logo-mark.png', alt: 'G', classes: 'gs-logo-mark gs-logo-mark--hero'),
            span(classes: 'gs-hero-word', [.text('oStudy')]),
          ]),
          div(classes: 'gs-hero-kicker', [
            span(classes: 'gs-hero-rule', []),
            span(classes: 'gs-hero-kicker-text', [.text('BUILT FOR UNIVERSITY OF BUEA STUDENTS')]),
          ]),
          h1(classes: 'gs-hero-h1', [.text('Your Academic'), br(), .text('Companion')]),
          p(classes: 'gs-hero-p', [
            .text(
              'AI study help, your course materials offline, campus chat, exam planning and official transcript '
              'requests — all in one Android app made by UB students, for UB students.',
            ),
          ]),
          div(classes: 'gs-hero-cta-row', [
            a(href: playStoreUrl, classes: 'gs-play-btn', [
              span(classes: 'gs-play-btn-tag', [.text('ANDROID')]),
              span(classes: 'gs-play-btn-divider', []),
              span(classes: 'gs-play-btn-label', [.text('Get it on Google Play')]),
              const CornerMarks(color: 'rgba(255,255,255,.55)'),
            ]),
            div(classes: 'gs-hero-fine-print', [
              div([.text('FREE TO START')]),
              div([.text('MTN MOMO · ORANGE MONEY')]),
            ]),
          ]),
        ]),
        div(classes: 'gs-hero-mock-wrap', [
          div(classes: 'gs-hero-mock', [
            const CornerMarks(color: '#38BDF8'),
            div(classes: 'gs-hero-mock-tag', [.text('FIG. 01 — HOME')]),
            div(classes: 'gs-phone-frame', [
              div(classes: 'gs-phone-screen', [
                img(src: 'images/shot-home.png', alt: 'GoStudy home screen', classes: 'gs-phone-img'),
                span(classes: 'gs-phone-notch', []),
              ]),
            ]),
          ]),
        ]),
      ]),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    css('.gs-hero').styles(
      position: .relative(),
      padding: .fromLTRB(24.px, 88.px, 24.px, 72.px),
      border: .only(bottom: .solid(color: border(.18), width: 1.px)),
      raw: {
        'background-image':
            'radial-gradient(circle at 78% 18%, rgba(30,136,229,.30), transparent 46%),'
            'radial-gradient(circle at 12% 82%, rgba(56,189,248,.16), transparent 48%),'
            'linear-gradient(rgba(125,211,252,.055) 1px, transparent 1px),'
            'linear-gradient(90deg, rgba(125,211,252,.055) 1px, transparent 1px)',
        'background-size': 'auto,auto,44px 44px,44px 44px',
      },
    ),
    css('.gs-hero-glow').styles(
      position: .absolute(),
      pointerEvents: .none,
      raw: {
        'inset': '0',
        'animation': 'gs-glow 9s ease-in-out infinite',
        'background-image': 'radial-gradient(circle at 78% 18%, rgba(56,189,248,.20), transparent 42%)',
      },
    ),
    css('.gs-hero-grid').styles(
      position: .relative(),
      maxWidth: 1160.px,
      margin: .symmetric(horizontal: .auto),
      display: .grid,
      gridTemplate: autoFitGrid(300),
      gap: .all(56.px),
      alignItems: .center,
    ),
    css('.gs-hero-copy').styles(minWidth: 0.px),
    css('.gs-hero-wordmark').styles(display: .flex, alignItems: .end, margin: .only(bottom: 26.px)),
    css('.gs-logo-mark--hero').styles(height: 56.px, width: .auto, display: .block, margin: .only(bottom: (-6).px)),
    css('.gs-hero-word').styles(
      fontSize: 44.px,
      fontWeight: .w700,
      letterSpacing: (-.03).em,
      color: heading,
      lineHeight: 1.em,
      margin: .only(left: 2.px),
    ),
    css('.gs-hero-kicker').styles(display: .flex, alignItems: .center, gap: .all(10.px), margin: .only(bottom: 22.px)),
    css('.gs-hero-rule').styles(
      width: 22.px,
      height: 1.px,
      backgroundColor: accent,
      raw: {
        'transform-origin': 'left',
        'animation': 'gs-rule .9s .25s cubic-bezier(.22,.7,.24,1) both',
      },
    ),
    css('.gs-hero-kicker-text').styles(
      fontFamily: monoFontFamily,
      fontSize: 11.px,
      letterSpacing: .20.em,
      color: accentLight,
    ),
    css('.gs-hero-h1').styles(
      margin: .zero,
      fontSize: .expression('clamp(40px,5.6vw,68px)'),
      lineHeight: 1.02.em,
      fontWeight: .w800,
      letterSpacing: (-.028).em,
      color: heading,
    ),
    css('.gs-hero-p').styles(
      margin: .only(top: 24.px),
      maxWidth: ch(44),
      fontSize: 18.px,
      lineHeight: 1.6.em,
      color: textMuted,
    ),
    css('.gs-hero-cta-row').styles(
      margin: .only(top: 34.px),
      display: .flex,
      flexWrap: .wrap,
      gap: .all(14.px),
      alignItems: .center,
    ),
    css('.gs-play-btn', [
      css('&').styles(
        position: .relative(),
        display: .flex,
        alignItems: .center,
        gap: .all(14.px),
        padding: .symmetric(vertical: 15.px, horizontal: 26.px),
        transition: Transition('all', duration: 200.ms),
        backgroundColor: blue,
        border: .all(color: blue, width: 1.px),
        color: Colors.white,
      ),
      css('&:hover').styles(backgroundColor: blueDark, border: .all(color: blueDark, width: 1.px), color: Colors.white),
    ]),
    css('.gs-play-btn-tag').styles(
      fontFamily: monoFontFamily,
      fontSize: 10.px,
      letterSpacing: .18.em,
      opacity: .85,
    ),
    css('.gs-play-btn-divider').styles(width: 1.px, height: 22.px, backgroundColor: Color.rgba(255, 255, 255, .35)),
    css('.gs-play-btn-label').styles(fontSize: 16.px, fontWeight: .w600),
    css('.gs-hero-fine-print').styles(
      fontFamily: monoFontFamily,
      fontSize: 11.px,
      lineHeight: 1.7.em,
      letterSpacing: .06.em,
      color: textMuted3,
    ),
    css('.gs-hero-mock-wrap').styles(minWidth: 0.px, display: .flex, justifyContent: .center),
    css('.gs-hero-mock').styles(
      position: .relative(),
      padding: .all(16.px),
      border: .all(color: border(.30), width: 1.px),
      maxWidth: 330.px,
      width: 100.percent,
      raw: {'animation': 'gs-float 7.5s ease-in-out infinite'},
    ),
    css('.gs-hero-mock-tag').styles(
      position: .absolute(top: (-9).px, left: 16.px),
      padding: .symmetric(horizontal: 8.px),
      backgroundColor: bg,
      whiteSpace: .noWrap,
      fontFamily: monoFontFamily,
      fontSize: 10.px,
      letterSpacing: .16.em,
      color: accentLight,
    ),
    css('.gs-phone-frame').styles(
      padding: .all(10.px),
      backgroundColor: phoneBezel,
      border: .all(color: border(.34), width: 1.px),
      radius: .all(.circular(30.px)),
      shadow: BoxShadow.inset(offsetX: 0.px, offsetY: 0.px, spread: 1.px, color: border(.10)),
    ),
    css('.gs-phone-screen').styles(
      position: .relative(),
      radius: .all(.circular(22.px)),
      overflow: .hidden,
      backgroundColor: Colors.black,
    ),
    css('.gs-phone-img').styles(display: .block, width: 100.percent, height: .auto),
    css('.gs-phone-notch').styles(
      position: .absolute(top: 9.px, left: 50.percent),
      transform: .translate(x: (-50).percent),
      width: 52.px,
      height: 5.px,
      radius: .all(.circular(3.px)),
      backgroundColor: Color.rgba(8, 13, 24, .55),
    ),
  ];
}
