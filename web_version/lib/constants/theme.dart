import 'package:jaspr/dom.dart';

// Brand palette — mirrors the app's dark theme and the store feature graphic.
const bg = Color('#0F172A');
const ink = Color('#E8EEF7');
const heading = Color('#F8FAFC');
const textMuted = Color('#A9BCD6');
const textMuted2 = Color('#8B9FBC');
const textMuted3 = Color('#6F86A6');
const accent = Color('#38BDF8');
const accentLight = Color('#7DD3FC');
const blue = Color('#1E88E5');
const blueDark = Color('#1565C0');
const surface = Color('#F8FAFC');
const surfaceInk = Color('#0F172A');
const surfaceMuted = Color('#475569');
const phoneBezel = Color('#080D18');

Color border(double a) => Color.rgba(125, 211, 252, a);

/// `grid-template-columns: repeat(auto-fit, minmax(minPx, 1fr))` — the responsive
/// card-grid pattern used throughout the design.
GridTemplate autoFitGrid(double minPx) => GridTemplate(
  columns: GridTracks([
    GridTrack.repeat(TrackRepeat.autoFit, [
      GridTrack(TrackSize.minmax(TrackSize(minPx.px), TrackSize.fr(1))),
    ]),
  ]),
);

/// The `ch` CSS unit (character width) — not covered by Jaspr's typed `Unit` extensions.
Unit ch(num n) => Unit.expression('${n}ch');

const fontFamily = FontFamily.list([FontFamily('Outfit'), FontFamilies.sansSerif]);
const monoFontFamily = FontFamily.list([
  FontFamilies.uiMonospace,
  FontFamily('Menlo'),
  FontFamilies.monospace,
]);

@css
List<StyleRule> get globalStyles => [
  css('html').styles(raw: {'scroll-behavior': 'smooth'}),
  css('body').styles(
    margin: .zero,
    backgroundColor: bg,
    color: ink,
    fontFamily: fontFamily,
    raw: {'-webkit-font-smoothing': 'antialiased'},
  ),
  css('*').styles(boxSizing: .borderBox),
  css('a').styles(color: accentLight, textDecoration: TextDecoration(line: .none)),
  css('a:hover').styles(color: accent),
  css('::selection').styles(backgroundColor: Color.rgba(56, 189, 248, .28)),
  css(':focus-visible').styles(
    outline: Outline(color: accent, style: .solid, width: OutlineWidth(2.px), offset: 2.px),
  ),

  css.keyframes('gs-float', {
    '0%, 100%': Styles(transform: .translate(y: 0.px)),
    '50%': Styles(transform: .translate(y: (-10).px)),
  }),
  css.keyframes('gs-glow', {
    '0%, 100%': Styles(opacity: .30),
    '50%': Styles(opacity: .62),
  }),
  css.keyframes('gs-rule', {
    'from': Styles(raw: {'transform': 'scaleX(0)'}),
    'to': Styles(raw: {'transform': 'scaleX(1)'}),
  }),
  css.keyframes('gs-page-in', {
    'from': Styles(opacity: 0, raw: {'transform': 'translateY(14px)'}),
    'to': Styles(opacity: 1, raw: {'transform': 'none'}),
  }),
  css.keyframes('gs-shot-in-right', {
    '0%': Styles(opacity: 0, raw: {'transform': 'translateX(22px) scale(.985)'}),
    '100%': Styles(opacity: 1, raw: {'transform': 'none'}),
  }),
  css.keyframes('gs-shot-in-left', {
    '0%': Styles(opacity: 0, raw: {'transform': 'translateX(-22px) scale(.985)'}),
    '100%': Styles(opacity: 1, raw: {'transform': 'none'}),
  }),

  // Scroll-reveal (see components/reveal.dart) — mirrors the design canvas's
  // data-reveal/data-stagger treatment.
  css('.gs-reveal').styles(
    opacity: 0,
    transform: .translate(y: 20.px),
    transition: Transition.combine([
      Transition('opacity', duration: 620.ms, curve: .cubicBezier(.22, .7, .24, 1)),
      Transition('transform', duration: 620.ms, curve: .cubicBezier(.22, .7, .24, 1)),
    ]),
  ),
  css('.gs-reveal--in').styles(opacity: 1, transform: .translate(y: 0.px)),
  css('.gs-stagger > *').styles(
    opacity: 0,
    transform: .translate(y: 20.px),
    transition: Transition.combine([
      Transition('opacity', duration: 620.ms, curve: .cubicBezier(.22, .7, .24, 1)),
      Transition('transform', duration: 620.ms, curve: .cubicBezier(.22, .7, .24, 1)),
    ]),
  ),
  for (var i = 1; i <= 8; i++)
    css('.gs-stagger > *:nth-child($i)').styles(raw: {'transition-delay': '${(i - 1) * 75}ms'}),
  css('.gs-stagger > *:nth-child(n+9)').styles(raw: {'transition-delay': '600ms'}),
  css('.gs-stagger--in > *').styles(opacity: 1, transform: .translate(y: 0.px)),

  css('.gs-page-transition').styles(
    raw: {'animation': 'gs-page-in .5s cubic-bezier(.22,.7,.24,1) both'},
  ),

  css.media(MediaQuery.raw('(prefers-reduced-motion: reduce)'), [
    css('*').styles(raw: {'animation': 'none !important', 'transition': 'none !important'}),
  ]),
];

/// Shared layout + typography utility classes reused across sections.
@css
List<StyleRule> get layoutStyles => [
  css('.gs-shell').styles(minHeight: 100.vh, backgroundColor: bg, overflow: .only(x: .hidden)),
  css('.gs-container').styles(maxWidth: 1160.px, margin: .symmetric(horizontal: .auto), padding: .symmetric(horizontal: 24.px)),
  css('.gs-eyebrow').styles(
    fontFamily: monoFontFamily,
    fontSize: 11.px,
    letterSpacing: .20.em,
    color: accentLight,
    margin: .only(bottom: 12.px),
  ),
  css('.gs-h2').styles(
    margin: .only(bottom: 16.px),
    fontSize: .expression('clamp(28px,3.4vw,40px)'),
    fontWeight: .w700,
    letterSpacing: (-.02).em,
    color: heading,
  ),
  css('.gs-lede').styles(
    margin: .only(bottom: 48.px),
    maxWidth: ch(56),
    fontSize: 17.px,
    lineHeight: 1.6.em,
    color: textMuted,
  ),
  css('.gs-section').styles(padding: .symmetric(vertical: 84.px, horizontal: 24.px), border: .only(bottom: .solid(color: border(.18), width: 1.px))),
];
