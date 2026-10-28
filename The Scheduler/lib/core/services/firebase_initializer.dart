import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../config/demo_config.dart';
import '../../firebase_options.dart';
import 'crashlytics_service.dart';
import 'notification_service.dart';

class FirebaseInitializer {
  const FirebaseInitializer();

  Future<void> initialize() async {
    try {
      // Check if Firebase is already initialized (e.g., by native code)
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DemoConfig.isDemoMode
              ? DemoConfig.firebaseOptions
              : DefaultFirebaseOptions.currentPlatform,
        );
      }

      // Keep launch-critical work small so a plugin cannot block the first frame.
      await _configureFirestore();
      if (!DemoConfig.isDemoMode) {
        await CrashlyticsService.initialize();
        unawaited(_initializeNotificationService());
      }

      debugPrint('Firebase launch-critical services initialized.');
    } on FirebaseException catch (e) {
      if (e.code == 'duplicate-app') {
        debugPrint('Firebase app already exists, continuing.');
        return;
      }
      debugPrint('Firebase initialization failed');
      rethrow;
    }
  }

  /// Configure Firestore settings for optimal performance and cost.
  Future<void> _configureFirestore() async {
    final firestore = FirebaseFirestore.instance;

    // Enable offline persistence with bounded cache size (100MB default)
    // This dramatically reduces reads by serving cached data first
    firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes:
          Settings.CACHE_SIZE_UNLIMITED, // Or use 100 * 1024 * 1024 for 100MB
    );

    debugPrint('Firestore configured with offline persistence enabled.');
  }

  Future<void> _initializeNotificationService() async {
    try {
      await NotificationService.initialize();
    } catch (e, stackTrace) {
      debugPrint(
        'NotificationService initialization failed asynchronously: $e',
      );
      debugPrint('$stackTrace');
    }
  }
}
