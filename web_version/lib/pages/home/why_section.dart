import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../components/corner_marks.dart';
import '../../constants/content.dart';
import '../../constants/theme.dart';

class WhySection extends StatelessComponent {
  const WhySection({super.key});

  @override
  Component build(BuildContext context) {
    return section(classes: 'gs-why', [
      div(classes: 'gs-container', [
        div(classes: 'gs-why-eyebrow', [.text('WHY GOSTUDY')]),
        h2(classes: 'gs-why-h2', [.text('Made for how UB actually works')]),
        div(classes: 'gs-why-grid', [for (final w in why) WhyCard(item: w)]),
      ]),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    css('.gs-why').styles(
      padding: .symmetric(vertical: 84.px, horizontal: 24.px),
      backgroundColor: surface,
      color: surfaceInk,
      border: .only(bottom: .solid(color: border(.18), width: 1.px)),
    ),
    css('.gs-why-eyebrow').styles(
      fontFamily: monoFontFamily,
      fontSize: 11.px,
      letterSpacing: .20.em,
      color: blueDark,
      margin: .only(bottom: 12.px),
    ),
    css('.gs-why-h2').styles(
      margin: .only(bottom: 48.px),
      fontSize: .expression('clamp(28px,3.4vw,40px)'),
      fontWeight: .w700,
      letterSpacing: (-.02).em,
      color: surfaceInk,
      maxWidth: ch(22),
    ),
    css('.gs-why-grid').styles(display: .grid, gridTemplate: autoFitGrid(230), gap: .all(28.px)),
  ];
}

class WhyCard extends StatelessComponent {
  final WhyItem item;
  const WhyCard({required this.item});

  @override
  Component build(BuildContext context) {
    return div(classes: 'gs-why-card', [
      const CornerMarks(color: '#1E88E5'),
      div(classes: 'gs-why-n', [.text(item.n)]),
      h3(classes: 'gs-why-title', [.text(item.title)]),
      p(classes: 'gs-why-body', [.text(item.body)]),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    css('.gs-why-card').styles(
      position: .relative(),
      padding: .fromLTRB(24.px, 28.px, 24.px, 30.px),
      border: .all(color: Color.rgba(15, 23, 42, .16), width: 1.px),
    ),
    css('.gs-why-n').styles(fontFamily: monoFontFamily, fontSize: 10.px, letterSpacing: .16.em, color: blueDark, margin: .only(bottom: 14.px)),
    css('.gs-why-title').styles(margin: .fromLTRB(0.px, 0.px, 0.px, 10.px), fontSize: 18.px, fontWeight: .w700, color: surfaceInk, lineHeight: 1.25.em),
    css('.gs-why-body').styles(margin: .zero, fontSize: 14.5.px, lineHeight: 1.6.em, color: surfaceMuted),
  ];
}
