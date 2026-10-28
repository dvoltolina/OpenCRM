import '../../data/models/security_context.dart';
import '../../data/models/time_entry.dart';
import '../../data/models/timesheet_summary.dart';
import '../../data/repositories/providers_repository.dart';
import '../../data/repositories/time_entry_repository.dart';

/// Service for generating timesheet summaries and performing payroll calculations.
///
/// This service aggregates time entries into timesheet summaries for individual
/// staff members or the entire business, calculating regular hours, overtime,
/// and estimated pay.
class TimesheetService {
  TimesheetService({
    TimeEntryRepository? timeEntryRepository,
    ProvidersRepository? providersRepository,
    OvertimeCalculator? overtimeCalculator,
    PayPeriodCalculator? payPeriodCalculator,
  })  : _timeEntryRepository = timeEntryRepository ?? TimeEntryRepository(),
        _providersRepository = providersRepository ?? ProvidersRepository(),
        _overtimeCalculator = overtimeCalculator ?? const OvertimeCalculator(),
        _payPeriodCalculator =
            payPeriodCalculator ?? const PayPeriodCalculator();

  final TimeEntryRepository _timeEntryRepository;
  final ProvidersRepository _providersRepository;
  final OvertimeCalculator _overtimeCalculator;
  final PayPeriodCalculator _payPeriodCalculator;

  /// Get timesheet summary for a specific staff member.
  ///
  /// Calculates total hours, overtime, and estimated pay for the given period.
  Future<TimesheetSummary> getStaffTimesheet({
    required SecurityContext context,
    required String staffId,
    required DateTime periodStart,
    required DateTime periodEnd,
    int? hourlyRateCents,
  }) async {
    // Get time entries for the staff member
    final entries = await _timeEntryRepository.getEntriesByStaff(
      context: context,
      staffId: staffId,
      startDate: periodStart,
      endDate: periodEnd,
    );

    // Get staff info
    final provider = await _providersRepository.getProvider(
      context: context,
      providerId: staffId,
    );

    return _buildTimesheetSummary(
      staffId: staffId,
      staffName: provider?.fullName ?? 'Unknown Staff',
      staffEmail: provider?.email,
      periodStart: periodStart,
      periodEnd: periodEnd,
      entries: entries,
      hourlyRateCents: hourlyRateCents,
    );
  }

  /// Get timesheet summaries for all staff in the business.
  ///
  /// Only admins/managers can access this.
  Future<List<TimesheetSummary>> getAllStaffTimesheets({
    required SecurityContext context,
    required DateTime periodStart,
    required DateTime periodEnd,
    Map<String, int>? staffHourlyRates, // staffId -> hourlyRateCents
  }) async {
    if (!context.role.canManageAllAppointments) {
      throw SecurityException(
          'Only administrators can view all staff timesheets');
    }

    // Get all providers in the business
    final providers = await _providersRepository
        .watchProviders(context)
        .first;

    // Build timesheet for each provider
    final timesheets = <TimesheetSummary>[];

    for (final provider in providers) {
      final entries = await _timeEntryRepository.getEntriesByStaff(
        context: context,
        staffId: provider.id,
        startDate: periodStart,
        endDate: periodEnd,
      );

      // Skip staff with no entries
      if (entries.isEmpty) continue;

      final hourlyRate = staffHourlyRates?[provider.id];
      final summary = _buildTimesheetSummary(
        staffId: provider.id,
        staffName: provider.fullName,
        staffEmail: provider.email,
        periodStart: periodStart,
        periodEnd: periodEnd,
        entries: entries,
        hourlyRateCents: hourlyRate,
      );

      timesheets.add(summary);
    }

    // Sort by staff name
    timesheets.sort((a, b) => a.staffName.compareTo(b.staffName));

    return timesheets;
  }

  /// Get the current pay period dates.
  ({DateTime start, DateTime end}) getCurrentPayPeriod() {
    return _payPeriodCalculator.getPeriodForDate(DateTime.now());
  }

  /// Get pay period for a specific date.
  ({DateTime start, DateTime end}) getPayPeriodForDate(DateTime date) {
    return _payPeriodCalculator.getPeriodForDate(date);
  }

  /// Get the previous pay period dates.
  ({DateTime start, DateTime end}) getPreviousPayPeriod(DateTime currentStart) {
    return _payPeriodCalculator.getPreviousPeriod(currentStart);
  }

  /// Get the next pay period dates.
  ({DateTime start, DateTime end}) getNextPayPeriod(DateTime currentEnd) {
    return _payPeriodCalculator.getNextPeriod(currentEnd);
  }

  /// Calculate total labor cost for a pay period.
  Future<double> calculateLaborCost({
    required SecurityContext context,
    required DateTime periodStart,
    required DateTime periodEnd,
    required Map<String, int> staffHourlyRates,
  }) async {
    final timesheets = await getAllStaffTimesheets(
      context: context,
      periodStart: periodStart,
      periodEnd: periodEnd,
      staffHourlyRates: staffHourlyRates,
    );

    return timesheets.fold<double>(
      0,
      (sum, ts) => sum + ts.estimatedPayAmount,
    );
  }

  /// Get summary statistics for a pay period.
  Future<PayPeriodStats> getPayPeriodStats({
    required SecurityContext context,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) async {
    final timesheets = await getAllStaffTimesheets(
      context: context,
      periodStart: periodStart,
      periodEnd: periodEnd,
    );

    int totalWorkedMinutes = 0;
    int totalOvertimeMinutes = 0;
    int totalShifts = 0;
    int pendingApprovals = 0;
    int approvedEntries = 0;
    int rejectedEntries = 0;

    for (final ts in timesheets) {
      totalWorkedMinutes += ts.totalWorkedMinutes;
      totalOvertimeMinutes += ts.overtimeMinutes;
      totalShifts += ts.totalShifts;
      pendingApprovals += ts.pendingEntriesCount;
      approvedEntries += ts.approvedEntriesCount;
      rejectedEntries += ts.rejectedEntriesCount;
    }

    return PayPeriodStats(
      periodStart: periodStart,
      periodEnd: periodEnd,
      totalStaff: timesheets.length,
      totalWorkedHours: totalWorkedMinutes / 60.0,
      totalOvertimeHours: totalOvertimeMinutes / 60.0,
      totalShifts: totalShifts,
      pendingApprovals: pendingApprovals,
      approvedEntries: approvedEntries,
      rejectedEntries: rejectedEntries,
    );
  }

  /// Export timesheet data as CSV.
  String exportToCSV({
    required List<TimesheetSummary> timesheets,
    bool includeEntryDetails = false,
  }) {
    final buffer = StringBuffer();

    // Header
    buffer.writeln(
      'Staff Name,Staff Email,Period Start,Period End,'
      'Total Hours,Regular Hours,Overtime Hours,Total Breaks (hrs),'
      'Shifts,Estimated Pay,Status',
    );

    for (final ts in timesheets) {
      buffer.writeln(
        '"${ts.staffName}",'
        '"${ts.staffEmail ?? ''}",'
        '"${_formatDate(ts.periodStart)}",'
        '"${_formatDate(ts.periodEnd)}",'
        '${ts.totalWorkedHours.toStringAsFixed(2)},'
        '${ts.regularHours.toStringAsFixed(2)},'
        '${ts.overtimeHours.toStringAsFixed(2)},'
        '${ts.totalBreakHours.toStringAsFixed(2)},'
        '${ts.totalShifts},'
        '\$${ts.estimatedPayAmount.toStringAsFixed(2)},'
        '${ts.status.name}',
      );
    }

    if (includeEntryDetails) {
      buffer.writeln();
      buffer.writeln('--- Entry Details ---');
      buffer.writeln(
        'Staff Name,Date,Clock In,Clock Out,Worked Hours,Break Hours,'
        'Status,Staff Notes',
      );

      for (final ts in timesheets) {
        for (final entry in ts.entries) {
          buffer.writeln(
            '"${ts.staffName}",'
            '"${_formatDate(entry.clockInTime)}",'
            '"${_formatTime(entry.clockInTime)}",'
            '"${entry.clockOutTime != null ? _formatTime(entry.clockOutTime!) : 'Active'}",'
            '${entry.durationHours.toStringAsFixed(2)},'
            '${entry.breakHours.toStringAsFixed(2)},'
            '${entry.status.name},'
            '"${entry.staffNotes ?? ''}"',
          );
        }
      }
    }

    return buffer.toString();
  }

  // ---------------------------------------------------------------------------
  // Private Helpers
  // ---------------------------------------------------------------------------

  TimesheetSummary _buildTimesheetSummary({
    required String staffId,
    required String staffName,
    String? staffEmail,
    required DateTime periodStart,
    required DateTime periodEnd,
    required List<TimeEntry> entries,
    int? hourlyRateCents,
  }) {
    // Calculate totals from completed entries
    final completedEntries =
        entries.where((e) => e.clockOutTime != null).toList();

    final totalWorkedMinutes = completedEntries.fold<int>(
      0,
      (sum, e) => sum + (e.workedMinutes ?? 0),
    );

    final totalBreakMinutes = completedEntries.fold<int>(
      0,
      (sum, e) => sum + (e.breakMinutes ?? 0),
    );

    // Calculate overtime
    final (:regularMinutes, :overtimeMinutes) =
        _overtimeCalculator.calculate(completedEntries);

    // Calculate estimated pay
    double estimatedPay = 0;
    if (hourlyRateCents != null && hourlyRateCents > 0) {
      estimatedPay = _overtimeCalculator.calculateEstimatedPay(
        regularMinutes: regularMinutes,
        overtimeMinutes: overtimeMinutes,
        hourlyRateCents: hourlyRateCents,
      );
    }

    // Determine overall status
    final status = _calculateTimesheetStatus(entries);

    return TimesheetSummary(
      staffId: staffId,
      staffName: staffName,
      staffEmail: staffEmail,
      periodStart: periodStart,
      periodEnd: periodEnd,
      totalWorkedMinutes: totalWorkedMinutes,
      totalBreakMinutes: totalBreakMinutes,
      totalShifts: completedEntries.length,
      regularMinutes: regularMinutes,
      overtimeMinutes: overtimeMinutes,
      hourlyRateCents: hourlyRateCents,
      estimatedPayAmount: estimatedPay,
      entries: entries,
      status: status,
    );
  }

  TimesheetStatus _calculateTimesheetStatus(List<TimeEntry> entries) {
    if (entries.isEmpty) return TimesheetStatus.draft;

    final hasActive = entries.any((e) => e.status == TimeEntryStatus.active);
    final hasPending = entries.any((e) => e.status == TimeEntryStatus.pending);
    final hasRejected = entries.any((e) => e.status == TimeEntryStatus.rejected);
    final allApproved = entries.every((e) => e.status == TimeEntryStatus.approved);

    if (hasActive || hasRejected) {
      return TimesheetStatus.draft;
    } else if (hasPending) {
      return TimesheetStatus.submitted;
    } else if (allApproved) {
      return TimesheetStatus.approved;
    }

    return TimesheetStatus.draft;
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

/// Statistics for a pay period.
class PayPeriodStats {
  final DateTime periodStart;
  final DateTime periodEnd;
  final int totalStaff;
  final double totalWorkedHours;
  final double totalOvertimeHours;
  final int totalShifts;
  final int pendingApprovals;
  final int approvedEntries;
  final int rejectedEntries;

  const PayPeriodStats({
    required this.periodStart,
    required this.periodEnd,
    required this.totalStaff,
    required this.totalWorkedHours,
    required this.totalOvertimeHours,
    required this.totalShifts,
    required this.pendingApprovals,
    required this.approvedEntries,
    required this.rejectedEntries,
  });

  /// Total entries across all staff
  int get totalEntries => pendingApprovals + approvedEntries + rejectedEntries;

  /// Percentage of entries approved
  double get approvalRate =>
      totalEntries > 0 ? (approvedEntries / totalEntries) * 100 : 0;

  /// Whether there are entries needing attention
  bool get hasItemsNeedingAttention => pendingApprovals > 0 || rejectedEntries > 0;
}
