import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:flutter/material.dart';
import 'package:neo/Screens/Shared/constanst.dart';
import 'package:neo/Screens/authentication/wrap.dart';
import 'package:neo/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:neo/core/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await sb.Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserModel()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        StreamProvider<sb.User?>(
          create: (_) => sb.Supabase.instance.client.auth.onAuthStateChange.map(
            (data) => data.session?.user,
          ),
          initialData: sb.Supabase.instance.client.auth.currentUser,
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: "Go Study",
          debugShowCheckedModeBanner: false,
          theme: themeProvider.lightTheme,
          darkTheme: themeProvider.darkTheme,
          themeMode: themeProvider.themeMode,
          home: const AuthWrapper(),
        );
      },
    );
  }
}
