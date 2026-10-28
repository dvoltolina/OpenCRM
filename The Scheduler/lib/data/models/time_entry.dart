import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'time_entry.freezed.dart';
part 'time_entry.g.dart';

/// Status of a time entry in the approval workflow.
enum TimeEntryStatus {
  /// Currently clocked in
  active,

  /// Clocked out, awaiting approval
  pending,

  /// Manager approved
  approved,

  /// Manager rejected (needs correction)
  rejected,
}

/// Type of break taken during a shift.
enum BreakType {
  /// Meal break (typically 30+ minutes)
  meal,

  /// Rest break (typically 10-15 minutes)
  rest,
}

/// Converter for Firestore Timestamp to DateTime.
class _TimestampConverter implements JsonConverter<DateTime, dynamic> {
  const _TimestampConverter();

  @override
  DateTime fromJson(dynamic json) {
    if (json is Timestamp) {
      return json.toDate();
    } else if (json is String) {
      return DateTime.parse(json);
    } else if (json is int) {
      return DateTime.fromMillisecondsSinceEpoch(json);
    }
    throw ArgumentError('Cannot convert $json to DateTime');
  }

  @override
  dynamic toJson(DateTime object) => Timestamp.fromDate(object);
}

/// Converter for nullable Firestore Timestamp to DateTime.
class _NullableTimestampConverter implements JsonConverter<DateTime?, dynamic> {
  const _NullableTimestampConverter();

  @override
  DateTime? fromJson(dynamic json) {
    if (json == null) return null;
    if (json is Timestamp) {
      return json.toDate();
    } else if (json is String) {
      return DateTime.parse(json);
    } else if (json is int) {
      return DateTime.fromMillisecondsSinceEpoch(json);
    }
    return null;
  }

  @override
  dynamic toJson(DateTime? object) =>
      object == null ? null : Timestamp.fromDate(object);
}

/// Represents a break period during a time entry.
@freezed
abstract class BreakPeriod with _$BreakPeriod {
  const factory BreakPeriod({
    @_TimestampConverter() required DateTime startTime,
    @_NullableTimestampConverter() DateTime? endTime,
    required BreakType type,
  }) = _BreakPeriod;

  factory BreakPeriod.fromJson(Map<String, dynamic> json) =>
      _$BreakPeriodFromJson(json);
}

/// Extension methods for BreakPeriod.
extension BreakPeriodExtensions on BreakPeriod {
  /// Whether this break is currently active (no end time).
  bool get isActive => endTime == null;

  /// Duration of the break in minutes.
  /// Returns 0 if break is still active.
  int get durationMinutes {
    if (endTime == null) return 0;
    return endTime!.difference(startTime).inMinutes;
  }
}

/// Represents a time entry for staff clock-in/clock-out tracking.
///
/// This model is used for tracking working hours, breaks, and payroll
/// calculations. Time entries are stored in Firestore at:
/// `businesses/{businessId}/timeEntries/{timeEntryId}`
@freezed
abstract class TimeEntry with _$TimeEntry {
  const factory TimeEntry({
    required String id,
    required String businessId,
    required String staffId,

    // Clock in/out times
    @_TimestampConverter() required DateTime clockInTime,
    @_NullableTimestampConverter() DateTime? clockOutTime,

    // Clock-in location tracking (GPS)
    double? clockInLatitude,
    double? clockInLongitude,
    String? clockInAddress,

    // Clock-out location tracking (GPS)
    double? clockOutLatitude,
    double? clockOutLongitude,
    String? clockOutAddress,

    // Geo-fence validation
    /// Business location ID if clocked in at a known location
    String? clockInLocationId,

    /// Business location ID if clocked out at a known location
    String? clockOutLocationId,

    /// True if clock-in was outside the geo-fence radius
    @Default(false) bool clockInOutsideGeofence,

    /// True if clock-out was outside the geo-fence radius
    @Default(false) bool clockOutOutsideGeofence,

    // Breaks
    @Default([]) List<BreakPeriod> breaks,

    // Calculated fields (set on clock out)
    /// Total minutes between clock-in and clock-out
    int? totalMinutes,

    /// Total break time in minutes
    int? breakMinutes,

    /// Worked minutes (totalMinutes - breakMinutes)
    int? workedMinutes,

    // Status & approval
    required TimeEntryStatus status,

    /// User ID of manager who approved/rejected
    String? approvedByUserId,

    /// When the entry was approved/rejected
    @_NullableTimestampConverter() DateTime? approvedAt,

    /// Reason for rejection (if status is rejected)
    String? rejectionReason,

    // Notes
    /// Notes added by staff member
    String? staffNotes,

    /// Notes added by manager
    String? managerNotes,

    // Audit fields
    @_TimestampConverter() required DateTime createdAt,
    @_TimestampConverter() required DateTime updatedAt,
  }) = _TimeEntry;

  factory TimeEntry.fromJson(Map<String, dynamic> json) =>
      _$TimeEntryFromJson(json);
}

/// Extension methods for TimeEntry.
extension TimeEntryExtensions on TimeEntry {
  /// Whether this entry is currently active (clocked in, not clocked out).
  bool get isActive => status == TimeEntryStatus.active && clockOutTime == null;

  /// Whether this entry has been approved.
  bool get isApproved => status == TimeEntryStatus.approved;

  /// Whether this entry is pending approval.
  bool get isPendingApproval => status == TimeEntryStatus.pending;

  /// Whether this entry was rejected.
  bool get isRejected => status == TimeEntryStatus.rejected;

  /// Whether the staff is currently on break.
  bool get isOnBreak {
    if (breaks.isEmpty) return false;
    final lastBreak = breaks.last;
    return lastBreak.endTime == null;
  }

  /// Duration in hours as a decimal (e.g., 8.5 hours).
  double get durationHours => (workedMinutes ?? 0) / 60.0;

  /// Total break hours as a decimal.
  double get breakHours => (breakMinutes ?? 0) / 60.0;

  /// Calculates the total break minutes from all break periods.
  int get calculatedBreakMinutes {
    return breaks.fold<int>(0, (total, b) => total + b.durationMinutes);
  }

  /// Calculates worked minutes from clock times and breaks.
  int? get calculatedWorkedMinutes {
    if (clockOutTime == null) return null;
    final total = clockOutTime!.difference(clockInTime).inMinutes;
    return total - calculatedBreakMinutes;
  }

  /// Check if entry can be edited (draft/rejected status).
  bool get isEditable =>
      status == TimeEntryStatus.active || status == TimeEntryStatus.rejected;

  /// Check if this entry requires location verification.
  bool get hasLocationData =>
      clockInLatitude != null && clockInLongitude != null;
}
