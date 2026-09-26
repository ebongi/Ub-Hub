import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../components/reveal.dart';
import '../../constants/content.dart';
import '../../constants/theme.dart';

class FeaturesSection extends StatelessComponent {
  const FeaturesSection({super.key});

  @override
  Component build(BuildContext context) {
    return section(id: 'features', classes: 'gs-section', [
      div(classes: 'gs-container', [
        div(classes: 'gs-eyebrow', [.text('FEATURES')]),
        h2(classes: 'gs-h2', [.text('Everything the semester needs')]),
        p(classes: 'gs-lede', [
          .text(
            'Six systems, one app. No juggling six different tools and a WhatsApp group that lost your lecture notes.',
          ),
        ]),
        Reveal(
          classes: 'gs-features-grid',
          stagger: true,
          children: [for (final f in features) FeatureCard(feature: f)],
        ),
      ]),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    css('.gs-features-grid').styles(
      display: .grid,
      gridTemplate: autoFitGrid(300),
      gap: .all(1.px),
      backgroundColor: border(.16),
      border: .all(color: border(.16), width: 1.px),
    ),
  ];
}

class FeatureCard extends StatelessComponent {
  final FeatureBlock feature;
  const FeatureCard({required this.feature});

  @override
  Component build(BuildContext context) {
    return div(classes: 'gs-feature-card', [
      div(classes: 'gs-feature-n', [.text(feature.n)]),
      h3(classes: 'gs-feature-title', [.text(feature.title)]),
      p(classes: 'gs-feature-body', [.text(feature.body)]),
      ul(
        classes: 'gs-feature-items',
        [for (final item in feature.items) li([span(classes: 'gs-feature-dot', []), span([.text(item)])])],
      ),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    css('.gs-feature-card', [
      css('&').styles(
        position: .relative(),
        padding: .fromLTRB(30.px, 34.px, 30.px, 36.px),
        backgroundColor: bg,
        transition: Transition.combine([
          Transition('transform', duration: 260.ms, curve: .cubicBezier(.22, .7, .24, 1)),
          Transition('background', duration: 260.ms),
        ]),
      ),
      css('&:hover').styles(
        transform: .translate(y: (-3).px),
        backgroundColor: Color.rgba(56, 189, 248, .04),
      ),
    ]),
    css('.gs-feature-n').styles(fontFamily: monoFontFamily, fontSize: 10.px, letterSpacing: .16.em, color: accent, margin: .only(bottom: 16.px)),
    css('.gs-feature-title').styles(margin: .fromLTRB(0.px, 0.px, 0.px, 12.px), fontSize: 21.px, fontWeight: .w700, letterSpacing: (-.012).em, color: heading),
    css('.gs-feature-body').styles(margin: .fromLTRB(0.px, 0.px, 0.px, 18.px), fontSize: 15.px, lineHeight: 1.62.em, color: textMuted),
    css('.gs-feature-items').styles(margin: .zero, padding: .zero, listStyle: .none, display: .flex, flexDirection: .column, gap: .all(7.px)),
    css('.gs-feature-items li').styles(display: .flex, gap: .all(10.px), fontSize: 13.5.px, lineHeight: 1.45.em, color: textMuted2),
    css('.gs-feature-dot').styles(
      flex: Flex(grow: 0, shrink: 0),
      margin: .only(top: 7.px),
      width: 5.px,
      height: 5.px,
      backgroundColor: accent,
    ),
  ];
}
