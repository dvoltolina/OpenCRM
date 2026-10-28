import 'package:freezed_annotation/freezed_annotation.dart';

import '../converters/timestamp_converters.dart';

part 'app_notification.freezed.dart';
part 'app_notification.g.dart';

/// Type of notification for categorization and icon display.
enum NotificationType {
  appointmentReminder,
  appointmentConfirmed,
  appointmentCancelled,
  appointmentRescheduled,
  waitlistAvailable,
  newMessage,
  paymentReceived,
  paymentFailed,
  intakeFormRequired,
  general,
}

/// Priority level affects visual styling and ordering.
enum NotificationPriority { low, normal, high, urgent }

/// In-app notification for inbox/history display.
/// Stored per-user (not per-business) for cross-business notifications.
@freezed
abstract class AppNotification with _$AppNotification {
  const factory AppNotification({
    required String id,
    required String userId,
    String? businessId,
    required NotificationType type,
    required String title,
    required String body,
    @Default(NotificationPriority.normal) NotificationPriority priority,
    @Default(false) bool isRead,
    @NullableTimestampConverter() DateTime? readAt,
    @TimestampConverter() required DateTime createdAt,
    /// Deep link data for navigation on tap
    String? targetType, // 'appointment', 'conversation', 'intake_form', etc.
    String? targetId,
    /// Additional data payload
    @Default({}) Map<String, dynamic> data,
    /// TTL - notifications can expire
    @NullableTimestampConverter() DateTime? expiresAt,
  }) = _AppNotification;

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      _$AppNotificationFromJson(json);
}

extension AppNotificationExtensions on AppNotification {
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  bool get isUnread => !isRead && !isExpired;
}
