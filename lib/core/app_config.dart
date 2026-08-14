import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  // Gemini and Fapshi credentials are intentionally NOT read here anymore —
  // they live only in the gemini-proxy/fapshi-proxy Supabase Edge Function
  // secrets now. A client-side getter for them would just be an invitation
  // to reintroduce the exposure this was fixed to close.

  static String get firebaseApiKeyAndroid =>
      dotenv.env['FIREBASE_API_KEY_ANDROID'] ?? '';
  static String get firebaseAppIdAndroid =>
      dotenv.env['FIREBASE_APP_ID_ANDROID'] ?? '';

  static String get firebaseApiKeyIos =>
      dotenv.env['FIREBASE_API_KEY_IOS'] ?? '';
  static String get firebaseAppIdIos => dotenv.env['FIREBASE_APP_ID_IOS'] ?? '';

  static String get firebaseMessagingSenderId =>
      dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '';
  static String get firebaseProjectId =>
      dotenv.env['FIREBASE_PROJECT_ID'] ?? '';
  static String get firebaseStorageBucket =>
      dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '';

  static String get newsApiKey => dotenv.env['NEWS_API_KEY'] ?? '';

  static Future<void> init() async {
    await dotenv.load(fileName: ".env");
  }
}
