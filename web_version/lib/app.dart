import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_router/jaspr_router.dart';

import 'components/footer.dart';
import 'components/header.dart';
import 'pages/home.dart';
import 'pages/legal/delete_account.dart';
import 'pages/legal/privacy.dart';
import 'pages/legal/terms.dart';

class App extends StatelessComponent {
  const App({super.key});

  @override
  Component build(BuildContext context) {
    return div(classes: 'gs-shell', [
      Router(routes: [
        ShellRoute(
          builder: (context, state, child) => .fragment([
            const Header(),
            // Keyed by path so navigating between routes remounts this
            // wrapper and replays the fade-up entrance animation.
            div(key: ValueKey(state.location), classes: 'gs-page-transition', [child]),
            const Footer(),
          ]),
          routes: [
            Route(path: '/', title: 'GoStudy — Your Academic Companion', builder: (context, state) => const Home()),
            Route(path: '/privacy', title: 'Privacy Policy — GoStudy', builder: (context, state) => const PrivacyPage()),
            Route(path: '/terms', title: 'Terms of Service — GoStudy', builder: (context, state) => const TermsPage()),
            Route(
              path: '/delete-account',
              title: 'Delete My Account — GoStudy',
              builder: (context, state) => const DeleteAccountPage(),
            ),
          ],
        ),
      ]),
    ]);
  }
}
