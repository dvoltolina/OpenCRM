import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'notification_content.dart';

/// User preferences for notifications.
///
/// Stores notification settings including enabled types and quiet hours.
class NotificationPreferences {
  NotificationPreferences._();
  static final NotificationPreferences instance = NotificationPreferences._();

  SharedPreferences? _prefs;

  // Preference keys
  static const _keyScheduleUpdates = 'notif_schedule_updates';
  static const _keyNewAppointments = 'notif_new_appointments';
  static const _keyCancellations = 'notif_cancellations';
  static const _keyReminders = 'notif_reminders';
  static const _keyTimesheetStatus = 'notif_timesheet_status';
  static const _keyAnnouncements = 'notif_announcements';
  static const _keyQuietHoursEnabled = 'notif_quiet_hours_enabled';
  static const _keyQuietHoursStart = 'notif_quiet_hours_start';
  static const _keyQuietHoursEnd = 'notif_quiet_hours_end';
  static const _keyReminderTime1Hour = 'notif_reminder_1_hour'; // gitleaks:allow -- SharedPreferences setting name, not a credential.
  static const _reminderTime15MinPreference = 'notif_reminder_15_min'; // gitleaks:allow -- SharedPreferences setting name, not a credential.

  /// Initializes preferences.
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  SharedPreferences get _storage {
    if (_prefs == null) {
      throw StateError('NotificationPreferences not initialized. Call initialize() first.');
    }
    return _prefs!;
  }

  // Schedule Updates
  bool get scheduleUpdatesEnabled => _storage.getBool(_keyScheduleUpdates) ?? true;
  Future<void> setScheduleUpdatesEnabled(bool value) =>
      _storage.setBool(_keyScheduleUpdates, value);

  // New Appointments
  bool get newAppointmentsEnabled => _storage.getBool(_keyNewAppointments) ?? true;
  Future<void> setNewAppointmentsEnabled(bool value) =>
      _storage.setBool(_keyNewAppointments, value);

  // Cancellations
  bool get cancellationsEnabled => _storage.getBool(_keyCancellations) ?? true;
  Future<void> setCancellationsEnabled(bool value) =>
      _storage.setBool(_keyCancellations, value);

  // Reminders
  bool get remindersEnabled => _storage.getBool(_keyReminders) ?? true;
  Future<void> setRemindersEnabled(bool value) =>
      _storage.setBool(_keyReminders, value);

  // Timesheet Status
  bool get timesheetStatusEnabled => _storage.getBool(_keyTimesheetStatus) ?? true;
  Future<void> setTimesheetStatusEnabled(bool value) =>
      _storage.setBool(_keyTimesheetStatus, value);

  // Announcements
  bool get announcementsEnabled => _storage.getBool(_keyAnnouncements) ?? true;
  Future<void> setAnnouncementsEnabled(bool value) =>
      _storage.setBool(_keyAnnouncements, value);

  // Quiet Hours
  bool get quietHoursEnabled => _storage.getBool(_keyQuietHoursEnabled) ?? false;
  Future<void> setQuietHoursEnabled(bool value) =>
      _storage.setBool(_keyQuietHoursEnabled, value);

  TimeOfDay get quietHoursStart {
    final minutes = _storage.getInt(_keyQuietHoursStart) ?? (22 * 60); // 10 PM
    return TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
  }

  Future<void> setQuietHoursStart(TimeOfDay time) =>
      _storage.setInt(_keyQuietHoursStart, time.hour * 60 + time.minute);

  TimeOfDay get quietHoursEnd {
    final minutes = _storage.getInt(_keyQuietHoursEnd) ?? (7 * 60); // 7 AM
    return TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
  }

  Future<void> setQuietHoursEnd(TimeOfDay time) =>
      _storage.setInt(_keyQuietHoursEnd, time.hour * 60 + time.minute);

  // Reminder Times
  bool get reminder1HourEnabled => _storage.getBool(_keyReminderTime1Hour) ?? true;
  Future<void> setReminder1HourEnabled(bool value) =>
      _storage.setBool(_keyReminderTime1Hour, value);

  bool get reminder15MinEnabled => _storage.getBool(_reminderTime15MinPreference) ?? true;
  Future<void> setReminder15MinEnabled(bool value) =>
      _storage.setBool(_reminderTime15MinPreference, value);

  /// Checks if a notification type is enabled.
  bool isNotificationTypeEnabled(NotificationType type) {
    switch (type) {
      case NotificationType.scheduleUpdate:
        return scheduleUpdatesEnabled;
      case NotificationType.newAppointment:
        return newAppointmentsEnabled;
      case NotificationType.appointmentCancelled:
      case NotificationType.appointmentRescheduled:
        return cancellationsEnabled;
      case NotificationType.appointmentReminder:
      case NotificationType.shiftReminder:
        return remindersEnabled;
      case NotificationType.timesheetApproved:
      case NotificationType.timesheetRejected:
        return timesheetStatusEnabled;
      case NotificationType.announcement:
        return announcementsEnabled;
      case NotificationType.syncRequired:
        return true; // Always show system notifications
    }
  }

  /// Checks if current time is within quiet hours.
  bool isInQuietHours() {
    if (!quietHoursEnabled) return false;

    final now = TimeOfDay.now();
    final start = quietHoursStart;
    final end = quietHoursEnd;

    final nowMinutes = now.hour * 60 + now.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;

    // Handle overnight quiet hours (e.g., 10 PM to 7 AM)
    if (startMinutes > endMinutes) {
      return nowMinutes >= startMinutes || nowMinutes < endMinutes;
    } else {
      return nowMinutes >= startMinutes && nowMinutes < endMinutes;
    }
  }

  /// Determines if a notification should be shown based on preferences.
  Future<bool> shouldShowNotification(NotificationType type) async {
    // Check if notification type is enabled
    if (!isNotificationTypeEnabled(type)) {
      return false;
    }

    // Check quiet hours (except for urgent notifications)
    if (isInQuietHours() &&
        type != NotificationType.syncRequired) {
      return false;
    }

    return true;
  }

  /// Gets all preferences as a map for syncing to backend.
  Map<String, dynamic> toMap() {
    return {
      'scheduleUpdates': scheduleUpdatesEnabled,
      'newAppointments': newAppointmentsEnabled,
      'cancellations': cancellationsEnabled,
      'reminders': remindersEnabled,
      'timesheetStatus': timesheetStatusEnabled,
      'announcements': announcementsEnabled,
      'quietHoursEnabled': quietHoursEnabled,
      'quietHoursStart': quietHoursStart.hour * 60 + quietHoursStart.minute,
      'quietHoursEnd': quietHoursEnd.hour * 60 + quietHoursEnd.minute,
      'reminder1Hour': reminder1HourEnabled,
      'reminder15Min': reminder15MinEnabled,
    };
  }

  /// Loads preferences from a map (from backend sync).
  Future<void> fromMap(Map<String, dynamic> map) async {
    if (map.containsKey('scheduleUpdates')) {
      await setScheduleUpdatesEnabled(map['scheduleUpdates'] as bool);
    }
    if (map.containsKey('newAppointments')) {
      await setNewAppointmentsEnabled(map['newAppointments'] as bool);
    }
    if (map.containsKey('cancellations')) {
      await setCancellationsEnabled(map['cancellations'] as bool);
    }
    if (map.containsKey('reminders')) {
      await setRemindersEnabled(map['reminders'] as bool);
    }
    if (map.containsKey('timesheetStatus')) {
      await setTimesheetStatusEnabled(map['timesheetStatus'] as bool);
    }
    if (map.containsKey('announcements')) {
      await setAnnouncementsEnabled(map['announcements'] as bool);
    }
    if (map.containsKey('quietHoursEnabled')) {
      await setQuietHoursEnabled(map['quietHoursEnabled'] as bool);
    }
    if (map.containsKey('quietHoursStart')) {
      final minutes = map['quietHoursStart'] as int;
      await setQuietHoursStart(TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60));
    }
    if (map.containsKey('quietHoursEnd')) {
      final minutes = map['quietHoursEnd'] as int;
      await setQuietHoursEnd(TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60));
    }
    if (map.containsKey('reminder1Hour')) {
      await setReminder1HourEnabled(map['reminder1Hour'] as bool);
    }
    if (map.containsKey('reminder15Min')) {
      await setReminder15MinEnabled(map['reminder15Min'] as bool);
    }
  }
}

/// Extension for TimeOfDay.
extension TimeOfDayExtension on TimeOfDay {
  /// Returns the current time of day.
  static TimeOfDay now() {
    final now = DateTime.now();
    return TimeOfDay(hour: now.hour, minute: now.minute);
  }

  /// Formats as HH:MM AM/PM.
  String format12Hour() {
    final h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final m = minute.toString().padLeft(2, '0');
    final period = hour < 12 ? 'AM' : 'PM';
    return '$h:$m $period';
  }
}
