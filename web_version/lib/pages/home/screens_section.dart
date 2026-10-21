import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../components/corner_marks.dart';
import '../../components/reveal.dart';
import '../../constants/content.dart';
import '../../constants/theme.dart';

class ScreensSection extends StatefulComponent {
  const ScreensSection({super.key});

  @override
  State<ScreensSection> createState() => ScreensSectionState();
}

class ScreensSectionState extends State<ScreensSection> {
  int index = 0;
  int _direction = 1;

  void _go(int newIndex) {
    if (newIndex == index) return;
    final last = shots.length - 1;
    final wrappedForward = index == last && newIndex == 0;
    setState(() {
      _direction = (newIndex > index || wrappedForward) ? 1 : -1;
      index = newIndex;
    });
  }

  void _prev() => _go((index - 1 + shots.length) % shots.length);
  void _next() => _go((index + 1) % shots.length);
  void _pick(int i) => _go(i);

  @override
  Component build(BuildContext context) {
    final current = shots[index];

    return section(classes: 'gs-screens', [
      div(classes: 'gs-container', [
        div(classes: 'gs-screens-head', [
          div([
            div(classes: 'gs-eyebrow', [.text('SCREENS')]),
            h2(classes: 'gs-h2', [.text('A look inside the app')]),
          ]),
          div(classes: 'gs-screens-arrows', [
            button(
              onClick: _prev,
              attributes: {'aria-label': 'Previous screen'},
              classes: 'gs-arrow-btn',
              [.text('←')],
            ),
            button(
              onClick: _next,
              attributes: {'aria-label': 'Next screen'},
              classes: 'gs-arrow-btn',
              [.text('→')],
            ),
          ]),
        ]),
        div(classes: 'gs-screens-grid', [
          Reveal(classes: 'gs-screens-mock-wrap', children: [
            div(classes: 'gs-screens-mock', [
              const CornerMarks(color: '#38BDF8'),
              div(classes: 'gs-phone-frame', [
                div(classes: 'gs-phone-screen', [
                  img(
                    key: ValueKey(index),
                    src: current.src,
                    alt: current.title,
                    classes: _direction == 1 ? 'gs-phone-img gs-phone-img--in-right' : 'gs-phone-img gs-phone-img--in-left',
                  ),
                  span(classes: 'gs-phone-notch', []),
                ]),
              ]),
            ]),
          ]),
          Reveal(classes: 'gs-screens-copy', children: [
            div(classes: 'gs-screens-fig', [.text('FIG. ${current.n}')]),
            h3(classes: 'gs-screens-title', [.text(current.title)]),
            p(classes: 'gs-screens-body', [.text(current.body)]),
            div(
              classes: 'gs-screens-tabs',
              [
                for (var i = 0; i < shots.length; i++)
                  button(
                    onClick: () => _pick(i),
                    classes: i == index ? 'gs-tab gs-tab--active' : 'gs-tab',
                    [.text(shots[i].tab)],
                  ),
              ],
            ),
          ]),
        ]),
      ]),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    css('.gs-screens').styles(padding: .symmetric(vertical: 84.px, horizontal: 24.px), border: .only(bottom: .solid(color: border(.18), width: 1.px))),
    css('.gs-screens-head').styles(
      display: .flex,
      flexWrap: .wrap,
      gap: .all(18.px),
      alignItems: .baseline,
      justifyContent: .spaceBetween,
      margin: .only(bottom: 44.px),
    ),
    css('.gs-screens-arrows').styles(display: .flex, gap: .all(8.px)),
    css('.gs-arrow-btn', [
      css('&').styles(
        width: 44.px,
        height: 44.px,
        backgroundColor: Colors.transparent,
        border: .all(color: border(.30), width: 1.px),
        color: accentLight,
        fontSize: 18.px,
        cursor: .pointer,
        fontFamily: fontFamily,
        transition: Transition('all', duration: 180.ms),
      ),
      css('&:hover').styles(
        backgroundColor: Color.rgba(56, 189, 248, .10),
        border: .all(color: accent, width: 1.px),
        color: accent,
      ),
    ]),
    css('.gs-screens-grid').styles(
      display: .grid,
      gridTemplate: autoFitGrid(280),
      gap: .all(48.px),
      alignItems: .center,
    ),
    css('.gs-screens-mock-wrap').styles(minWidth: 0.px, display: .flex, justifyContent: .center),
    css('.gs-phone-img--in-right').styles(raw: {'animation': 'gs-shot-in-right .46s cubic-bezier(.22,.7,.24,1) both'}),
    css('.gs-phone-img--in-left').styles(raw: {'animation': 'gs-shot-in-left .46s cubic-bezier(.22,.7,.24,1) both'}),
    css('.gs-screens-mock').styles(
      position: .relative(),
      padding: .all(16.px),
      border: .all(color: border(.30), width: 1.px),
      maxWidth: 320.px,
      width: 100.percent,
    ),
    css('.gs-screens-copy').styles(minWidth: 0.px),
    css('.gs-screens-fig').styles(fontFamily: monoFontFamily, fontSize: 11.px, letterSpacing: .18.em, color: accent, margin: .only(bottom: 14.px)),
    css('.gs-screens-title').styles(margin: .zero, fontSize: 26.px, fontWeight: .w700, letterSpacing: (-.015).em, color: heading),
    css('.gs-screens-body').styles(margin: .fromLTRB(0.px, 14.px, 0.px, 0.px), maxWidth: ch(46), fontSize: 16.px, lineHeight: 1.65.em, color: textMuted),
    css('.gs-screens-tabs').styles(margin: .only(top: 32.px), display: .flex, flexWrap: .wrap, gap: .all(8.px)),
    css('.gs-tab', [
      css('&').styles(
        padding: .symmetric(vertical: 8.px, horizontal: 12.px),
        backgroundColor: Colors.transparent,
        border: .all(color: border(.22), width: 1.px),
        color: textMuted2,
        fontFamily: monoFontFamily,
        fontSize: 10.px,
        letterSpacing: .12.em,
        cursor: .pointer,
        transition: Transition('all', duration: 180.ms),
      ),
      css('&:hover').styles(
        backgroundColor: Color.rgba(56, 189, 248, .10),
        border: .all(color: accent, width: 1.px),
        color: accent,
      ),
    ]),
    css('.gs-tab--active').styles(
      backgroundColor: Color.rgba(56, 189, 248, .10),
      border: .all(color: accent, width: 1.px),
      color: accent,
    ),
  ];
}
