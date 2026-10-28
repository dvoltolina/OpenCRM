import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app.dart';
import 'data/local/staff_database.dart';
import 'core/providers/database_provider.dart';

/// Entry point for the Staff App.
///
/// Initializes Firebase and the local Drift database before launching
/// the app within a [ProviderScope] for Riverpod state management.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize local SQLite database
  final database = StaffDatabase();

  // Set up global error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    // TODO: Log to crashlytics in production
  };

  runApp(
    ProviderScope(
      overrides: [
        // Override with initialized database instance
        databaseProvider.overrideWithValue(database),
      ],
      child: const StaffApp(),
    ),
  );
}
