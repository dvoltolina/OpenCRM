import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'fcm_service.dart';
import 'local_notification_service.dart';
import 'notification_content.dart';
import 'notification_preferences.dart';
import 'reminder_service.dart';

// Service Providers

/// Provider for the FCM service singleton.
final fcmServiceProvider = Provider<FCMService>((ref) {
  return FCMService.instance;
});

/// Provider for the local notification service singleton.
final localNotificationServiceProvider = Provider<LocalNotificationService>((ref) {
  return LocalNotificationService.instance;
});

/// Provider for notification preferences singleton.
final notificationPreferencesProvider = Provider<NotificationPreferences>((ref) {
  return NotificationPreferences.instance;
});

/// Provider for the reminder service singleton.
final reminderServiceProvider = Provider<ReminderService>((ref) {
  return ReminderService.instance;
});

// Preference State Providers

/// Provider for schedule updates notification preference.
final scheduleUpdatesEnabledProvider = StateProvider<bool>((ref) {
  return NotificationPreferences.instance.scheduleUpdatesEnabled;
});

/// Provider for new appointments notification preference.
final newAppointmentsEnabledProvider = StateProvider<bool>((ref) {
  return NotificationPreferences.instance.newAppointmentsEnabled;
});

/// Provider for cancellations notification preference.
final cancellationsEnabledProvider = StateProvider<bool>((ref) {
  return NotificationPreferences.instance.cancellationsEnabled;
});

/// Provider for reminders notification preference.
final remindersEnabledProvider = StateProvider<bool>((ref) {
  return NotificationPreferences.instance.remindersEnabled;
});

/// Provider for timesheet status notification preference.
final timesheetStatusEnabledProvider = StateProvider<bool>((ref) {
  return NotificationPreferences.instance.timesheetStatusEnabled;
});

/// Provider for announcements notification preference.
final announcementsEnabledProvider = StateProvider<bool>((ref) {
  return NotificationPreferences.instance.announcementsEnabled;
});

/// Provider for quiet hours enabled preference.
final quietHoursEnabledProvider = StateProvider<bool>((ref) {
  return NotificationPreferences.instance.quietHoursEnabled;
});

/// Provider for quiet hours start time.
final quietHoursStartProvider = StateProvider<TimeOfDay>((ref) {
  return NotificationPreferences.instance.quietHoursStart;
});

/// Provider for quiet hours end time.
final quietHoursEndProvider = StateProvider<TimeOfDay>((ref) {
  return NotificationPreferences.instance.quietHoursEnd;
});

/// Provider for 1-hour reminder enabled preference.
final reminder1HourEnabledProvider = StateProvider<bool>((ref) {
  return NotificationPreferences.instance.reminder1HourEnabled;
});

/// Provider for 15-minute reminder enabled preference.
final reminder15MinEnabledProvider = StateProvider<bool>((ref) {
  return NotificationPreferences.instance.reminder15MinEnabled;
});

// Action Providers

/// Provider for updating schedule updates preference.
final updateScheduleUpdatesProvider = Provider<Future<void> Function(bool)>((ref) {
  return (bool enabled) async {
    await NotificationPreferences.instance.setScheduleUpdatesEnabled(enabled);
    ref.read(scheduleUpdatesEnabledProvider.notifier).state = enabled;
  };
});

/// Provider for updating new appointments preference.
final updateNewAppointmentsProvider = Provider<Future<void> Function(bool)>((ref) {
  return (bool enabled) async {
    await NotificationPreferences.instance.setNewAppointmentsEnabled(enabled);
    ref.read(newAppointmentsEnabledProvider.notifier).state = enabled;
  };
});

/// Provider for updating cancellations preference.
final updateCancellationsProvider = Provider<Future<void> Function(bool)>((ref) {
  return (bool enabled) async {
    await NotificationPreferences.instance.setCancellationsEnabled(enabled);
    ref.read(cancellationsEnabledProvider.notifier).state = enabled;
  };
});

/// Provider for updating reminders preference.
final updateRemindersProvider = Provider<Future<void> Function(bool)>((ref) {
  return (bool enabled) async {
    await NotificationPreferences.instance.setRemindersEnabled(enabled);
    ref.read(remindersEnabledProvider.notifier).state = enabled;
    // Update scheduled reminders when preference changes
    if (!enabled) {
      await ReminderService.instance.cancelAllReminders();
    }
  };
});

/// Provider for updating timesheet status preference.
final updateTimesheetStatusProvider = Provider<Future<void> Function(bool)>((ref) {
  return (bool enabled) async {
    await NotificationPreferences.instance.setTimesheetStatusEnabled(enabled);
    ref.read(timesheetStatusEnabledProvider.notifier).state = enabled;
  };
});

/// Provider for updating announcements preference.
final updateAnnouncementsProvider = Provider<Future<void> Function(bool)>((ref) {
  return (bool enabled) async {
    await NotificationPreferences.instance.setAnnouncementsEnabled(enabled);
    ref.read(announcementsEnabledProvider.notifier).state = enabled;
  };
});

/// Provider for updating quiet hours enabled preference.
final updateQuietHoursEnabledProvider = Provider<Future<void> Function(bool)>((ref) {
  return (bool enabled) async {
    await NotificationPreferences.instance.setQuietHoursEnabled(enabled);
    ref.read(quietHoursEnabledProvider.notifier).state = enabled;
  };
});

/// Provider for updating quiet hours start time.
final updateQuietHoursStartProvider = Provider<Future<void> Function(TimeOfDay)>((ref) {
  return (TimeOfDay time) async {
    await NotificationPreferences.instance.setQuietHoursStart(time);
    ref.read(quietHoursStartProvider.notifier).state = time;
  };
});

/// Provider for updating quiet hours end time.
final updateQuietHoursEndProvider = Provider<Future<void> Function(TimeOfDay)>((ref) {
  return (TimeOfDay time) async {
    await NotificationPreferences.instance.setQuietHoursEnd(time);
    ref.read(quietHoursEndProvider.notifier).state = time;
  };
});

/// Provider for updating 1-hour reminder preference.
final updateReminder1HourProvider = Provider<Future<void> Function(bool)>((ref) {
  return (bool enabled) async {
    await NotificationPreferences.instance.setReminder1HourEnabled(enabled);
    ref.read(reminder1HourEnabledProvider.notifier).state = enabled;
  };
});

/// Provider for updating 15-minute reminder preference.
final updateReminder15MinProvider = Provider<Future<void> Function(bool)>((ref) {
  return (bool enabled) async {
    await NotificationPreferences.instance.setReminder15MinEnabled(enabled);
    ref.read(reminder15MinEnabledProvider.notifier).state = enabled;
  };
});

// Initialization Provider

/// Provider that initializes all notification services.
///
/// Call this after authentication with the user's business and staff IDs.
final initializeNotificationsProvider =
    FutureProvider.family<void, ({String businessId, String staffId})>((ref, params) async {
  // Initialize local notifications
  await LocalNotificationService.instance.initialize();

  // Initialize preferences
  await NotificationPreferences.instance.initialize();

  // Initialize FCM
  await FCMService.instance.initialize(
    businessId: params.businessId,
    staffId: params.staffId,
  );

  // Initialize reminder service
  await ReminderService.instance.initialize();

  // Set up notification tap handler
  void handleNotificationTap(NotificationPayload payload) {
    // This will be handled by the app's navigation
    // The actual navigation logic should be set up in the app
  }

  FCMService.instance.onNotificationTapped = handleNotificationTap;
  LocalNotificationService.instance.onNotificationTapped = handleNotificationTap;
});

// Permission Providers

/// Provider for checking if notification permission is granted.
final notificationPermissionGrantedProvider = FutureProvider<bool>((ref) async {
  return LocalNotificationService.instance.requestPermission();
});

/// Provider for requesting notification permission.
final requestNotificationPermissionProvider = Provider<Future<bool> Function()>((ref) {
  return () async {
    final fcmGranted = await FCMService.instance.requestPermission();
    final localGranted = await LocalNotificationService.instance.requestPermission();
    return fcmGranted && localGranted;
  };
});

// Status Providers

/// Provider for the count of pending scheduled notifications.
final pendingNotificationCountProvider = FutureProvider<int>((ref) async {
  return ReminderService.instance.getPendingNotificationCount();
});
