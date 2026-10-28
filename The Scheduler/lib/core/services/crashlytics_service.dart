import 'dart:async';
import 'dart:isolate';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import '../config/demo_config.dart';

/// Service for production error monitoring via Firebase Crashlytics.
///
/// Provides:
/// - Automatic crash reporting for uncaught exceptions
/// - Manual error logging with context
/// - User identification for crash reports
/// - Custom keys and logs for debugging
/// - Fatal vs non-fatal error distinction
///
/// Usage:
/// ```dart
/// // Initialize in bootstrap
/// await CrashlyticsService.initialize();
///
/// // Log non-fatal errors
/// CrashlyticsService.instance.recordError(
///   exception,
///   stackTrace,
///   reason: 'Failed to load appointments',
/// );
///
/// // Add context for debugging
/// CrashlyticsService.instance.setUserIdentifier(userId);
/// CrashlyticsService.instance.setCustomKey('businessId', businessId);
/// ```
class CrashlyticsService {
  CrashlyticsService._({FirebaseCrashlytics? crashlytics})
      : _crashlytics = crashlytics ?? FirebaseCrashlytics.instance;

  final FirebaseCrashlytics _crashlytics;

  static CrashlyticsService? _instance;

  /// Get the singleton instance.
  /// Throws if [initialize] hasn't been called.
  static CrashlyticsService get instance {
    if (_instance == null) {
      throw StateError(
        'CrashlyticsService not initialized. Call CrashlyticsService.initialize() first.',
      );
    }
    return _instance!;
  }

  /// Check if service is available (initialized and enabled).
  static bool get isAvailable => _instance != null;

  /// Initialize Crashlytics and set up global error handlers.
  ///
  /// Should be called early in app startup, after Firebase initialization.
  /// In debug mode, Crashlytics is disabled by default to avoid noise.
  ///
  /// Set [enableInDebug] to true to enable crash reporting in debug builds.
  static Future<void> initialize({
    bool enableInDebug = false,
    FirebaseCrashlytics? crashlytics,
  }) async {
    if (_instance != null) {
      debugPrint('CrashlyticsService already initialized');
      return;
    }

    final instance = CrashlyticsService._(crashlytics: crashlytics);
    _instance = instance;

    if (DemoConfig.isDemoMode) {
      await instance._crashlytics.setCrashlyticsCollectionEnabled(false);
      debugPrint('Crashlytics disabled in demo mode');
      return;
    }

    // Disable in debug mode unless explicitly enabled
    if (kDebugMode && !enableInDebug) {
      await instance._crashlytics.setCrashlyticsCollectionEnabled(false);
      debugPrint('Crashlytics disabled in debug mode');
      return;
    }

    // Enable crash collection
    await instance._crashlytics.setCrashlyticsCollectionEnabled(true);

    // Set up Flutter error handling
    FlutterError.onError = (errorDetails) {
      // Log to console in debug mode
      if (kDebugMode) {
        FlutterError.dumpErrorToConsole(errorDetails);
      }
      // Report to Crashlytics
      instance._crashlytics.recordFlutterFatalError(errorDetails);
    };

    // Handle errors in the current Isolate that aren't caught by Flutter
    PlatformDispatcher.instance.onError = (error, stack) {
      instance._crashlytics.recordError(error, stack, fatal: true);
      return true; // Handled
    };

    // Handle errors from other isolates
    Isolate.current.addErrorListener(RawReceivePort((pair) async {
      final List<dynamic> errorAndStacktrace = pair as List<dynamic>;
      await instance._crashlytics.recordError(
        errorAndStacktrace.first,
        errorAndStacktrace.last as StackTrace?,
        fatal: true,
      );
    }).sendPort);

    debugPrint('CrashlyticsService initialized');
  }

  /// Record a non-fatal error with optional context.
  ///
  /// Use this for errors that are caught and handled but should still
  /// be tracked for monitoring and debugging.
  ///
  /// Example:
  /// ```dart
  /// try {
  ///   await loadAppointments();
  /// } catch (e, stack) {
  ///   CrashlyticsService.instance.recordError(
  ///     e, stack,
  ///     reason: 'Failed to load appointments',
  ///     information: ['businessId: $businessId', 'userId: $userId'],
  ///   );
  ///   // Show user-friendly error message
  /// }
  /// ```
  Future<void> recordError(
    dynamic exception,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
    List<String>? information,
  }) async {
    if (DemoConfig.isDemoMode) {
      return;
    }
    // Log to console in debug mode
    if (kDebugMode) {
      debugPrint('Recording ${fatal ? 'fatal' : 'non-fatal'} error: $exception');
      if (reason != null) debugPrint('Reason: $reason');
      if (stackTrace != null) debugPrint('$stackTrace');
    }

    // Add contextual information as logs
    if (information != null) {
      for (final info in information) {
        await _crashlytics.log(info);
      }
    }

    if (reason != null) {
      await _crashlytics.log('Reason: $reason');
    }

    await _crashlytics.recordError(
      exception,
      stackTrace,
      reason: reason,
      fatal: fatal,
    );
  }

  /// Record a fatal error (app will likely crash).
  ///
  /// Use this for unrecoverable errors.
  Future<void> recordFatalError(
    dynamic exception,
    StackTrace? stackTrace, {
    String? reason,
  }) {
    return recordError(exception, stackTrace, reason: reason, fatal: true);
  }

  /// Set the user identifier for crash reports.
  ///
  /// Call this after user authentication. The identifier appears in
  /// Crashlytics console to help identify affected users.
  ///
  /// For privacy, consider using a non-PII identifier (user ID, not email).
  Future<void> setUserIdentifier(String userId) async {
    if (DemoConfig.isDemoMode) {
      return;
    }
    await _crashlytics.setUserIdentifier(userId);
    if (kDebugMode) {
      debugPrint('Crashlytics user identifier set: $userId');
    }
  }

  /// Clear the user identifier (e.g., on logout).
  Future<void> clearUserIdentifier() async {
    if (DemoConfig.isDemoMode) {
      return;
    }
    await _crashlytics.setUserIdentifier('');
    if (kDebugMode) {
      debugPrint('Crashlytics user identifier cleared');
    }
  }

  /// Set a custom key-value pair for crash reports.
  ///
  /// Custom keys appear in the Crashlytics console and help with debugging.
  /// Use for contextual information like:
  /// - businessId, providerId, clientId
  /// - Feature flags
  /// - App state (current screen, selected filters)
  ///
  /// Supports String, bool, int, and double values.
  Future<void> setCustomKey(String key, Object value) async {
    if (DemoConfig.isDemoMode) {
      return;
    }
    await _crashlytics.setCustomKey(key, value);
    if (kDebugMode) {
      debugPrint('Crashlytics custom key set: $key = $value');
    }
  }

  /// Set multiple custom keys at once.
  Future<void> setCustomKeys(Map<String, Object> keys) async {
    if (DemoConfig.isDemoMode) {
      return;
    }
    for (final entry in keys.entries) {
      await _crashlytics.setCustomKey(entry.key, entry.value);
    }
    if (kDebugMode) {
      debugPrint('Crashlytics custom keys set: $keys');
    }
  }

  /// Add a log message to the crash report.
  ///
  /// Logs are included in crash reports to show what happened before a crash.
  /// Keep logs concise - there's a limit on how many are retained.
  Future<void> log(String message) async {
    if (DemoConfig.isDemoMode) {
      return;
    }
    await _crashlytics.log(message);
    if (kDebugMode) {
      debugPrint('Crashlytics log: $message');
    }
  }

  /// Enable or disable crash collection.
  ///
  /// Can be used to implement a user preference for crash reporting.
  Future<void> setCrashlyticsCollectionEnabled(bool enabled) async {
    await _crashlytics.setCrashlyticsCollectionEnabled(enabled);
    debugPrint('Crashlytics collection ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Force a test crash (debug only).
  ///
  /// Use this to verify Crashlytics is working correctly.
  /// Only works in debug mode to prevent accidental production crashes.
  void testCrash() {
    if (kDebugMode) {
      debugPrint('Triggering test crash...');
      _crashlytics.crash();
    } else {
      debugPrint('Test crash ignored - only available in debug mode');
    }
  }

  /// Check if there are unsent crash reports.
  ///
  /// Returns true if there are reports from a previous session.
  Future<bool> checkForUnsentReports() {
    return _crashlytics.checkForUnsentReports();
  }

  /// Send any unsent crash reports.
  ///
  /// Call this if you want to manually trigger upload
  /// (normally happens automatically).
  Future<void> sendUnsentReports() {
    return _crashlytics.sendUnsentReports();
  }

  /// Delete any unsent crash reports.
  ///
  /// Use if user opts out of crash reporting.
  Future<void> deleteUnsentReports() {
    return _crashlytics.deleteUnsentReports();
  }
}

/// Extension methods for easier error recording with context.
extension CrashlyticsErrorRecording on Object {
  /// Record this exception to Crashlytics.
  ///
  /// Example:
  /// ```dart
  /// try {
  ///   await riskyOperation();
  /// } catch (e, stack) {
  ///   e.recordToCrashlytics(stack, reason: 'Risky operation failed');
  /// }
  /// ```
  Future<void> recordToCrashlytics(
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  }) async {
    if (CrashlyticsService.isAvailable) {
      await CrashlyticsService.instance.recordError(
        this,
        stackTrace,
        reason: reason,
        fatal: fatal,
      );
    }
  }
}
