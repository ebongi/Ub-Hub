import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:go_study/services/gemma_model_manager.dart';
import 'package:go_study/services/message_provider.dart';
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
import 'package:go_study/firebase_options.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Load environment variables FIRST
  await AppConfig.init();
  // 2. Run remaining initializations in parallel
  final initResults = await Future.wait([
    sb.Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    ),
    SharedPreferences.getInstance(),
    Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).catchError((e) {
      debugPrint("Firebase initialization failed: $e");
      return Firebase.app(); // Return existing app if already initialized, or just fallback
    }),
  ]);

  // Initialize notifications without blocking the first frame
  NotificationService().init();

  // On-device AI (Gemma) is Android-only in Phase 1 — flutter_gemma needs
  // iOS 16+, this app's Podfile isn't set up for that yet. Registered here
  // (once, app-wide) so GemmaChatScreen's engine is ready the moment a user
  // opens it from the Toolbox, rather than registering lazily on first use.
  if (defaultTargetPlatform == TargetPlatform.android) {
    await GemmaModelManager().ensureEngineRegistered();
  }

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
          title: "GoStudy",
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
