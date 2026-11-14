import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_router/jaspr_router.dart';

import '../../constants/content.dart';
import '../../constants/theme.dart';
import 'legal_shell.dart';

class PrivacyPage extends StatelessComponent {
  const PrivacyPage({super.key});

  @override
  Component build(BuildContext context) {
    return LegalShell(
      title: 'Privacy Policy',
      intro:
          'This is the canonical, permanent home of the GoStudy privacy policy — the URL declared in the '
          'Google Play listing.',
      draftNote:
          'The section shells below are ready for your existing policy text. Paste each block in and delete '
          'this note. The third-party table is pre-filled to match your Play Console Data Safety declaration.',
      sections: privacySections,
      sectionPlaceholder: 'PASTE POLICY TEXT HERE',
      trailing: [
        section(classes: 'gs-legal-section', [
          div(classes: 'gs-legal-section-head', [
            span(classes: 'gs-legal-section-n', [.text('08')]),
            h2(classes: 'gs-legal-section-title', [.text('Third-party services we use')]),
          ]),
          p(classes: 'gs-legal-section-hint gs-processors-hint', [
            .text('These are the only external processors GoStudy sends data to, and what each one receives.'),
          ]),
          div(
            classes: 'gs-processors-table',
            [
              for (final p in processors)
                div(classes: 'gs-processor-row', [
                  div(classes: 'gs-processor-name', [.text(p.name)]),
                  div(classes: 'gs-processor-role', [.text(p.role)]),
                ]),
            ],
          ),
        ]),
        section([
          div(classes: 'gs-legal-section-head', [
            span(classes: 'gs-legal-section-n', [.text('09')]),
            h2(classes: 'gs-legal-section-title', [.text('Contact')]),
          ]),
          p(classes: 'gs-legal-contact-p', [
            .text('Questions about this policy, or a request to access or delete your data: '),
            a(href: 'mailto:$supportEmail', [.text(supportEmail)]),
            .text('. To delete your account, see '),
            Link(to: '/delete-account', child: .text('Delete My Account')),
            .text('.'),
          ]),
        ]),
      ],
    );
  }

  @css
  static List<StyleRule> get styles => [
    css('.gs-processors-hint').styles(margin: .fromLTRB(0.px, 0.px, 0.px, 20.px), maxWidth: ch(62)),
    css('.gs-processors-table').styles(
      display: .flex,
      flexDirection: .column,
      gap: .all(1.px),
      backgroundColor: border(.16),
      border: .all(color: border(.16), width: 1.px),
    ),
    css('.gs-processor-row').styles(
      padding: .symmetric(vertical: 18.px, horizontal: 20.px),
      backgroundColor: bg,
      display: .grid,
      gridTemplate: autoFitGrid(180),
      gap: Gap(row: 8.px, column: 24.px),
      alignItems: .baseline,
    ),
    css('.gs-processor-name').styles(fontSize: 16.px, fontWeight: .w700, color: heading),
    css('.gs-processor-role').styles(fontSize: 14.px, lineHeight: 1.55.em, color: textMuted),
    css('.gs-legal-contact-p').styles(margin: .zero, fontSize: 15.px, lineHeight: 1.7.em, color: textMuted, maxWidth: ch(62)),
  ];
}
