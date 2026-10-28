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

/// Represents a break period during a time entry.
@freezed
class BreakPeriod with _$BreakPeriod {
  const factory BreakPeriod({
    required DateTime startTime,
    DateTime? endTime,
    required BreakType type,
  }) = _BreakPeriod;

  factory BreakPeriod.fromJson(Map<String, dynamic> json) =>
      _$BreakPeriodFromJson(json);
}

/// Represents a time entry for staff clock-in/clock-out tracking.
///
/// This model is used by both the main admin app and the staff app
/// for tracking working hours, breaks, and payroll calculations.
@freezed
class TimeEntry with _$TimeEntry {
  const factory TimeEntry({
    required String id,
    required String businessId,
    required String staffId,

    // Clock in/out times
    required DateTime clockInTime,
    DateTime? clockOutTime,

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
    DateTime? approvedAt,
    /// Reason for rejection (if status is rejected)
    String? rejectionReason,

    // Notes
    /// Notes added by staff member
    String? staffNotes,
    /// Notes added by manager
    String? managerNotes,

    // Audit fields
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _TimeEntry;

  factory TimeEntry.fromJson(Map<String, dynamic> json) =>
      _$TimeEntryFromJson(json);
}
