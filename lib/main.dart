import 'package:neo/services/message_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:flutter/material.dart';
import 'package:neo/Screens/Shared/constanst.dart';
import 'package:neo/Screens/authentication/wrap.dart';
import 'package:neo/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:neo/core/supabase_config.dart';
import 'package:neo/Screens/onboarding/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:neo/core/app_config.dart';
import 'package:neo/Screens/UI/preview/Navigation/splash_screen.dart';

import 'package:neo/services/notification_service.dart';

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
  ]);

  // Initialize notifications without blocking the first frame
  NotificationService().init();

  final prefs = initResults[1] as SharedPreferences;
  final isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MessageProvider()),
        ChangeNotifierProvider(create: (_) => UserModel()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
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
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: "Ub Studies",
          debugShowCheckedModeBanner: false,
          theme: themeProvider.lightTheme,
          darkTheme: themeProvider.darkTheme,
          themeMode: themeProvider.themeMode,
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
