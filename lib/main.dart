import 'package:go_study/services/message_provider.dart';
import 'package:rive/rive.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_study/Screens/Shared/constanst.dart';
import 'package:go_study/Screens/authentication/wrap.dart';
import 'package:go_study/l10n/generated/app_localizations.dart';
import 'package:go_study/locale_provider.dart';
import 'package:go_study/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:go_study/core/supabase_config.dart';
import 'package:go_study/Screens/onboarding/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_study/core/app_config.dart';
import 'package:go_study/Screens/UI/preview/Navigation/splash_screen.dart';

import 'package:go_study/services/notification_service.dart';
import 'package:firebase_core/firebase_core.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Load environment variables FIRST
  await AppConfig.init();
  await RiveNative.init();
  // 2. Run remaining initializations in parallel
  final initResults = await Future.wait([
    sb.Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    ),
    SharedPreferences.getInstance(),
    Firebase.initializeApp().catchError((e) {
      debugPrint("Firebase initialization failed: $e");
      return Firebase.app(); // Return existing app if already initialized, or just fallback
    }),
  ]);

  // Initialize notifications without blocking the first frame
  NotificationService().init();

  final prefs = initResults[1] as SharedPreferences;
  final isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;
  final themeModeIndex = prefs.getInt('theme_mode');
  final initialThemeMode = themeModeIndex != null
      ? ThemeMode.values[themeModeIndex]
      : ThemeMode.system;

  final accentColorValue = prefs.getInt('accent_color');
  final initialAccentColor = accentColorValue != null
      ? Color(accentColorValue)
      : Colors.blue;

  final localeCode = prefs.getString('locale_language_code');
  final initialLocale = localeCode != null ? Locale(localeCode) : null;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MessageProvider()),
        ChangeNotifierProvider(create: (_) => UserModel()),
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(
            initialMode: initialThemeMode,
            initialColor: initialAccentColor,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => LocaleProvider(initialLocale: initialLocale),
        ),
        StreamProvider<sb.User?>(
          create: (_) => sb.Supabase.instance.client.auth.onAuthStateChange.map(
            (data) => data.session?.user,
          ),
          initialData: sb.Supabase.instance.client.auth.currentUser,
        ),
      ],
      child: MyApp(isFirstLaunch: isFirstLaunch),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool isFirstLaunch;
  const MyApp({super.key, required this.isFirstLaunch});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, LocaleProvider>(
      builder: (context, themeProvider, localeProvider, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: "GO Study",
          debugShowCheckedModeBanner: false,
          theme: themeProvider.lightTheme,
          darkTheme: themeProvider.darkTheme,
          themeMode: themeProvider.themeMode,
          locale: localeProvider.locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          routes: {
            '/auth': (context) => const AuthWrapper(),
            '/onboarding': (context) => const OnboardingScreen(),
          },
          home: SplashScreen(isFirstLaunch: isFirstLaunch),
        );
      },
    );
  }
}

class AppEntryPoint extends StatelessWidget {
  final bool isFirstLaunch;
  const AppEntryPoint({super.key, required this.isFirstLaunch});

  @override
  Widget build(BuildContext context) {
    if (isFirstLaunch) {
      // Pre-cache onboarding images for smoother experience
      _precacheImages(context);
      return const OnboardingScreen();
    }

    return const AuthWrapper();
  }

  void _precacheImages(BuildContext context) {
    const images = [
      'Learning-bro.png',
      'gpa_calc.png',
      'folder.png',
      'team_work.png',
    ];
    for (final image in images) {
      precacheImage(AssetImage('assets/images/$image'), context);
    }
  }
}
