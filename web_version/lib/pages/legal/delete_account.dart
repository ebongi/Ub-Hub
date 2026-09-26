import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_router/jaspr_router.dart';

import '../../components/corner_marks.dart';
import '../../constants/content.dart';
import '../../constants/theme.dart';

class DeleteAccountPage extends StatelessComponent {
  const DeleteAccountPage({super.key});

  @override
  Component build(BuildContext context) {
    return main_(classes: 'gs-legal', [
      div(classes: 'gs-legal-container gs-delete-container', [
        Link(to: '/', classes: 'gs-legal-back', child: .text('← BACK TO HOME')),
        h1(classes: 'gs-legal-title', [.text('Delete My Account')]),
        p(classes: 'gs-delete-intro', [
          .text(
            'You can delete your GoStudy account and its data at any time, with or without the app installed. '
            'Pick whichever route applies to you.',
          ),
        ]),
        div(classes: 'gs-delete-routes', [
          div(classes: 'gs-route-card', [
            const CornerMarks(color: '#38BDF8'),
            div(classes: 'gs-route-tag', [.text('ROUTE A — IN THE APP')]),
            h2(classes: 'gs-route-title', [.text('Immediate and permanent')]),
            ol(classes: 'gs-route-steps', [
              DeleteStep(n: '01', child: .fragment([.text('Open GoStudy and go to '), strong([.text('Settings')])])),
              DeleteStep(n: '02', child: .fragment([.text('Tap '), strong([.text('Delete Account')])])),
              DeleteStep(
                n: '03',
                child: .text('Confirm. Your account and all associated data are deleted immediately and permanently.'),
              ),
            ]),
            p(classes: 'gs-route-footnote', [
              .text('There is no recovery window and no undo. Export anything you want to keep first.'),
            ]),
          ]),
          div(classes: 'gs-route-card', [
            const CornerMarks(color: '#38BDF8'),
            div(classes: 'gs-route-tag', [.text('ROUTE B — BY EMAIL')]),
            h2(classes: 'gs-route-title', [.text('No app installed?')]),
            p(classes: 'gs-route-body', [
              .text('Email us from — or naming — the address your account is registered to, with the subject '),
              strong([.text('Delete my account')]),
              .text(
                '. We verify ownership, then delete your account and all associated data within $deletionDays '
                'business days and confirm by reply.',
              ),
            ]),
            a(
              href: 'mailto:$supportEmail?subject=Delete%20my%20account',
              classes: 'gs-route-cta',
              [.text('Email a deletion request')],
            ),
            p(classes: 'gs-route-whatsapp', [
              .text('Or message '),
              a(href: whatsappUrl, [.text(whatsappNumber)]),
              .text(' on WhatsApp.'),
            ]),
          ]),
        ]),
        div(classes: 'gs-delete-lists', [
          div(classes: 'gs-delete-list-col', [
            h2(classes: 'gs-delete-list-title', [.text('What gets deleted')]),
            ul(classes: 'gs-delete-list', [
              for (final item in deletedOnAccountDeletion)
                li([span(classes: 'gs-dot gs-dot--accent', []), span([.text(item)])]),
            ]),
          ]),
          div(classes: 'gs-delete-list-col', [
            h2(classes: 'gs-delete-list-title', [.text('What we must keep')]),
            ul(classes: 'gs-delete-list', [
              for (final item in retainedOnAccountDeletion)
                li([span(classes: 'gs-dot gs-dot--light', []), span([.text(item)])]),
            ]),
            p(classes: 'gs-delete-retained-note', [
              .text(
                'These records are stripped of everything not required by law and are never used to contact '
                'you or rebuild your profile.',
              ),
            ]),
          ]),
        ]),
        p(classes: 'gs-delete-legal-note', [
          .text('RETENTION PERIODS AND LEGAL BASIS SHOULD BE CONFIRMED AGAINST YOUR FINAL PRIVACY POLICY BEFORE PUBLISHING.'),
        ]),
      ]),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    css('.gs-delete-container').styles(maxWidth: 840.px),
    css('.gs-delete-intro').styles(margin: .fromLTRB(0.px, 14.px, 0.px, 52.px), fontSize: 17.px, lineHeight: 1.65.em, color: textMuted, maxWidth: ch(62)),
    css('.gs-delete-routes').styles(display: .grid, gridTemplate: autoFitGrid(290), gap: .all(24.px), margin: .only(bottom: 56.px)),
    css('.gs-route-card').styles(position: .relative(), padding: .fromLTRB(32.px, 32.px, 32.px, 34.px), border: .all(color: border(.26), width: 1.px)),
    css('.gs-route-tag').styles(fontFamily: monoFontFamily, fontSize: 10.px, letterSpacing: .16.em, color: accentLight, margin: .only(bottom: 14.px)),
    css('.gs-route-title').styles(margin: .fromLTRB(0.px, 0.px, 0.px, 18.px), fontSize: 21.px, fontWeight: .w700, color: heading),
    css('.gs-route-steps').styles(margin: .fromLTRB(0.px, 0.px, 0.px, 20.px), padding: .zero, listStyle: .none, display: .flex, flexDirection: .column, gap: .all(12.px)),
    css('.gs-route-footnote').styles(margin: .zero, fontSize: 14.px, lineHeight: 1.6.em, color: textMuted2),
    css('.gs-route-body').styles(margin: .fromLTRB(0.px, 0.px, 0.px, 18.px), fontSize: 15.px, lineHeight: 1.6.em, color: Color('#C7D6E9')),
    css('.gs-route-cta', [
      css('&').styles(
        display: .inlineBlock,
        padding: .symmetric(vertical: 13.px, horizontal: 20.px),
        transition: Transition('all', duration: 200.ms),
        backgroundColor: blue,
        border: .all(color: blue, width: 1.px),
        color: Colors.white,
        fontSize: 15.px,
        fontWeight: .w600,
      ),
      css('&:hover').styles(backgroundColor: blueDark, border: .all(color: blueDark, width: 1.px), color: Colors.white),
    ]),
    css('.gs-route-whatsapp').styles(margin: .fromLTRB(0.px, 18.px, 0.px, 0.px), fontSize: 13.5.px, lineHeight: 1.6.em, color: textMuted2),
    css('.gs-delete-lists').styles(
      display: .grid,
      gridTemplate: autoFitGrid(280),
      gap: .all(1.px),
      backgroundColor: border(.16),
      border: .all(color: border(.16), width: 1.px),
      margin: .only(bottom: 44.px),
    ),
    css('.gs-delete-list-col').styles(padding: .symmetric(vertical: 30.px, horizontal: 26.px), backgroundColor: bg),
    css('.gs-delete-list-title').styles(margin: .fromLTRB(0.px, 0.px, 0.px, 18.px), fontSize: 19.px, fontWeight: .w700, color: heading),
    css('.gs-delete-list').styles(margin: .zero, padding: .zero, listStyle: .none, display: .flex, flexDirection: .column, gap: .all(9.px)),
    css('.gs-delete-list li').styles(display: .flex, gap: .all(10.px), fontSize: 14.5.px, lineHeight: 1.5.em, color: Color('#C7D6E9')),
    css('.gs-dot').styles(flex: Flex(grow: 0, shrink: 0), margin: .only(top: 7.px), width: 5.px, height: 5.px),
    css('.gs-dot--accent').styles(backgroundColor: accent),
    css('.gs-dot--light').styles(backgroundColor: accentLight),
    css('.gs-delete-retained-note').styles(margin: .fromLTRB(0.px, 18.px, 0.px, 0.px), fontSize: 13.5.px, lineHeight: 1.6.em, color: textMuted2),
    css('.gs-delete-legal-note').styles(margin: .zero, fontFamily: monoFontFamily, fontSize: 10.5.px, letterSpacing: .10.em, lineHeight: 1.8.em, color: textMuted3),
  ];
}

class DeleteStep extends StatelessComponent {
  final String n;
  final Component child;
  const DeleteStep({required this.n, required this.child});

  @override
  Component build(BuildContext context) {
    return li(classes: 'gs-step', [
      span(classes: 'gs-step-n', [.text(n)]),
      span([child]),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    css('.gs-step').styles(display: .flex, gap: .all(12.px), fontSize: 15.px, lineHeight: 1.5.em, color: Color('#C7D6E9')),
    css('.gs-step-n').styles(
      flex: Flex(grow: 0, shrink: 0),
      fontFamily: monoFontFamily,
      fontSize: 11.px,
      color: accent,
      padding: .only(top: 3.px),
    ),
  ];
}
