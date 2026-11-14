import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../components/reveal.dart';
import '../../constants/content.dart';
import '../../constants/theme.dart';

class FeatureStripSection extends StatelessComponent {
  const FeatureStripSection({super.key});

  @override
  Component build(BuildContext context) {
    return section(classes: 'gs-strip', [
      div(classes: 'gs-container', [
        Reveal(
          classes: 'gs-strip-grid',
          stagger: true,
          children: [for (final item in strip) StripCell(item: item)],
        ),
      ]),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    css('.gs-strip').styles(padding: .zero, border: .only(bottom: .solid(color: border(.18), width: 1.px))),
    css('.gs-strip-grid').styles(display: .grid, gridTemplate: autoFitGrid(190)),
  ];
}

class StripCell extends StatelessComponent {
  final StripItem item;
  const StripCell({required this.item});

  @override
  Component build(BuildContext context) {
    return div(classes: 'gs-strip-cell', [
      div(classes: 'gs-strip-n', [.text(item.n)]),
      div(classes: 'gs-strip-title', [.text(item.title)]),
      div(classes: 'gs-strip-sub', [.text(item.sub)]),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    css('.gs-strip-cell').styles(
      padding: .fromLTRB(20.px, 26.px, 20.px, 28.px),
      border: .only(
        right: .solid(color: border(.14), width: 1.px),
        bottom: .solid(color: border(.08), width: 1.px),
      ),
    ),
    css('.gs-strip-n').styles(
      fontFamily: monoFontFamily,
      fontSize: 10.px,
      letterSpacing: .16.em,
      color: accent,
      margin: .only(bottom: 12.px),
    ),
    css('.gs-strip-title').styles(fontSize: 15.px, fontWeight: .w600, color: ink, lineHeight: 1.3.em),
    css('.gs-strip-sub').styles(margin: .only(top: 6.px), fontSize: 13.px, lineHeight: 1.5.em, color: textMuted2),
  ];
}
