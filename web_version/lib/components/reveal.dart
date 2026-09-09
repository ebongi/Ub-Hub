import 'dart:async';
import 'dart:js_interop';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:web/web.dart' as web;

/// Fades + slides its children up into place the first time they scroll into
/// view, mirroring the design canvas's `data-reveal`/`data-stagger` behavior.
///
/// Renders as a single `div` (not an extra wrapper) so it can drop straight
/// into an existing grid/flex layout without disturbing sizing. When
/// [stagger] is true, direct children are revealed one after another via
/// CSS `:nth-child` delays instead of all at once.
class Reveal extends StatefulComponent {
  final String classes;
  final List<Component> children;
  final bool stagger;
  final int delayMs;

  const Reveal({
    required this.classes,
    required this.children,
    this.stagger = false,
    this.delayMs = 0,
    super.key,
  });

  @override
  State<Reveal> createState() => RevealState();
}

class RevealState extends State<Reveal> {
  final GlobalNodeKey<web.HTMLElement> _domKey = GlobalNodeKey();
  web.IntersectionObserver? _observer;
  bool _in = false;

  @override
  void initState() {
    super.initState();
    // Defer past the current DOM-attach pass so `_domKey.currentNode` is set.
    Timer.run(_setup);
  }

  void _setup() {
    final el = _domKey.currentNode;
    if (el == null || !mounted) return;
    _observer = web.IntersectionObserver(
      _onIntersect.toJS,
      web.IntersectionObserverInit(rootMargin: '0px 0px -8% 0px', threshold: 0.06.toJS),
    );
    _observer!.observe(el);
  }

  void _onIntersect(JSArray<web.IntersectionObserverEntry> entries, web.IntersectionObserver observer) {
    for (final entry in entries.toDart) {
      if (!entry.isIntersecting) continue;
      observer.unobserve(entry.target);
      if (component.delayMs == 0) {
        if (mounted) setState(() => _in = true);
      } else {
        Timer(Duration(milliseconds: component.delayMs), () {
          if (mounted) setState(() => _in = true);
        });
      }
    }
  }

  @override
  void dispose() {
    _observer?.disconnect();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    final base = component.stagger ? 'gs-stagger' : 'gs-reveal';
    final classes = _in ? '${component.classes} $base $base--in' : '${component.classes} $base';
    return div(key: _domKey, classes: classes, component.children);
  }
}
