// HIPAA-compliant notification templates.
//
// CRITICAL: Notifications must NEVER contain Protected Health Information (PHI):
// - NO client names
// - NO phone numbers
// - NO addresses
// - NO appointment times with identifiable info
// - NO service details
// - NO health-related information
//
// All notifications use generic messages that provide value without
// exposing sensitive data. The full details are only shown after
// the user authenticates in the app.

/// Types of notifications the staff app can receive.
enum NotificationType {
  /// Schedule has been updated (generic)
  scheduleUpdate('schedule_update'),

  /// New appointment added
  newAppointment('new_appointment'),

  /// Appointment was cancelled
  appointmentCancelled('appointment_cancelled'),

  /// Appointment was rescheduled
  appointmentRescheduled('appointment_rescheduled'),

  /// Timesheet was approved
  timesheetApproved('timesheet_approved'),

  /// Timesheet was rejected
  timesheetRejected('timesheet_rejected'),

  /// Upcoming appointment reminder
  appointmentReminder('appointment_reminder'),

  /// Shift reminder
  shiftReminder('shift_reminder'),

  /// General announcement from admin
  announcement('announcement'),

  /// Sync required notification
  syncRequired('sync_required');

  const NotificationType(this.value);
  final String value;

  static NotificationType? fromString(String? value) {
    if (value == null) return null;
    return NotificationType.values.cast<NotificationType?>().firstWhere(
          (t) => t?.value == value,
          orElse: () => null,
        );
  }
}

/// Template for a notification with HIPAA-compliant content.
class NotificationTemplate {
  const NotificationTemplate({
    required this.type,
    required this.title,
    required this.body,
    this.channelId = 'default',
    this.channelName = 'General',
    this.importance = NotificationImportance.high,
  });

  final NotificationType type;
  final String title;
  final String body;
  final String channelId;
  final String channelName;
  final NotificationImportance importance;
}

/// Notification importance levels.
enum NotificationImportance {
  low,
  normal,
  high,
  urgent,
}

/// HIPAA-compliant notification content templates.
///
/// These templates ensure NO Protected Health Information is ever
/// displayed in push notifications, which may appear on lock screens.
class NotificationTemplates {
  NotificationTemplates._();

  // Schedule notifications
  static const scheduleUpdate = NotificationTemplate(
    type: NotificationType.scheduleUpdate,
    title: 'Schedule Updated',
    body: 'Your schedule has been updated. Tap to view changes.',
    channelId: 'schedule',
    channelName: 'Schedule Updates',
  );

  static const newAppointment = NotificationTemplate(
    type: NotificationType.newAppointment,
    title: 'New Appointment',
    body: 'A new appointment has been added to your schedule.',
    channelId: 'schedule',
    channelName: 'Schedule Updates',
  );

  static const appointmentCancelled = NotificationTemplate(
    type: NotificationType.appointmentCancelled,
    title: 'Appointment Cancelled',
    body: 'An appointment has been cancelled. Tap to view your updated schedule.',
    channelId: 'schedule',
    channelName: 'Schedule Updates',
  );

  static const appointmentRescheduled = NotificationTemplate(
    type: NotificationType.appointmentRescheduled,
    title: 'Appointment Rescheduled',
    body: 'An appointment has been rescheduled. Tap to view details.',
    channelId: 'schedule',
    channelName: 'Schedule Updates',
  );

  // Reminder notifications
  static const appointmentReminder1Hour = NotificationTemplate(
    type: NotificationType.appointmentReminder,
    title: 'Upcoming Appointment',
    body: 'You have an appointment in 1 hour.',
    channelId: 'reminders',
    channelName: 'Reminders',
    importance: NotificationImportance.high,
  );

  static const appointmentReminder15Min = NotificationTemplate(
    type: NotificationType.appointmentReminder,
    title: 'Appointment Starting Soon',
    body: 'You have an appointment in 15 minutes.',
    channelId: 'reminders',
    channelName: 'Reminders',
    importance: NotificationImportance.urgent,
  );

  static const shiftReminder = NotificationTemplate(
    type: NotificationType.shiftReminder,
    title: 'Shift Reminder',
    body: 'Your shift starts soon. Don\'t forget to clock in!',
    channelId: 'reminders',
    channelName: 'Reminders',
  );

  // Timesheet notifications
  static const timesheetApproved = NotificationTemplate(
    type: NotificationType.timesheetApproved,
    title: 'Timesheet Approved',
    body: 'Your timesheet has been approved.',
    channelId: 'timesheet',
    channelName: 'Timesheet',
  );

  static const timesheetRejected = NotificationTemplate(
    type: NotificationType.timesheetRejected,
    title: 'Timesheet Needs Attention',
    body: 'Your timesheet requires corrections. Tap to view details.',
    channelId: 'timesheet',
    channelName: 'Timesheet',
    importance: NotificationImportance.high,
  );

  // System notifications
  static const syncRequired = NotificationTemplate(
    type: NotificationType.syncRequired,
    title: 'Sync Required',
    body: 'Your data needs to sync. Tap to open the app.',
    channelId: 'system',
    channelName: 'System',
    importance: NotificationImportance.normal,
  );

  static const announcement = NotificationTemplate(
    type: NotificationType.announcement,
    title: 'New Announcement',
    body: 'You have a new message from your administrator.',
    channelId: 'announcements',
    channelName: 'Announcements',
  );

  /// Gets the template for a notification type.
  static NotificationTemplate? getTemplate(NotificationType type) {
    switch (type) {
      case NotificationType.scheduleUpdate:
        return scheduleUpdate;
      case NotificationType.newAppointment:
        return newAppointment;
      case NotificationType.appointmentCancelled:
        return appointmentCancelled;
      case NotificationType.appointmentRescheduled:
        return appointmentRescheduled;
      case NotificationType.appointmentReminder:
        return appointmentReminder15Min;
      case NotificationType.shiftReminder:
        return shiftReminder;
      case NotificationType.timesheetApproved:
        return timesheetApproved;
      case NotificationType.timesheetRejected:
        return timesheetRejected;
      case NotificationType.syncRequired:
        return syncRequired;
      case NotificationType.announcement:
        return announcement;
    }
  }
}

/// Payload data for notifications.
///
/// Contains only IDs and type information - never PHI.
class NotificationPayload {
  const NotificationPayload({
    required this.type,
    this.appointmentId,
    this.timesheetDate,
    this.route,
  });

  final NotificationType type;
  final String? appointmentId;
  final String? timesheetDate;
  final String? route;

  Map<String, String> toMap() {
    return {
      'type': type.value,
      if (appointmentId != null) 'appointmentId': appointmentId!,
      if (timesheetDate != null) 'timesheetDate': timesheetDate!,
      if (route != null) 'route': route!,
    };
  }

  factory NotificationPayload.fromMap(Map<String, dynamic> map) {
    return NotificationPayload(
      type: NotificationType.fromString(map['type'] as String?) ??
          NotificationType.scheduleUpdate,
      appointmentId: map['appointmentId'] as String?,
      timesheetDate: map['timesheetDate'] as String?,
      route: map['route'] as String?,
    );
  }

  String toJsonString() {
    final parts = <String>[];
    parts.add('"type":"${type.value}"');
    if (appointmentId != null) parts.add('"appointmentId":"$appointmentId"');
    if (timesheetDate != null) parts.add('"timesheetDate":"$timesheetDate"');
    if (route != null) parts.add('"route":"$route"');
    return '{${parts.join(',')}}';
  }
}
