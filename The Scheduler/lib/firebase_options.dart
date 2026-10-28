import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Supply your own Firebase client configuration with --dart-define-from-file.
/// See the repository CONFIGURATION.md. No project is configured by default.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    final FirebaseOptions options;
    if (kIsWeb) {
      options = web;
    } else {
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          options = android;
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
          options = ios;
        default:
          throw UnsupportedError('Configure Firebase for this platform first.');
      }
    }
    if (options.apiKey.isEmpty ||
        options.appId.isEmpty ||
        options.projectId.isEmpty ||
        options.messagingSenderId.isEmpty) {
      throw StateError(
        'Firebase is not configured. Supply your own FIREBASE_* build values.',
      );
    }
    return options;
  }

  static const web = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_API_KEY'),
    appId: String.fromEnvironment('FIREBASE_WEB_APP_ID'),
    messagingSenderId: String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID'),
    projectId: String.fromEnvironment('FIREBASE_PROJECT_ID'),
    authDomain: String.fromEnvironment('FIREBASE_AUTH_DOMAIN'),
    storageBucket: String.fromEnvironment('FIREBASE_STORAGE_BUCKET'),
    databaseURL: String.fromEnvironment('FIREBASE_DATABASE_URL'),
  );

  static const android = FirebaseOptions(
    apiKey: String.fromEnvironment(
      'FIREBASE_ANDROID_API_KEY',
      defaultValue: String.fromEnvironment('FIREBASE_API_KEY'),
    ),
    appId: String.fromEnvironment('FIREBASE_ANDROID_APP_ID'),
    messagingSenderId: String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID'),
    projectId: String.fromEnvironment('FIREBASE_PROJECT_ID'),
    storageBucket: String.fromEnvironment('FIREBASE_STORAGE_BUCKET'),
    databaseURL: String.fromEnvironment('FIREBASE_DATABASE_URL'),
  );

  static const ios = FirebaseOptions(
    apiKey: String.fromEnvironment(
      'FIREBASE_IOS_API_KEY',
      defaultValue: String.fromEnvironment('FIREBASE_API_KEY'),
    ),
    appId: String.fromEnvironment('FIREBASE_IOS_APP_ID'),
    messagingSenderId: String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID'),
    projectId: String.fromEnvironment('FIREBASE_PROJECT_ID'),
    storageBucket: String.fromEnvironment('FIREBASE_STORAGE_BUCKET'),
    databaseURL: String.fromEnvironment('FIREBASE_DATABASE_URL'),
    iosBundleId: String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID'),
    iosClientId: String.fromEnvironment('FIREBASE_IOS_CLIENT_ID'),
  );
}
