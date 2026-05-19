import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  static String get geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  static String get campayUsername => dotenv.env['CAMPAY_USERNAME'] ?? '';
  static String get campayPassword => dotenv.env['CAMPAY_PASSWORD'] ?? '';
  static String get campayToken => dotenv.env['CAMPAY_TOKEN'] ?? '';
  static String get campayEnv => dotenv.env['CAMPAY_ENV'] ?? 'sandbox';

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
