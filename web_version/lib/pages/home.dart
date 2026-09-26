import 'package:jaspr/jaspr.dart';

import 'home/feature_strip_section.dart';
import 'home/features_section.dart';
import 'home/hero_section.dart';
import 'home/pricing_section.dart';
import 'home/screens_section.dart';
import 'home/support_section.dart';
import 'home/why_section.dart';

class Home extends StatelessComponent {
  const Home({super.key});

  @override
  Component build(BuildContext context) {
    return .fragment([
      const HeroSection(),
      const FeatureStripSection(),
      const ScreensSection(),
      const FeaturesSection(),
      const WhySection(),
      const PricingSection(),
      const SupportSection(),
    ]);
  }
}
