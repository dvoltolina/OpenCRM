import 'dart:io';

import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../data/models/analytics_metrics.dart';
import '../../data/models/audit_log.dart';
import '../../data/models/security_context.dart';
import '../../data/repositories/audit_log_repository.dart';

/// Service for exporting analytics reports to various formats.
///
/// All exports are audit-logged for HIPAA compliance using [AuditLogRepository].
class ExportService {
  ExportService({AuditLogRepository? auditLogRepository})
      : _auditLogRepository = auditLogRepository ?? AuditLogRepository();

  final AuditLogRepository _auditLogRepository;

  /// Export metrics to CSV format.
  ///
  /// Logs a `dataExport` audit event on success with report type and date range.
  Future<File> exportToCsv(
    AnalyticsMetrics metrics, {
    required String filename,
    required SecurityContext context,
    Directory? outputDirectory,
  }) async {
    final rows = <List<String>>[
      // Header
      ['Metric', 'Value'],
      // Appointment metrics
      ['Total Appointments', metrics.totalAppointments.toString()],
      ['Confirmed Appointments', metrics.confirmedAppointments.toString()],
      ['Canceled Appointments', metrics.canceledAppointments.toString()],
      ['Completed Appointments', metrics.completedAppointments.toString()],
      ['No-Show Appointments', metrics.noShowAppointments.toString()],
      // Revenue metrics
      ['Total Revenue', '\$${metrics.totalRevenueDollars.toStringAsFixed(2)}'],
      ['Paid Revenue', '\$${metrics.paidRevenueDollars.toStringAsFixed(2)}'],
      [
        'Pending Revenue',
        '\$${metrics.pendingRevenueDollars.toStringAsFixed(2)}'
      ],
      // Client metrics
      ['Total Clients', metrics.totalClients.toString()],
      ['New Clients', metrics.newClients.toString()],
      ['Returning Clients', metrics.returningClients.toString()],
      ['Active Clients', metrics.activeClients.toString()],
      // Performance metrics
      [
        'Cancellation Rate',
        '${(metrics.cancellationRate * 100).toStringAsFixed(1)}%'
      ],
      ['No-Show Rate', '${(metrics.noShowRate * 100).toStringAsFixed(1)}%'],
      [
        'Utilization Rate',
        '${(metrics.utilizationRate * 100).toStringAsFixed(1)}%'
      ],
      [
        'Avg Booking Lead Time',
        '${metrics.averageBookingLeadDays.toStringAsFixed(1)} days'
      ],
    ];

    // Add service breakdown
    if (metrics.appointmentsByService.isNotEmpty) {
      rows.add(['', '']); // Empty row
      rows.add(['Service', 'Appointments']);
      for (final entry in metrics.appointmentsByService.entries) {
        rows.add([entry.key, entry.value.toString()]);
      }
    }

    // Add provider breakdown
    if (metrics.appointmentsByProvider.isNotEmpty) {
      rows.add(['', '']); // Empty row
      rows.add(['Provider', 'Appointments']);
      for (final entry in metrics.appointmentsByProvider.entries) {
        rows.add([entry.key, entry.value.toString()]);
      }
    }

    final csvData = const ListToCsvConverter().convert(rows);

    final directory =
        outputDirectory ?? await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$filename');
    await file.writeAsString(csvData);

    // Log data export for HIPAA compliance (non-blocking)
    await _logExportEvent(
      context: context,
      reportType: 'csv',
      dateRangeDays: metrics.endDate.difference(metrics.startDate).inDays,
    );

    return file;
  }

  /// Export metrics to PDF format.
  ///
  /// Logs a `dataExport` audit event on success with report type and date range.
  Future<File> exportToPdf(
    AnalyticsMetrics metrics, {
    required String filename,
    required String businessName,
    required SecurityContext context,
    Directory? outputDirectory,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('MMM d, yyyy');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header
          pw.Header(
            level: 0,
            child: pw.Text(
              '$businessName - Analytics Report',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Report Period: ${dateFormat.format(metrics.startDate)} - ${dateFormat.format(metrics.endDate)}',
            style: const pw.TextStyle(fontSize: 12),
          ),
          pw.Divider(),
          pw.SizedBox(height: 16),

          // Key Metrics Section
          pw.Header(level: 1, text: 'Key Metrics'),
          pw.SizedBox(height: 8),
          _buildMetricsTable([
            ['Total Appointments', metrics.totalAppointments.toString()],
            ['Confirmed', metrics.confirmedAppointments.toString()],
            ['Completed', metrics.completedAppointments.toString()],
            ['Canceled', metrics.canceledAppointments.toString()],
            ['No-Shows', metrics.noShowAppointments.toString()],
          ]),
          pw.SizedBox(height: 16),

          // Revenue Section
          pw.Header(level: 1, text: 'Revenue'),
          pw.SizedBox(height: 8),
          _buildMetricsTable([
            [
              'Total Revenue',
              '\$${metrics.totalRevenueDollars.toStringAsFixed(2)}'
            ],
            [
              'Paid Revenue',
              '\$${metrics.paidRevenueDollars.toStringAsFixed(2)}'
            ],
            [
              'Pending Revenue',
              '\$${metrics.pendingRevenueDollars.toStringAsFixed(2)}'
            ],
            [
              'Avg per Appointment',
              '\$${metrics.averageRevenuePerAppointment.toStringAsFixed(2)}'
            ],
          ]),
          pw.SizedBox(height: 16),

          // Client Metrics Section
          pw.Header(level: 1, text: 'Client Metrics'),
          pw.SizedBox(height: 8),
          _buildMetricsTable([
            ['Total Clients', metrics.totalClients.toString()],
            ['New Clients', metrics.newClients.toString()],
            ['Returning Clients', metrics.returningClients.toString()],
            ['Active Clients', metrics.activeClients.toString()],
            [
              'Retention Rate',
              '${(metrics.clientRetentionRate * 100).toStringAsFixed(1)}%'
            ],
          ]),
          pw.SizedBox(height: 16),

          // Performance Section
          pw.Header(level: 1, text: 'Performance'),
          pw.SizedBox(height: 8),
          _buildMetricsTable([
            [
              'Cancellation Rate',
              '${(metrics.cancellationRate * 100).toStringAsFixed(1)}%'
            ],
            [
              'No-Show Rate',
              '${(metrics.noShowRate * 100).toStringAsFixed(1)}%'
            ],
            [
              'Utilization Rate',
              '${(metrics.utilizationRate * 100).toStringAsFixed(1)}%'
            ],
            [
              'Completion Rate',
              '${(metrics.completionRate * 100).toStringAsFixed(1)}%'
            ],
            [
              'Avg Booking Lead Time',
              '${metrics.averageBookingLeadDays.toStringAsFixed(1)} days'
            ],
          ]),

          // Service Breakdown
          if (metrics.appointmentsByService.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            pw.Header(level: 1, text: 'Appointments by Service'),
            pw.SizedBox(height: 8),
            _buildMetricsTable(
              metrics.appointmentsByService.entries
                  .map((e) => [e.key, e.value.toString()])
                  .toList(),
            ),
          ],

          // Provider Breakdown
          if (metrics.appointmentsByProvider.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            pw.Header(level: 1, text: 'Appointments by Provider'),
            pw.SizedBox(height: 8),
            _buildMetricsTable(
              metrics.appointmentsByProvider.entries
                  .map((e) => [e.key, e.value.toString()])
                  .toList(),
            ),
          ],

          // Footer
          pw.SizedBox(height: 32),
          pw.Divider(),
          pw.Text(
            'Generated on ${DateFormat('MMM d, yyyy h:mm a').format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
          ),
        ],
      ),
    );

    final directory =
        outputDirectory ?? await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$filename');
    await file.writeAsBytes(await pdf.save());

    // Log data export for HIPAA compliance (non-blocking)
    await _logExportEvent(
      context: context,
      reportType: 'pdf',
      dateRangeDays: metrics.endDate.difference(metrics.startDate).inDays,
    );

    return file;
  }

  /// Share/print PDF
  Future<void> sharePdf(
    AnalyticsMetrics metrics, {
    required String businessName,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('MMM d, yyyy');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              '$businessName - Analytics Report',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Text(
            'Report Period: ${dateFormat.format(metrics.startDate)} - ${dateFormat.format(metrics.endDate)}',
            style: const pw.TextStyle(fontSize: 12),
          ),
          pw.Divider(),
          // Add content similar to exportToPdf
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename:
          'analytics-${DateFormat('yyyy-MM-dd').format(DateTime.now())}.pdf',
    );
  }

  pw.Widget _buildMetricsTable(List<List<String>> data) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: data.map((row) {
        return pw.TableRow(
          children: row.map((cell) {
            return pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(cell),
            );
          }).toList(),
        );
      }).toList(),
    );
  }

  /// Logs a data export event for HIPAA audit trail.
  ///
  /// Errors are swallowed to ensure export operations are non-blocking.
  Future<void> _logExportEvent({
    required SecurityContext context,
    required String reportType,
    required int dateRangeDays,
  }) async {
    try {
      await _auditLogRepository.logEvent(
        AuditLogEntry(
          businessId: context.businessId,
          userId: context.userId,
          actionType: AuditActionType.dataExport,
          entityType: 'AnalyticsReport',
          entityId: context.businessId, // Report scoped to business
          metadata: {
            'reportType': reportType,
            'dateRangeDays': dateRangeDays,
          },
        ),
      );
    } catch (_) {
      // Audit log failures must never block primary user actions
    }
  }
}
