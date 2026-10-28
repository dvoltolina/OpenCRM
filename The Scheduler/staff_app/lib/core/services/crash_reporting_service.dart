// Crash Reporting & Analytics Service
//
// Provides crash reporting and analytics for the staff app.
// Integrates with Firebase Crashlytics and Analytics.
// HIPAA Note: Never log PHI or PII in crash reports.

import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Analytics event types.
enum AnalyticsEvent {
  /// App lifecycle events.
  appOpen,
  appBackground,
  appResume,

  /// Authentication events.
  login,
  logout,
  loginFailed,
  biometricAuthUsed,

  /// Time clock events.
  clockIn,
  clockOut,
  breakStart,
  breakEnd,

  /// Schedule events.
  scheduleViewed,
  appointmentViewed,
  appointmentAccepted,
  appointmentDeclined,

  /// Sync events.
  syncStarted,
  syncCompleted,
  syncFailed,
  conflictResolved,

  /// Settings events.
  settingsChanged,
  notificationToggled,
  themeChanged,

  /// Error events.
  errorOccurred,
  networkError,
  validationError,
}

/// User properties for analytics segmentation.
class UserProperties {
  const UserProperties({
    this.userId,
    this.businessId,
    this.role,
    this.appVersion,
    this.platform,
  });

  /// Anonymized user ID (not email or name).
  final String? userId;

  /// Business/tenant ID.
  final String? businessId;

  /// User role (staff, manager, etc.).
  final String? role;

  /// App version.
  final String? appVersion;

  /// Platform (iOS/Android).
  final String? platform;

  Map<String, String> toMap() {
    return {
      if (userId != null) 'user_id': userId!,
      if (businessId != null) 'business_id': businessId!,
      if (role != null) 'role': role!,
      if (appVersion != null) 'app_version': appVersion!,
      if (platform != null) 'platform': platform!,
    };
  }
}

/// Crash reporting and analytics service.
///
/// Usage:
/// ```dart
/// // Initialize at app start
/// await CrashReportingService.instance.initialize();
///
/// // Set user properties
/// CrashReportingService.instance.setUserProperties(UserProperties(
///   userId: 'anonymized_id',
///   businessId: 'business_123',
///   role: 'staff',
/// ));
///
/// // Log events
/// CrashReportingService.instance.logEvent(AnalyticsEvent.clockIn);
///
/// // Log errors
/// CrashReportingService.instance.recordError(error, stackTrace);
/// ```
class CrashReportingService {
  CrashReportingService._();
  static final CrashReportingService instance = CrashReportingService._();

  bool _initialized = false;

  /// Current user properties.
  UserProperties? _userProperties;

  /// Get current user properties.
  UserProperties? get userProperties => _userProperties;

  /// Whether the service is initialized.
  bool get isInitialized => _initialized;

  /// Firebase instances
  final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Whether crash reporting is enabled.
  bool _crashReportingEnabled = true;

  /// Whether analytics is enabled.
  bool _analyticsEnabled = true;

  /// Initialize the service.
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Disable collection in debug mode by default
      await _crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);
      await _analytics.setAnalyticsCollectionEnabled(!kDebugMode);

      // Set up Flutter error handling
      FlutterError.onError = (details) {
        _handleFlutterError(details);
      };

      // Set up platform error handling
      PlatformDispatcher.instance.onError = (error, stack) {
        _handlePlatformError(error, stack);
        return true;
      };

      _initialized = true;
      debugPrint('CrashReportingService: Initialized');
    } catch (e) {
      debugPrint('CrashReportingService: Failed to initialize: $e');
    }
  }

  /// Enable or disable crash reporting.
  Future<void> setCrashReportingEnabled(bool enabled) async {
    _crashReportingEnabled = enabled;
    await _crashlytics.setCrashlyticsCollectionEnabled(enabled);
    debugPrint('CrashReportingService: Crash reporting ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Enable or disable analytics.
  Future<void> setAnalyticsEnabled(bool enabled) async {
    _analyticsEnabled = enabled;
    await _analytics.setAnalyticsCollectionEnabled(enabled);
    debugPrint('CrashReportingService: Analytics ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Set user properties for analytics.
  ///
  /// IMPORTANT: Never include PHI or PII (names, emails, phone numbers).
  Future<void> setUserProperties(UserProperties properties) async {
    _userProperties = properties;

    // Set analytics user properties
    for (final entry in properties.toMap().entries) {
      await _analytics.setUserProperty(name: entry.key, value: entry.value);
    }

    // Set Crashlytics user identifier (anonymized)
    if (properties.userId != null) {
      await _crashlytics.setUserIdentifier(properties.userId!);
    }

    debugPrint('CrashReportingService: User properties set');
  }

  /// Clear user properties (e.g., on logout).
  Future<void> clearUserProperties() async {
    _userProperties = null;
    await _crashlytics.setUserIdentifier('');
    debugPrint('CrashReportingService: User properties cleared');
  }

  /// Log an analytics event.
  ///
  /// IMPORTANT: Never include PHI in event parameters.
  Future<void> logEvent(
    AnalyticsEvent event, {
    Map<String, dynamic>? parameters,
  }) async {
    if (!_analyticsEnabled) return;

    // Sanitize parameters to ensure no PHI
    final sanitizedParams = _sanitizeParameters(parameters);

    await _analytics.logEvent(
      name: event.name,
      parameters: sanitizedParams?.map(
        (k, v) => MapEntry(k, v is String ? v : v.toString()),
      ),
    );

    debugPrint('Analytics: ${event.name} ${sanitizedParams ?? ''}');
  }

  /// Log a screen view.
  Future<void> logScreenView(String screenName, {String? screenClass}) async {
    if (!_analyticsEnabled) return;

    await _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenClass,
    );

    debugPrint('Analytics: Screen view - $screenName');
  }

  /// Record a non-fatal error.
  ///
  /// IMPORTANT: Error messages are sanitized to remove potential PHI.
  Future<void> recordError(
    dynamic error,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
    Map<String, dynamic>? information,
  }) async {
    if (!_crashReportingEnabled) return;

    // Sanitize error message
    final sanitizedReason = _sanitizeErrorMessage(reason ?? error.toString());
    // Sanitize additional information
    final sanitizedInfo = _sanitizeParameters(information);

    await _crashlytics.recordError(
      error,
      stackTrace,
      reason: sanitizedReason,
      fatal: fatal,
      information: sanitizedInfo?.entries.map((e) => '${e.key}: ${e.value}').toList() ?? [],
    );

    debugPrint('CrashReporting: ${fatal ? 'FATAL' : 'Error'}: $sanitizedReason');
    if (stackTrace != null && kDebugMode) {
      debugPrint(stackTrace.toString());
    }
  }

  /// Log a custom message for debugging.
  void log(String message) {
    if (!_crashReportingEnabled) return;

    // Sanitize message
    final sanitized = _sanitizeErrorMessage(message);

    _crashlytics.log(sanitized);

    debugPrint('CrashReporting Log: $sanitized');
  }

  /// Set a custom key-value pair for crash context.
  Future<void> setCustomKey(String key, dynamic value) async {
    if (!_crashReportingEnabled) return;

    // Don't allow PHI-related keys
    if (_isPHIKey(key)) {
      debugPrint('CrashReporting: Blocked PHI key: $key');
      return;
    }

    await _crashlytics.setCustomKey(key, value.toString());
  }

  void _handleFlutterError(FlutterErrorDetails details) {
    recordError(
      details.exception,
      details.stack,
      reason: 'Flutter Error: ${details.summary}',
      fatal: false,
    );

    // In debug mode, also print to console
    if (kDebugMode) {
      FlutterError.dumpErrorToConsole(details);
    }
  }

  void _handlePlatformError(Object error, StackTrace stack) {
    recordError(
      error,
      stack,
      reason: 'Platform Error',
      fatal: true,
    );
  }

  /// Sanitize parameters to remove potential PHI.
  Map<String, dynamic>? _sanitizeParameters(Map<String, dynamic>? params) {
    if (params == null) return null;

    final sanitized = <String, dynamic>{};

    for (final entry in params.entries) {
      // Skip PHI keys
      if (_isPHIKey(entry.key)) continue;

      // Sanitize values
      var value = entry.value;
      if (value is String) {
        value = _sanitizeString(value);
      }

      sanitized[entry.key] = value;
    }

    return sanitized;
  }

  /// Check if a key might contain PHI.
  bool _isPHIKey(String key) {
    final lowerKey = key.toLowerCase();
    const phiKeywords = [
      'name',
      'email',
      'phone',
      'address',
      'ssn',
      'dob',
      'birth',
      'patient',
      'client',
      'diagnosis',
      'treatment',
      'medication',
      'health',
      'medical',
      'insurance',
    ];

    return phiKeywords.any((keyword) => lowerKey.contains(keyword));
  }

  /// Sanitize a string to remove potential PHI patterns.
  String _sanitizeString(String value) {
    // Remove email patterns
    var sanitized = value.replaceAll(
      RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}'),
      '[EMAIL]',
    );

    // Remove phone patterns
    sanitized = sanitized.replaceAll(
      RegExp(r'\b\d{3}[-.]?\d{3}[-.]?\d{4}\b'),
      '[PHONE]',
    );

    // Remove SSN patterns
    sanitized = sanitized.replaceAll(
      RegExp(r'\b\d{3}[-]?\d{2}[-]?\d{4}\b'),
      '[SSN]',
    );

    return sanitized;
  }

  /// Sanitize error messages.
  String _sanitizeErrorMessage(String message) {
    return _sanitizeString(message);
  }
}

/// Run a zone with error handling.
///
/// Use this to wrap your app's main function:
/// ```dart
/// void main() {
///   runWithCrashReporting(() async {
///     WidgetsFlutterBinding.ensureInitialized();
///     await CrashReportingService.instance.initialize();
///     runApp(const MyApp());
///   });
/// }
/// ```
Future<void> runWithCrashReporting(Future<void> Function() appMain) async {
  await runZonedGuarded(
    () async {
      await appMain();
    },
    (error, stack) {
      CrashReportingService.instance.recordError(
        error,
        stack,
        reason: 'Uncaught exception',
        fatal: true,
      );
    },
  );
}
