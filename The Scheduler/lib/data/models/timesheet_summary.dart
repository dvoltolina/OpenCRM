import 'package:freezed_annotation/freezed_annotation.dart';

import 'time_entry.dart';
import '../converters/timestamp_converters.dart';

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
/// It is a computed entity not directly stored in Firestore.
@freezed
abstract class TimesheetSummary with _$TimesheetSummary {
  const TimesheetSummary._();

  const factory TimesheetSummary({
    required String staffId,
    required String staffName,
    String? staffEmail,
    String? staffAvatarUrl,
    @TimestampConverter() required DateTime periodStart,
    @TimestampConverter() required DateTime periodEnd,

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

    /// Staff hourly rate in cents (if available)
    int? hourlyRateCents,

    /// Estimated pay based on hourly rate (regular + overtime)
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

  /// Number of approved entries
  int get approvedEntriesCount =>
      entries.where((e) => e.status == TimeEntryStatus.approved).length;

  /// Number of pending entries
  int get pendingEntriesCount =>
      entries.where((e) => e.status == TimeEntryStatus.pending).length;

  /// Number of rejected entries
  int get rejectedEntriesCount =>
      entries.where((e) => e.status == TimeEntryStatus.rejected).length;

  /// Whether all entries are approved
  bool get allEntriesApproved =>
      entries.isNotEmpty &&
      entries.every((e) => e.status == TimeEntryStatus.approved);

  /// Whether any entries need attention (rejected)
  bool get hasRejectedEntries => rejectedEntriesCount > 0;
}

/// Helper class to calculate overtime based on business rules.
///
/// Default rules:
/// - Daily overtime: Hours worked > 8 hours/day
/// - Weekly overtime: Hours worked > 40 hours/week
class OvertimeCalculator {
  /// Daily threshold in minutes (default: 8 hours = 480 minutes)
  final int dailyThresholdMinutes;

  /// Weekly threshold in minutes (default: 40 hours = 2400 minutes)
  final int weeklyThresholdMinutes;

  /// Overtime multiplier (default: 1.5x)
  final double overtimeMultiplier;

  const OvertimeCalculator({
    this.dailyThresholdMinutes = 480, // 8 hours
    this.weeklyThresholdMinutes = 2400, // 40 hours
    this.overtimeMultiplier = 1.5,
  });

  /// Calculate overtime from a list of time entries.
  /// Returns a record with regular and overtime minutes.
  ({int regularMinutes, int overtimeMinutes}) calculate(
    List<TimeEntry> entries,
  ) {
    if (entries.isEmpty) {
      return (regularMinutes: 0, overtimeMinutes: 0);
    }

    int totalRegular = 0;
    int totalOvertime = 0;

    // Group entries by day for daily overtime calculation
    final entriesByDay = <DateTime, List<TimeEntry>>{};
    for (final entry in entries) {
      if (entry.workedMinutes == null) continue;
      final dayKey = DateTime(
        entry.clockInTime.year,
        entry.clockInTime.month,
        entry.clockInTime.day,
      );
      entriesByDay.putIfAbsent(dayKey, () => []).add(entry);
    }

    // Calculate daily totals and overtime
    for (final dayEntries in entriesByDay.values) {
      final dayTotal = dayEntries.fold<int>(
        0,
        (sum, e) => sum + (e.workedMinutes ?? 0),
      );

      if (dayTotal > dailyThresholdMinutes) {
        totalRegular += dailyThresholdMinutes;
        totalOvertime += dayTotal - dailyThresholdMinutes;
      } else {
        totalRegular += dayTotal;
      }
    }

    // Check weekly overtime (if total regular > weekly threshold)
    if (totalRegular > weeklyThresholdMinutes) {
      final weeklyOvertime = totalRegular - weeklyThresholdMinutes;
      totalRegular = weeklyThresholdMinutes;
      totalOvertime += weeklyOvertime;
    }

    return (regularMinutes: totalRegular, overtimeMinutes: totalOvertime);
  }

  /// Calculate estimated pay based on hourly rate and worked hours.
  double calculateEstimatedPay({
    required int regularMinutes,
    required int overtimeMinutes,
    required int hourlyRateCents,
  }) {
    final regularHours = regularMinutes / 60.0;
    final overtimeHours = overtimeMinutes / 60.0;
    final hourlyRate = hourlyRateCents / 100.0;

    final regularPay = regularHours * hourlyRate;
    final overtimePay = overtimeHours * hourlyRate * overtimeMultiplier;

    return regularPay + overtimePay;
  }
}

/// Pay period types supported by the timesheet system.
enum PayPeriodType {
  /// Every week (7 days)
  weekly,

  /// Every two weeks (14 days)
  biweekly,

  /// Twice a month (1st-15th, 16th-end)
  semimonthly,

  /// Once a month
  monthly,
}

/// Helper to calculate pay period date ranges.
class PayPeriodCalculator {
  final PayPeriodType periodType;

  /// For weekly/biweekly: which day starts the week (1=Monday, 7=Sunday)
  final int weekStartDay;

  const PayPeriodCalculator({
    this.periodType = PayPeriodType.biweekly,
    this.weekStartDay = 1, // Monday
  });

  /// Get the pay period containing the given date.
  ({DateTime start, DateTime end}) getPeriodForDate(DateTime date) {
    switch (periodType) {
      case PayPeriodType.weekly:
        return _getWeeklyPeriod(date);
      case PayPeriodType.biweekly:
        return _getBiweeklyPeriod(date);
      case PayPeriodType.semimonthly:
        return _getSemimonthlyPeriod(date);
      case PayPeriodType.monthly:
        return _getMonthlyPeriod(date);
    }
  }

  /// Get the previous pay period.
  ({DateTime start, DateTime end}) getPreviousPeriod(DateTime currentStart) {
    final previousDate = currentStart.subtract(const Duration(days: 1));
    return getPeriodForDate(previousDate);
  }

  /// Get the next pay period.
  ({DateTime start, DateTime end}) getNextPeriod(DateTime currentEnd) {
    final nextDate = currentEnd.add(const Duration(days: 1));
    return getPeriodForDate(nextDate);
  }

  ({DateTime start, DateTime end}) _getWeeklyPeriod(DateTime date) {
    // Find start of week
    var start = date;
    while (start.weekday != weekStartDay) {
      start = start.subtract(const Duration(days: 1));
    }
    start = DateTime(start.year, start.month, start.day);
    final end = start.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
    return (start: start, end: end);
  }

  ({DateTime start, DateTime end}) _getBiweeklyPeriod(DateTime date) {
    // Use a reference date (Jan 1, 2024 was a Monday)
    final reference = DateTime(2024, 1, 1);
    final daysSinceReference = date.difference(reference).inDays;
    final periodNumber = daysSinceReference ~/ 14;
    final start = reference.add(Duration(days: periodNumber * 14));
    final end = start.add(const Duration(days: 13, hours: 23, minutes: 59, seconds: 59));
    return (start: start, end: end);
  }

  ({DateTime start, DateTime end}) _getSemimonthlyPeriod(DateTime date) {
    if (date.day <= 15) {
      // First half of month
      final start = DateTime(date.year, date.month, 1);
      final end = DateTime(date.year, date.month, 15, 23, 59, 59);
      return (start: start, end: end);
    } else {
      // Second half of month
      final start = DateTime(date.year, date.month, 16);
      final nextMonth = date.month == 12
          ? DateTime(date.year + 1, 1, 1)
          : DateTime(date.year, date.month + 1, 1);
      final end = nextMonth.subtract(const Duration(seconds: 1));
      return (start: start, end: end);
    }
  }

  ({DateTime start, DateTime end}) _getMonthlyPeriod(DateTime date) {
    final start = DateTime(date.year, date.month, 1);
    final nextMonth = date.month == 12
        ? DateTime(date.year + 1, 1, 1)
        : DateTime(date.year, date.month + 1, 1);
    final end = nextMonth.subtract(const Duration(seconds: 1));
    return (start: start, end: end);
  }
}
