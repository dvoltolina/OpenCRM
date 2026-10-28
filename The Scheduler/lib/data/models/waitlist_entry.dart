import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../converters/timestamp_converters.dart';
import 'security_context.dart';

part 'waitlist_entry.freezed.dart';
part 'waitlist_entry.g.dart';

/// Status of a waitlist entry lifecycle.
enum WaitlistStatus { active, notified, expired, converted }

/// Channel preference for waitlist notifications.
enum NotificationPreference { email, sms, both }

/// Broad time-of-day preferences for matching newly opened slots.
enum TimeOfDayPreference { morning, afternoon, evening, anytime }

/// Data model representing a client's waitlist request.
///
/// HIPAA: Contains client contact info (PHI). Audit all access.
@freezed
abstract class WaitlistEntry with _$WaitlistEntry {
  const WaitlistEntry._();

  const factory WaitlistEntry({
    required String id,
    required String businessId,
    String? clientId,
    required String clientName,
    String? clientEmail,
    String? clientPhone,
    required String serviceId,
    String? serviceName,
    String? providerId,
    String? providerName,
    String? locationId,
    @Default(<int>[]) List<int> preferredDaysOfWeek,
    @Default(<TimeOfDayPreference>[TimeOfDayPreference.anytime])
    List<TimeOfDayPreference> timeOfDayPreferences,
    @TimestampConverter() required DateTime earliestDate,
    @TimestampConverter() required DateTime latestDate,
    @Default(0.0) double priorityScore,
    @Default(NotificationPreference.email)
    NotificationPreference notificationPreference,
    @Default(WaitlistStatus.active) WaitlistStatus status,
    @TimestampConverter() required DateTime createdAt,
    @TimestampConverter() required DateTime updatedAt,
    @NullableTimestampConverter() DateTime? lastNotifiedAt,
    @NullableTimestampConverter() DateTime? responseExpiresAt,
    @NullableTimestampConverter() DateTime? expiresAt,
    String? notes,
  }) = _WaitlistEntry;

  factory WaitlistEntry.fromJson(Map<String, dynamic> json) =>
      _$WaitlistEntryFromJson(json);

  /// Create from Firestore document.
  factory WaitlistEntry.fromFirestore({
    required Map<String, dynamic> data,
    required String documentId,
  }) {
    // Handle Timestamp conversion for dates
    final processed = Map<String, dynamic>.from(data);

    // Convert timestamps
    if (processed['earliestDate'] is Timestamp) {
      processed['earliestDate'] =
          (processed['earliestDate'] as Timestamp).toDate().toIso8601String();
    }
    if (processed['latestDate'] is Timestamp) {
      processed['latestDate'] =
          (processed['latestDate'] as Timestamp).toDate().toIso8601String();
    }
    if (processed['createdAt'] is Timestamp) {
      processed['createdAt'] =
          (processed['createdAt'] as Timestamp).toDate().toIso8601String();
    }
    if (processed['updatedAt'] is Timestamp) {
      processed['updatedAt'] =
          (processed['updatedAt'] as Timestamp).toDate().toIso8601String();
    }
    if (processed['lastNotifiedAt'] is Timestamp) {
      processed['lastNotifiedAt'] =
          (processed['lastNotifiedAt'] as Timestamp).toDate().toIso8601String();
    }
    if (processed['responseExpiresAt'] is Timestamp) {
      processed['responseExpiresAt'] =
          (processed['responseExpiresAt'] as Timestamp)
              .toDate()
              .toIso8601String();
    }
    if (processed['expiresAt'] is Timestamp) {
      processed['expiresAt'] =
          (processed['expiresAt'] as Timestamp).toDate().toIso8601String();
    }

    // Set defaults for required fields
    processed['id'] = documentId;
    processed['clientName'] ??= 'Unknown client';
    processed['priorityScore'] ??= 0.0;

    return WaitlistEntry.fromJson(processed);
  }

  /// Convert to Firestore map.
  Map<String, dynamic> toFirestore() {
    return {
      'businessId': businessId,
      'clientId': clientId,
      'clientName': clientName,
      'clientEmail': clientEmail,
      'clientPhone': clientPhone,
      'serviceId': serviceId,
      'serviceName': serviceName,
      'providerId': providerId,
      'providerName': providerName,
      'locationId': locationId,
      'preferredDaysOfWeek': preferredDaysOfWeek,
      'timeOfDayPreferences':
          timeOfDayPreferences.map((p) => p.name).toList(),
      'earliestDate': Timestamp.fromDate(earliestDate),
      'latestDate': Timestamp.fromDate(latestDate),
      'priorityScore': priorityScore,
      'notificationPreference': notificationPreference.name,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'lastNotifiedAt':
          lastNotifiedAt != null ? Timestamp.fromDate(lastNotifiedAt!) : null,
      'responseExpiresAt': responseExpiresAt != null
          ? Timestamp.fromDate(responseExpiresAt!)
          : null,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'notes': notes,
    };
  }

  /// Determines whether this entry should be considered for the provided slot.
  bool matchesSlot(DateTime start) {
    final dateOnly = DateTime(start.year, start.month, start.day);
    if (dateOnly.isBefore(DateTime(
          earliestDate.year,
          earliestDate.month,
          earliestDate.day,
        )) ||
        dateOnly.isAfter(DateTime(
          latestDate.year,
          latestDate.month,
          latestDate.day,
        ))) {
      return false;
    }

    if (preferredDaysOfWeek.isNotEmpty &&
        !preferredDaysOfWeek.contains(start.weekday)) {
      return false;
    }

    final preference = _timePreferenceFor(start);
    if (!timeOfDayPreferences.contains(TimeOfDayPreference.anytime) &&
        !timeOfDayPreferences.contains(preference)) {
      return false;
    }

    return true;
  }

  /// Ensure caller has access to this entry's business context.
  void enforceAccess(SecurityContext context) {
    context.verifyBusinessAccess(businessId);
    if (!context.role.canManageClients &&
        context.clientId != null &&
        clientId != null &&
        clientId != context.clientId) {
      throw SecurityException('Access denied to waitlist entry $id');
    }
  }

  static TimeOfDayPreference _timePreferenceFor(DateTime start) {
    final hour = start.hour;
    if (hour < 12) return TimeOfDayPreference.morning;
    if (hour < 17) return TimeOfDayPreference.afternoon;
    return TimeOfDayPreference.evening;
  }
}
