import 'dart:async';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_router/jaspr_router.dart';
import 'package:web/web.dart' as web;

import '../constants/content.dart';
import '../constants/theme.dart';

class Header extends StatefulComponent {
  const Header({super.key});

  @override
  State<Header> createState() => HeaderState();
}

class HeaderState extends State<Header> {
  bool _scrolled = false;
  StreamSubscription<web.Event>? _scrollSub;

  @override
  void initState() {
    super.initState();
    _scrollSub = web.EventStreamProviders.scrollEvent.forTarget(web.window).listen((_) {
      final scrolled = web.window.scrollY > 8;
      if (scrolled != _scrolled && mounted) setState(() => _scrolled = scrolled);
    });
  }

  @override
  void dispose() {
    _scrollSub?.cancel();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    return header(classes: _scrolled ? 'gs-header gs-header--scrolled' : 'gs-header', [
      div(classes: 'gs-header-inner', [
        Link(
          to: '/',
          classes: 'gs-logo',
          attributes: {'aria-label': 'GoStudy home'},
          child: .fragment([
            img(src: 'images/logo-mark.png', alt: 'G', classes: 'gs-logo-mark gs-logo-mark--header'),
            span(classes: 'gs-logo-word', [.text('oStudy')]),
          ]),
        ),
        nav(classes: 'gs-nav', [
          // Plain anchors (not the router's Link) so the browser handles
          // same-document hash scrolling natively, both from the home page
          // and when navigating in from another route.
          a(href: '/#features', classes: 'gs-nav-link', [.text('Features')]),
          a(href: '/#pricing', classes: 'gs-nav-link', [.text('Pricing')]),
          a(href: '/#support', classes: 'gs-nav-link', [.text('Support')]),
          a(href: playStoreUrl, classes: 'gs-nav-cta', [.text('Get the app')]),
        ]),
      ]),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    css('.gs-header', [
      css('&').styles(
        position: .sticky(top: 0.px),
        zIndex: ZIndex(40),
        backgroundColor: Color.rgba(15, 23, 42, .88),
        backdropFilter: .blur(10.px),
        border: .only(bottom: .solid(color: border(.18), width: 1.px)),
        transition: Transition.combine([
          Transition('border-color', duration: 300.ms),
          Transition('box-shadow', duration: 300.ms),
        ]),
      ),
    ]),
    css('.gs-header--scrolled').styles(
      border: .only(bottom: .solid(color: border(.30), width: 1.px)),
      shadow: BoxShadow(offsetX: 0.px, offsetY: 10.px, blur: 30.px, spread: (-18).px, color: Color.rgba(0, 0, 0, .9)),
    ),
    css('.gs-header-inner').styles(
      maxWidth: 1160.px,
      margin: .symmetric(horizontal: .auto),
      padding: .symmetric(vertical: 14.px, horizontal: 24.px),
      display: .flex,
      alignItems: .center,
      gap: .all(24.px),
    ),
    css('.gs-logo').styles(
      display: .flex,
      alignItems: .end,
      flex: Flex(grow: 0, shrink: 0),
    ),
    css('.gs-logo-mark--header').styles(height: 30.px, width: .auto, display: .block, margin: .only(bottom: (-3).px)),
    css('.gs-logo-word').styles(
      fontSize: 23.px,
      fontWeight: .w700,
      letterSpacing: (-.015).em,
      color: heading,
      lineHeight: 1.em,
      margin: .only(left: 1.px),
    ),
    css('.gs-nav').styles(
      margin: .only(left: .auto),
      display: .flex,
      alignItems: .center,
      gap: .all(6.px),
      flexWrap: .wrap,
      justifyContent: .end,
    ),
    css('.gs-nav-link', [
      css('&').styles(
        padding: .symmetric(vertical: 8.px, horizontal: 12.px),
        fontSize: 14.px,
        fontWeight: .w500,
        color: textMuted,
        transition: Transition.combine([
          Transition('color', duration: 180.ms),
          Transition('background', duration: 180.ms),
        ]),
      ),
      css('&:hover').styles(color: accent, backgroundColor: Color.rgba(56, 189, 248, .08)),
    ]),
    css('.gs-nav-cta', [
      css('&').styles(
        margin: .only(left: 8.px),
        padding: .symmetric(vertical: 10.px, horizontal: 16.px),
        backgroundColor: blue,
        color: Colors.white,
        fontSize: 14.px,
        fontWeight: .w600,
        border: .all(color: blue, width: 1.px),
        whiteSpace: .noWrap,
      ),
      css('&:hover').styles(backgroundColor: blueDark, border: .all(color: blueDark, width: 1.px), color: Colors.white),
    ]),
  ];
}
