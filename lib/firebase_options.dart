import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:neo/core/app_config.dart';

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static FirebaseOptions get web => FirebaseOptions(
    apiKey: AppConfig
        .firebaseApiKeyAndroid, // Using android as default for web if not specified
    appId: AppConfig.firebaseAppIdAndroid,
    messagingSenderId: AppConfig.firebaseMessagingSenderId,
    projectId: AppConfig.firebaseProjectId,
    authDomain: '${AppConfig.firebaseProjectId}.firebaseapp.com',
    storageBucket: AppConfig.firebaseStorageBucket,
  );

  static FirebaseOptions get android => FirebaseOptions(
    apiKey: AppConfig.firebaseApiKeyAndroid,
    appId: AppConfig.firebaseAppIdAndroid,
    messagingSenderId: AppConfig.firebaseMessagingSenderId,
    projectId: AppConfig.firebaseProjectId,
    storageBucket: AppConfig.firebaseStorageBucket,
  );

  static FirebaseOptions get ios => FirebaseOptions(
    apiKey: AppConfig.firebaseApiKeyIos,
    appId: AppConfig.firebaseAppIdIos,
    messagingSenderId: AppConfig.firebaseMessagingSenderId,
    projectId: AppConfig.firebaseProjectId,
    storageBucket: AppConfig.firebaseStorageBucket,
    iosBundleId: 'com.example.neo',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB7cN6j0FAMqKUua19Zi0pVyFb_nzAVZmM',
    appId: '1:734910045094:ios:699f1e59a6c1ec9b7d4d67',
    messagingSenderId: '734910045094',
    projectId: 'go-study-ub-hub',
    storageBucket: 'go-study-ub-hub.firebasestorage.app',
    iosBundleId: 'com.example.neo',
  );

  static FirebaseOptions get macos => FirebaseOptions(
    apiKey: AppConfig.firebaseApiKeyIos,
    appId: AppConfig.firebaseAppIdIos,
    messagingSenderId: AppConfig.firebaseMessagingSenderId,
    projectId: AppConfig.firebaseProjectId,
    storageBucket: AppConfig.firebaseStorageBucket,
    iosBundleId: 'com.example.neo',
  );

  static FirebaseOptions get windows => FirebaseOptions(
    apiKey: AppConfig.firebaseApiKeyAndroid,
    appId: AppConfig.firebaseAppIdAndroid,
    messagingSenderId: AppConfig.firebaseMessagingSenderId,
    projectId: AppConfig.firebaseProjectId,
    authDomain: '${AppConfig.firebaseProjectId}.firebaseapp.com',
    storageBucket: AppConfig.firebaseStorageBucket,
  );
}
