import 'package:freezed_annotation/freezed_annotation.dart';

import 'time_entry.dart';

part 'timesheet_summary.freezed.dart';
part 'timesheet_summary.g.dart';

/// Status of a timesheet in the approval/processing workflow.
enum TimesheetStatus {
  /// Initial state, staff is still working on entries
  draft,

  /// Staff has submitted for approval
  submitted,

  /// Manager has approved the timesheet
  approved,

  /// Timesheet has been processed for payroll
  processed,
}

/// Aggregated timesheet summary for a staff member over a pay period.
///
/// This model calculates and stores totals for worked hours, breaks,
/// overtime, and estimated pay for reporting and payroll purposes.
@freezed
class TimesheetSummary with _$TimesheetSummary {
  const TimesheetSummary._();

  const factory TimesheetSummary({
    required String staffId,
    required String staffName,
    required DateTime periodStart,
    required DateTime periodEnd,

    /// Total minutes worked across all entries
    required int totalWorkedMinutes,
    /// Total break minutes across all entries
    required int totalBreakMinutes,
    /// Number of shifts (clock-in/clock-out cycles) in period
    required int totalShifts,

    /// Regular hours (up to 8 hrs/day or 40 hrs/week)
    required int regularMinutes,
    /// Overtime hours (beyond 8 hrs/day or 40 hrs/week)
    required int overtimeMinutes,

    /// Estimated pay based on hourly rate
    required double estimatedPayAmount,

    /// All time entries in this period
    required List<TimeEntry> entries,

    /// Current approval status
    required TimesheetStatus status,
  }) = _TimesheetSummary;

  factory TimesheetSummary.fromJson(Map<String, dynamic> json) =>
      _$TimesheetSummaryFromJson(json);

  /// Total hours worked (decimal format)
  double get totalWorkedHours => totalWorkedMinutes / 60.0;

  /// Total break hours (decimal format)
  double get totalBreakHours => totalBreakMinutes / 60.0;

  /// Regular hours (decimal format)
  double get regularHours => regularMinutes / 60.0;

  /// Overtime hours (decimal format)
  double get overtimeHours => overtimeMinutes / 60.0;

  /// Whether this timesheet has any overtime
  bool get hasOvertime => overtimeMinutes > 0;

  /// Whether this timesheet is pending approval
  bool get isPendingApproval => status == TimesheetStatus.submitted;

  /// Whether this timesheet is editable (draft or rejected)
  bool get isEditable => status == TimesheetStatus.draft;
}
