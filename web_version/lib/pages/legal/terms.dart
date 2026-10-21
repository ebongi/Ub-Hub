import 'package:jaspr/jaspr.dart';

import '../../constants/content.dart';
import 'legal_shell.dart';

class TermsPage extends StatelessComponent {
  const TermsPage({super.key});

  @override
  Component build(BuildContext context) {
    return LegalShell(
      title: 'Terms of Service',
      intro: 'The linkable version of the terms shown in the app. Mirror the in-app text here so the two never drift apart.',
      draftNote: 'Paste the text from the in-app terms screen into the blocks below, then delete this note.',
      sections: termsSections,
      sectionPlaceholder: 'PASTE TERMS TEXT HERE',
    );
  }
}
