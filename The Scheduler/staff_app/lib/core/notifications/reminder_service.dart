import 'package:flutter/foundation.dart';

import '../../data/local/staff_database.dart';
import 'local_notification_service.dart';
import 'notification_content.dart';
import 'notification_preferences.dart';

/// Service for scheduling appointment reminders.
///
/// Schedules local notifications before appointments and manages
/// reminder updates when appointments change.
class ReminderService {
  ReminderService._();
  static final ReminderService instance = ReminderService._();

  final _localNotifications = LocalNotificationService.instance;
  final _preferences = NotificationPreferences.instance;

  // Maps appointment IDs to their scheduled notification IDs
  final Map<String, List<int>> _scheduledReminders = {};

  /// Initializes the reminder service.
  Future<void> initialize() async {
    // Local notifications should already be initialized
    debugPrint('ReminderService: Initialized');
  }

  /// Schedules reminders for an appointment.
  ///
  /// Schedules notifications based on user preferences:
  /// - 1 hour before (if enabled)
  /// - 15 minutes before (if enabled)
  Future<void> scheduleRemindersForAppointment(
    AppointmentsTableData appointment,
  ) async {
    if (!_preferences.remindersEnabled) return;

    // Cancel existing reminders for this appointment
    await cancelRemindersForAppointment(appointment.id);

    final now = DateTime.now();
    final startTime = appointment.startTime;

    // Don't schedule reminders for past appointments
    if (startTime.isBefore(now)) return;

    final notificationIds = <int>[];

    // Schedule 1-hour reminder
    if (_preferences.reminder1HourEnabled) {
      final reminderTime = startTime.subtract(const Duration(hours: 1));
      if (reminderTime.isAfter(now)) {
        final id = await _localNotifications.scheduleNotification(
          title: NotificationTemplates.appointmentReminder1Hour.title,
          body: NotificationTemplates.appointmentReminder1Hour.body,
          scheduledTime: reminderTime,
          payload: NotificationPayload(
            type: NotificationType.appointmentReminder,
            appointmentId: appointment.id,
          ).toJsonString(),
          channelId: 'reminders',
          channelName: 'Reminders',
        );
        notificationIds.add(id);
        debugPrint('ReminderService: Scheduled 1-hour reminder for ${appointment.id}');
      }
    }

    // Schedule 15-minute reminder
    if (_preferences.reminder15MinEnabled) {
      final reminderTime = startTime.subtract(const Duration(minutes: 15));
      if (reminderTime.isAfter(now)) {
        final id = await _localNotifications.scheduleNotification(
          title: NotificationTemplates.appointmentReminder15Min.title,
          body: NotificationTemplates.appointmentReminder15Min.body,
          scheduledTime: reminderTime,
          payload: NotificationPayload(
            type: NotificationType.appointmentReminder,
            appointmentId: appointment.id,
          ).toJsonString(),
          channelId: 'reminders',
          channelName: 'Reminders',
        );
        notificationIds.add(id);
        debugPrint('ReminderService: Scheduled 15-min reminder for ${appointment.id}');
      }
    }

    if (notificationIds.isNotEmpty) {
      _scheduledReminders[appointment.id] = notificationIds;
    }
  }

  /// Cancels reminders for an appointment.
  Future<void> cancelRemindersForAppointment(String appointmentId) async {
    final notificationIds = _scheduledReminders.remove(appointmentId);
    if (notificationIds != null) {
      for (final id in notificationIds) {
        await _localNotifications.cancelNotification(id);
      }
      debugPrint('ReminderService: Cancelled ${notificationIds.length} reminders for $appointmentId');
    }
  }

  /// Updates reminders for all appointments.
  ///
  /// Call this when appointments are synced or when reminder
  /// preferences change.
  Future<void> updateAllReminders(List<AppointmentsTableData> appointments) async {
    // Cancel all existing reminders
    await cancelAllReminders();

    if (!_preferences.remindersEnabled) return;

    // Schedule reminders for upcoming appointments
    final now = DateTime.now();
    final upcoming = appointments.where(
      (apt) => apt.startTime.isAfter(now) && apt.status != 'cancelled',
    );

    for (final appointment in upcoming) {
      await scheduleRemindersForAppointment(appointment);
    }

    debugPrint('ReminderService: Updated reminders for ${upcoming.length} appointments');
  }

  /// Cancels all scheduled reminders.
  Future<void> cancelAllReminders() async {
    for (final ids in _scheduledReminders.values) {
      for (final id in ids) {
        await _localNotifications.cancelNotification(id);
      }
    }
    _scheduledReminders.clear();
    debugPrint('ReminderService: Cancelled all reminders');
  }

  /// Schedules a shift start reminder.
  Future<void> scheduleShiftReminder({
    required DateTime shiftStart,
    Duration reminderBefore = const Duration(minutes: 30),
  }) async {
    if (!_preferences.remindersEnabled) return;

    final reminderTime = shiftStart.subtract(reminderBefore);
    if (reminderTime.isBefore(DateTime.now())) return;

    await _localNotifications.scheduleNotification(
      title: NotificationTemplates.shiftReminder.title,
      body: NotificationTemplates.shiftReminder.body,
      scheduledTime: reminderTime,
      payload: const NotificationPayload(
        type: NotificationType.shiftReminder,
      ).toJsonString(),
      channelId: 'reminders',
      channelName: 'Reminders',
    );

    debugPrint('ReminderService: Scheduled shift reminder for $shiftStart');
  }

  /// Gets the count of scheduled reminders.
  int get scheduledReminderCount {
    return _scheduledReminders.values.fold(0, (sum, ids) => sum + ids.length);
  }

  /// Gets pending notification requests from the system.
  Future<int> getPendingNotificationCount() async {
    final pending = await _localNotifications.getPendingNotifications();
    return pending.length;
  }
}
