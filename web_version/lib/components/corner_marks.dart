import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// Small decorative crosshair ticks at the four corners of a bordered box —
/// a recurring blueprint-style accent used throughout the design.
class CornerMarks extends StatelessComponent {
  final String color;

  const CornerMarks({required this.color, super.key});

  @override
  Component build(BuildContext context) {
    return div(
      classes: 'corner-marks',
      styles: Styles(raw: {'--mark-color': color}),
      [
        span(classes: 'tl', []),
        span(classes: 'tr', []),
        span(classes: 'bl', []),
        span(classes: 'br', []),
      ],
    );
  }

  @css
  static List<StyleRule> get styles => [
    css('.corner-marks', [
      css('span').styles(
        position: .absolute(),
        width: 9.px,
        height: 9.px,
        pointerEvents: .none,
        raw: {
          'background-image': 'linear-gradient(var(--mark-color),var(--mark-color)),'
              'linear-gradient(var(--mark-color),var(--mark-color))',
          'background-size': '9px 1px,1px 9px',
          'background-position': 'center,center',
          'background-repeat': 'no-repeat',
        },
      ),
      css('span.tl').styles(position: .absolute(top: (-5).px, left: (-5).px)),
      css('span.tr').styles(position: .absolute(top: (-5).px, right: (-5).px)),
      css('span.bl').styles(position: .absolute(bottom: (-5).px, left: (-5).px)),
      css('span.br').styles(position: .absolute(bottom: (-5).px, right: (-5).px)),
    ]),
  ];
}
