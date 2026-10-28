import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../config/demo_config.dart';

/// Background message handler - must be a top-level function.
/// Called when app is in background or terminated.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized for background/terminated state
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }

  debugPrint('Background push message received');

  // Handle specific message types based on data payload
  final messageType = message.data['type'] as String?;
  switch (messageType) {
    case 'appointment_reminder':
    case 'appointment_cancelled':
    case 'appointment_rescheduled':
    case 'waitlist_available':
      // Background handling - could update local cache or schedule local notification
      break;
  }
}

/// Callback type for handling notification taps.
typedef NotificationTapCallback = void Function(RemoteMessage message);

/// Callback type for handling foreground messages.
typedef ForegroundMessageCallback = void Function(RemoteMessage message);

/// Service for handling Firebase Cloud Messaging (FCM) push notifications.
///
/// Usage:
/// ```dart
/// await NotificationService.initialize();
///
/// // Request permissions at a strategic moment
/// final granted = await NotificationService.instance.requestPermission();
///
/// // Listen to foreground messages
/// NotificationService.instance.onForegroundMessage((message) {
///   showInAppNotification(message);
/// });
/// ```
class NotificationService {
  NotificationService._({FirebaseMessaging? messaging})
    : _messaging = messaging ?? FirebaseMessaging.instance;

  static const Duration _initialMessageTimeout = Duration(seconds: 3);

  final FirebaseMessaging _messaging;

  static NotificationService? _instance;

  /// Get the singleton instance. Throws if not initialized.
  static NotificationService get instance {
    if (_instance == null) {
      throw StateError(
        'NotificationService not initialized. Call initialize() first.',
      );
    }
    return _instance!;
  }

  /// Check if service is available.
  static bool get isAvailable => _instance?._initialized ?? false;

  final List<ForegroundMessageCallback> _foregroundCallbacks = [];
  final List<NotificationTapCallback> _tapCallbacks = [];
  String? _token;
  bool _initialized = false;

  /// Get the current FCM token.
  String? get token => _token;

  /// Initialize the notification service.
  /// Does NOT request permissions - call [requestPermission] at a strategic moment.
  static Future<void> initialize({FirebaseMessaging? messaging}) async {
    if (_instance?._initialized ?? false) {
      debugPrint('NotificationService already initialized');
      return;
    }

    final service = NotificationService._(messaging: messaging);
    _instance = service;

    if (DemoConfig.isDemoMode) {
      service._initialized = true;
      debugPrint('NotificationService disabled in demo mode');
      return;
    }

    try {
      // Register background handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Set up message listeners (app-lifetime subscriptions, no need to cancel)
      FirebaseMessaging.onMessage.listen(service._handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(
        service._handleNotificationTap,
      );
      service._messaging.onTokenRefresh.listen(service._handleTokenRefresh);

      service._initialized = true;
      unawaited(service._dispatchInitialMessageIfNeeded());
      debugPrint('NotificationService initialized');
    } catch (e, stackTrace) {
      debugPrint('Failed to initialize NotificationService: $e');
      debugPrint('$stackTrace');
    }
  }

  /// Request notification permissions and get FCM token.
  /// Call this at a strategic moment (e.g., after onboarding, before first booking).
  /// Returns true if authorized.
  Future<bool> requestPermission({bool provisional = false}) async {
    if (DemoConfig.isDemoMode) {
      return false;
    }
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: provisional,
    );

    final authorized =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;

    if (authorized) {
      await _refreshToken();
    }

    return authorized;
  }

  /// Get the current notification permission status.
  Future<AuthorizationStatus> getPermissionStatus() async {
    final settings = await _messaging.getNotificationSettings();
    return settings.authorizationStatus;
  }

  /// Subscribe to a topic for broadcast notifications.
  ///
  /// Topics allow sending notifications to groups of users.
  /// Example topics: 'business_123', 'provider_456', 'all_users'
  Future<void> subscribeToTopic(String topic) async {
    if (DemoConfig.isDemoMode) {
      return;
    }
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('Subscribed to notification topic');
    } catch (e) {
      debugPrint('Failed to subscribe to notification topic');
    }
  }

  /// Unsubscribe from a topic.
  Future<void> unsubscribeFromTopic(String topic) async {
    if (DemoConfig.isDemoMode) {
      return;
    }
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from notification topic');
    } catch (e) {
      debugPrint('Failed to unsubscribe from notification topic');
    }
  }

  /// Register a callback for foreground messages.
  ///
  /// The callback will be called when a message is received while
  /// the app is in the foreground.
  void onForegroundMessage(ForegroundMessageCallback callback) {
    _foregroundCallbacks.add(callback);
  }

  /// Remove a foreground message callback.
  void removeForegroundMessageCallback(ForegroundMessageCallback callback) {
    _foregroundCallbacks.remove(callback);
  }

  /// Register a callback for notification taps.
  ///
  /// The callback will be called when the user taps on a notification
  /// to open the app (from background or terminated state).
  void onNotificationTap(NotificationTapCallback callback) {
    _tapCallbacks.add(callback);
  }

  /// Remove a notification tap callback.
  void removeNotificationTapCallback(NotificationTapCallback callback) {
    _tapCallbacks.remove(callback);
  }

  /// Get the FCM token for this device.
  /// Returns null if permissions were denied or token fetch failed.
  Future<String?> getToken() async {
    if (_token != null) return _token;
    await _refreshToken();
    return _token;
  }

  /// Delete the FCM token (e.g., on logout).
  Future<void> deleteToken() async {
    if (DemoConfig.isDemoMode) {
      _token = null;
      return;
    }
    await _messaging.deleteToken();
    _token = null;
  }

  // Private methods

  Future<void> _refreshToken() async {
    try {
      _token = await _messaging.getToken();
    } catch (e) {
      debugPrint('Failed to refresh FCM token');
    }
  }

  void _handleTokenRefresh(String newToken) {
    _token = newToken;
    // TODO: Update token in Firestore user document for server-side targeting
  }

  void _handleForegroundMessage(RemoteMessage message) {
    for (final callback in _foregroundCallbacks) {
      callback(message);
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    for (final callback in _tapCallbacks) {
      callback(message);
    }
  }

  Future<void> _dispatchInitialMessageIfNeeded() async {
    try {
      final initialMessage = await _messaging.getInitialMessage().timeout(
        _initialMessageTimeout,
        onTimeout: () {
          debugPrint('NotificationService initial message lookup timed out.');
          return null;
        },
      );

      if (initialMessage != null) {
        // Delay slightly so routing can attach listeners after app launch.
        Future.delayed(const Duration(milliseconds: 500), () {
          _handleNotificationTap(initialMessage);
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Failed to load initial notification message: $e');
      debugPrint('$stackTrace');
    }
  }
}

/// Extension to extract common data from notification messages.
extension RemoteMessageExtension on RemoteMessage {
  /// Get the notification type from the data payload.
  String? get notificationType => data['type'] as String?;

  /// Get the appointment ID if this notification is about an appointment.
  String? get appointmentId => data['appointmentId'] as String?;

  /// Get the business ID for routing.
  String? get businessId => data['businessId'] as String?;

  /// Get the client ID if applicable.
  String? get clientId => data['clientId'] as String?;

  /// Get the deep link URL if provided.
  String? get deepLink => data['deepLink'] as String?;
}
