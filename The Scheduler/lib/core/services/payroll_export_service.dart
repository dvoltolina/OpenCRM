import '../../../data/models/timesheet_summary.dart';
import '../../../data/models/time_entry.dart';

/// Supported payroll export formats.
enum PayrollFormat {
  /// Generic CSV format compatible with most payroll systems.
  genericCSV('Generic CSV', 'csv'),

  /// QuickBooks-compatible format.
  quickBooks('QuickBooks', 'iif'),

  /// ADP-compatible format.
  adp('ADP', 'csv');

  const PayrollFormat(this.displayName, this.fileExtension);

  final String displayName;
  final String fileExtension;
}

/// Service for exporting timesheet data to various payroll formats.
///
/// Supports multiple payroll system formats including:
/// - Generic CSV (universal compatibility)
/// - QuickBooks IIF format
/// - ADP CSV format
class PayrollExportService {
  /// Export timesheets to the specified payroll format.
  String exportTimesheets({
    required List<TimesheetSummary> timesheets,
    required PayrollFormat format,
    required DateTime periodStart,
    required DateTime periodEnd,
    String? companyName,
  }) {
    switch (format) {
      case PayrollFormat.genericCSV:
        return _exportGenericCSV(timesheets, periodStart, periodEnd);
      case PayrollFormat.quickBooks:
        return _exportQuickBooks(timesheets, periodStart, periodEnd, companyName);
      case PayrollFormat.adp:
        return _exportADP(timesheets, periodStart, periodEnd);
    }
  }

  /// Export time entries (detailed) to CSV.
  String exportTimeEntries({
    required List<TimeEntry> entries,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) {
    final buffer = StringBuffer();

    // Header
    buffer.writeln(
      'Employee ID,Employee Name,Date,Clock In,Clock Out,'
      'Hours Worked,Break Hours,Overtime Hours,Pay Rate,Gross Pay,'
      'Status,Location,Notes',
    );

    for (final entry in entries) {
      final hours = entry.durationHours;
      final breakHours = entry.breakHours;
      final workedHours = hours - breakHours;
      final overtimeHours = workedHours > 8 ? workedHours - 8 : 0.0;

      buffer.writeln(
        '${entry.staffId},'
        '"${_escapeCSV(entry.staffId)}",'  // Would need staff name from joined data
        '${_formatDate(entry.clockInTime)},'
        '${_formatTime(entry.clockInTime)},'
        '${entry.clockOutTime != null ? _formatTime(entry.clockOutTime!) : ''},'
        '${workedHours.toStringAsFixed(2)},'
        '${breakHours.toStringAsFixed(2)},'
        '${overtimeHours.toStringAsFixed(2)},'
        '0.00,'  // Pay rate would come from staff/business config
        '0.00,'  // Calculated from rate * hours
        '${entry.status.name},'
        '"${_escapeCSV(entry.clockInAddress ?? '')}",'
        '"${_escapeCSV(entry.staffNotes ?? '')}"',
      );
    }

    return buffer.toString();
  }

  /// Generic CSV format for universal compatibility.
  ///
  /// Columns:
  /// - Employee ID
  /// - Employee Name
  /// - Period Start
  /// - Period End
  /// - Regular Hours
  /// - Overtime Hours
  /// - Total Hours
  /// - Pay Rate (placeholder)
  /// - Regular Pay (placeholder)
  /// - Overtime Pay (placeholder)
  /// - Gross Pay (estimated)
  String _exportGenericCSV(
    List<TimesheetSummary> timesheets,
    DateTime periodStart,
    DateTime periodEnd,
  ) {
    final buffer = StringBuffer();

    // Header row
    buffer.writeln(
      'Employee ID,Employee Name,Employee Email,Period Start,Period End,'
      'Regular Hours,Overtime Hours,Total Hours,Break Hours,'
      'Pay Rate,Regular Pay,OT Pay,Gross Pay,Status',
    );

    // Data rows
    double totalRegular = 0;
    double totalOvertime = 0;
    double totalGross = 0;

    for (final ts in timesheets) {
      final hourlyRate = (ts.hourlyRateCents ?? 0) / 100.0;
      final regularPay = ts.regularHours * hourlyRate;
      final otPay = ts.overtimeHours * hourlyRate * 1.5;
      final grossPay = ts.estimatedPayAmount;

      totalRegular += ts.regularHours;
      totalOvertime += ts.overtimeHours;
      totalGross += grossPay;

      buffer.writeln(
        '${ts.staffId},'
        '"${_escapeCSV(ts.staffName)}",'
        '"${_escapeCSV(ts.staffEmail ?? '')}",'
        '${_formatDate(periodStart)},'
        '${_formatDate(periodEnd)},'
        '${ts.regularHours.toStringAsFixed(2)},'
        '${ts.overtimeHours.toStringAsFixed(2)},'
        '${ts.totalWorkedHours.toStringAsFixed(2)},'
        '${ts.totalBreakHours.toStringAsFixed(2)},'
        '${hourlyRate.toStringAsFixed(2)},'
        '${regularPay.toStringAsFixed(2)},'
        '${otPay.toStringAsFixed(2)},'
        '${grossPay.toStringAsFixed(2)},'
        '${ts.status.name}',
      );
    }

    // Summary row
    buffer.writeln();
    buffer.writeln(
      'TOTALS,${timesheets.length} employees,,,'
      '${_formatDate(periodStart)} - ${_formatDate(periodEnd)},'
      '${totalRegular.toStringAsFixed(2)},'
      '${totalOvertime.toStringAsFixed(2)},'
      '${(totalRegular + totalOvertime).toStringAsFixed(2)},'
      ',,,,'
      '${totalGross.toStringAsFixed(2)},',
    );

    return buffer.toString();
  }

  /// QuickBooks IIF format export.
  ///
  /// IIF (Intuit Interchange Format) is a tab-delimited format
  /// for importing data into QuickBooks.
  String _exportQuickBooks(
    List<TimesheetSummary> timesheets,
    DateTime periodStart,
    DateTime periodEnd,
    String? companyName,
  ) {
    final buffer = StringBuffer();

    // IIF Header
    buffer.writeln('!TIMERHDR\tVER\tREL\tCOMPANYNAME\tIMPORTEDBEFORE\tFROMMODIFIEDDATE\tTOMODIFIEDDATE');
    buffer.writeln('TIMERHDR\t8\t0\t${companyName ?? "Company"}\tN\t${_formatDateUS(periodStart)}\t${_formatDateUS(periodEnd)}');
    buffer.writeln('!TIMEACT\tDATE\tJOB\tEMP\tITEM\tPITEM\tDURATION\tNOTE');

    for (final ts in timesheets) {
      for (final entry in ts.entries) {
        if (entry.clockOutTime != null) {
          final duration = _formatDurationQB(entry.durationHours);
          buffer.writeln(
            'TIMEACT\t'
            '${_formatDateUS(entry.clockInTime)}\t'
            '\t'  // Job (empty)
            '"${_escapeCSV(ts.staffName)}"\t'
            'Regular\t'  // Item
            '\t'  // Parent Item
            '$duration\t'
            '"${_escapeCSV(entry.staffNotes ?? '')}"',
          );
        }
      }
    }

    return buffer.toString();
  }

  /// ADP format export.
  ///
  /// ADP accepts various CSV formats. This implements
  /// a common format compatible with ADP Workforce Now.
  String _exportADP(
    List<TimesheetSummary> timesheets,
    DateTime periodStart,
    DateTime periodEnd,
  ) {
    final buffer = StringBuffer();

    // ADP Header
    buffer.writeln(
      'File Number,Employee ID,Employee Name,Pay Period Start,Pay Period End,'
      'Earnings Code,Hours,Amount,Rate',
    );

    int fileNumber = 1;

    for (final ts in timesheets) {
      final hourlyRate = (ts.hourlyRateCents ?? 0) / 100.0;

      // Regular hours row
      if (ts.regularHours > 0) {
        buffer.writeln(
          '$fileNumber,'
          '${ts.staffId},'
          '"${_escapeCSV(ts.staffName)}",'
          '${_formatDateUS(periodStart)},'
          '${_formatDateUS(periodEnd)},'
          'REG,'
          '${ts.regularHours.toStringAsFixed(2)},'
          '${(ts.regularHours * hourlyRate).toStringAsFixed(2)},'
          '${hourlyRate.toStringAsFixed(2)}',
        );
        fileNumber++;
      }

      // Overtime hours row
      if (ts.overtimeHours > 0) {
        buffer.writeln(
          '$fileNumber,'
          '${ts.staffId},'
          '"${_escapeCSV(ts.staffName)}",'
          '${_formatDateUS(periodStart)},'
          '${_formatDateUS(periodEnd)},'
          'OT,'
          '${ts.overtimeHours.toStringAsFixed(2)},'
          '${(ts.overtimeHours * hourlyRate * 1.5).toStringAsFixed(2)},'
          '${(hourlyRate * 1.5).toStringAsFixed(2)}',
        );
        fileNumber++;
      }
    }

    return buffer.toString();
  }

  /// Format date as YYYY-MM-DD.
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Format date as MM/DD/YYYY (US format for QuickBooks/ADP).
  String _formatDateUS(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  /// Format time as HH:MM.
  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  /// Format duration for QuickBooks (HH:MM format).
  String _formatDurationQB(double hours) {
    final h = hours.floor();
    final m = ((hours - h) * 60).round();
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  /// Escape special characters for CSV.
  String _escapeCSV(String value) {
    return value.replaceAll('"', '""');
  }
}

/// Payroll export result with metadata.
class PayrollExportResult {
  const PayrollExportResult({
    required this.content,
    required this.format,
    required this.fileName,
    required this.periodStart,
    required this.periodEnd,
    required this.employeeCount,
    required this.totalHours,
    required this.totalGrossPay,
  });

  final String content;
  final PayrollFormat format;
  final String fileName;
  final DateTime periodStart;
  final DateTime periodEnd;
  final int employeeCount;
  final double totalHours;
  final double totalGrossPay;

  /// Generate a suggested filename.
  static String generateFileName({
    required PayrollFormat format,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) {
    final startStr = '${periodStart.year}${periodStart.month.toString().padLeft(2, '0')}${periodStart.day.toString().padLeft(2, '0')}';
    final endStr = '${periodEnd.year}${periodEnd.month.toString().padLeft(2, '0')}${periodEnd.day.toString().padLeft(2, '0')}';
    return 'payroll_${startStr}_$endStr.${format.fileExtension}';
  }
}
