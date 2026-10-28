import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

import 'notification_content.dart';

/// Service for displaying local notifications.
///
/// Handles both immediate and scheduled notifications with
/// platform-specific configuration for Android and iOS.
class LocalNotificationService {
  LocalNotificationService._();
  static final LocalNotificationService instance = LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  int _notificationId = 0;

  /// Callback for when a notification is tapped.
  void Function(NotificationPayload payload)? onNotificationTapped;

  /// Initializes the notification service.
  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone
    tz_data.initializeTimeZones();

    // Android settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    // Create notification channels for Android
    if (Platform.isAndroid) {
      await _createNotificationChannels();
    }

    _initialized = true;
    debugPrint('LocalNotifications: Initialized');
  }

  /// Creates Android notification channels.
  Future<void> _createNotificationChannels() async {
    final androidPlugin =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) return;

    // Schedule channel
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'schedule',
        'Schedule Updates',
        description: 'Notifications about schedule changes',
        importance: Importance.high,
      ),
    );

    // Reminders channel
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'reminders',
        'Reminders',
        description: 'Appointment and shift reminders',
        importance: Importance.max,
        playSound: true,
      ),
    );

    // Timesheet channel
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'timesheet',
        'Timesheet',
        description: 'Timesheet approval notifications',
        importance: Importance.high,
      ),
    );

    // System channel
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'system',
        'System',
        description: 'System notifications',
        importance: Importance.defaultImportance,
      ),
    );

    // Announcements channel
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'announcements',
        'Announcements',
        description: 'Admin announcements',
        importance: Importance.high,
      ),
    );
  }

  /// Handles notification tap response.
  void _onNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;

    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final notificationPayload = NotificationPayload.fromMap(data);
      onNotificationTapped?.call(notificationPayload);
    } catch (e) {
      debugPrint('LocalNotifications: Error parsing payload: $e');
    }
  }

  /// Shows an immediate notification.
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    String channelId = 'default',
    String channelName = 'General',
  }) async {
    final id = _getNextId();

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(id, title, body, details, payload: payload);
    debugPrint('LocalNotifications: Showed notification $id');
  }

  /// Schedules a notification for a specific time.
  Future<int> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
    String channelId = 'reminders',
    String channelName = 'Reminders',
  }) async {
    final id = _getNextId();

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tzScheduledTime,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );

    debugPrint('LocalNotifications: Scheduled notification $id for $scheduledTime');
    return id;
  }

  /// Cancels a specific notification.
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
    debugPrint('LocalNotifications: Cancelled notification $id');
  }

  /// Cancels all notifications.
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    debugPrint('LocalNotifications: Cancelled all notifications');
  }

  /// Gets all pending notifications.
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return _notifications.pendingNotificationRequests();
  }

  /// Requests notification permission (iOS).
  Future<bool> requestPermission() async {
    if (Platform.isIOS) {
      final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final granted = await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    if (Platform.isAndroid) {
      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await androidPlugin?.requestNotificationsPermission();
      return granted ?? false;
    }

    return true;
  }

  /// Checks if exact alarm permission is granted (Android 12+).
  Future<bool> checkExactAlarmPermission() async {
    if (!Platform.isAndroid) return true;

    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return await androidPlugin?.canScheduleExactNotifications() ?? false;
  }

  /// Gets the next notification ID.
  int _getNextId() {
    return _notificationId++;
  }

  /// Shows a notification from a template.
  Future<void> showFromTemplate({
    required NotificationTemplate template,
    NotificationPayload? payload,
  }) async {
    await showNotification(
      title: template.title,
      body: template.body,
      payload: payload?.toJsonString(),
      channelId: template.channelId,
      channelName: template.channelName,
    );
  }
}
