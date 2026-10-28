import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'local_notification_service.dart';
import 'notification_content.dart';
import 'notification_preferences.dart';

/// Background message handler - must be top-level function.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background messages
  // Note: Cannot access UI or state from here
  debugPrint('Background message received');
}

/// Service for handling Firebase Cloud Messaging push notifications.
///
/// Manages FCM token registration, message handling, and notification display.
/// All notification content is HIPAA-compliant with no PHI.
class FCMService {
  FCMService._();
  static final FCMService instance = FCMService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _businessId;
  String? _staffId;
  String? _currentToken;
  StreamSubscription<String>? _tokenRefreshSubscription;

  /// Callback for when a notification is tapped.
  void Function(NotificationPayload payload)? onNotificationTapped;

  /// Initializes FCM service.
  ///
  /// [businessId] and [staffId] are required for token registration.
  Future<void> initialize({
    required String businessId,
    required String staffId,
  }) async {
    _businessId = businessId;
    _staffId = staffId;

    // Request permission
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('FCM: User denied notification permission');
      return;
    }

    // Get and register token
    _currentToken = await _messaging.getToken();
    await _registerToken(_currentToken);

    // Listen for token refresh
    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen(_registerToken);

    // Configure message handlers
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Check for initial message (app opened from terminated state)
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }

    debugPrint('FCM: Initialized');
  }

  /// Disposes resources.
  void dispose() {
    _tokenRefreshSubscription?.cancel();
  }

  /// Gets the current FCM token.
  String? get currentToken => _currentToken;

  /// Registers the FCM token with Firestore for this device.
  Future<void> _registerToken(String? token) async {
    if (token == null || _businessId == null || _staffId == null) return;

    _currentToken = token;

    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Store token in Firestore for this staff member's device
      await _firestore
          .collection('businesses')
          .doc(_businessId)
          .collection('staffDevices')
          .doc(_staffId)
          .collection('tokens')
          .doc(token)
          .set({
        'token': token,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'platform': defaultTargetPlatform.name,
        'userId': user.uid,
      }, SetOptions(merge: true));

      debugPrint('FCM: Token registered successfully');
    } catch (e) {
      debugPrint('FCM: Error registering token');
    }
  }

  /// Unregisters the current token (call on logout).
  Future<void> unregisterToken() async {
    if (_currentToken == null || _businessId == null || _staffId == null) return;

    try {
      await _firestore
          .collection('businesses')
          .doc(_businessId)
          .collection('staffDevices')
          .doc(_staffId)
          .collection('tokens')
          .doc(_currentToken)
          .delete();

      debugPrint('FCM: Token unregistered');
    } catch (e) {
      debugPrint('FCM: Error unregistering token');
    }
  }

  /// Handles messages received while app is in foreground.
  void _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('FCM: Foreground message received');

    final payload = _parsePayload(message);
    if (payload == null) return;

    // Check notification preferences
    final prefs = NotificationPreferences.instance;
    if (!await prefs.shouldShowNotification(payload.type)) {
      debugPrint('FCM: Notification suppressed by preferences');
      return;
    }

    // Show local notification
    final template = NotificationTemplates.getTemplate(payload.type);
    if (template != null) {
      await LocalNotificationService.instance.showNotification(
        title: message.notification?.title ?? template.title,
        body: message.notification?.body ?? template.body,
        payload: payload.toJsonString(),
        channelId: template.channelId,
        channelName: template.channelName,
      );
    }
  }

  /// Handles notification tap when app is opened from background.
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('FCM: App opened from notification');

    final payload = _parsePayload(message);
    if (payload != null) {
      onNotificationTapped?.call(payload);
    }
  }

  /// Parses notification payload from message.
  NotificationPayload? _parsePayload(RemoteMessage message) {
    try {
      final data = message.data;
      if (data.isEmpty) {
        // Try to infer type from notification content
        return const NotificationPayload(type: NotificationType.scheduleUpdate);
      }
      return NotificationPayload.fromMap(data);
    } catch (e) {
      debugPrint('FCM: Error parsing payload');
      return null;
    }
  }

  /// Subscribes to a topic for broadcast notifications.
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('FCM: Subscribed to topic');
    } catch (e) {
      debugPrint('FCM: Error subscribing to topic');
    }
  }

  /// Unsubscribes from a topic.
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('FCM: Unsubscribed from topic');
    } catch (e) {
      debugPrint('FCM: Error unsubscribing from topic');
    }
  }

  /// Gets the notification permission status.
  Future<AuthorizationStatus> getPermissionStatus() async {
    final settings = await _messaging.getNotificationSettings();
    return settings.authorizationStatus;
  }

  /// Requests notification permission.
  Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }
}
