import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/utils/safe_error_handler.dart';
import '../../../../data/models/appointment.dart';
import '../../../../data/models/location.dart';
import '../../../../data/models/provider.dart' as provider_model;
import '../../../../data/models/service.dart';

/// Handles CSV/PDF exports for appointment history while keeping the page lean
/// to satisfy the 600-line presentation rule.
class AppointmentHistoryExport {
  /// Exports appointments to CSV.
  ///
  /// [onExportComplete] is called after successful export with the record count
  /// for HIPAA audit logging purposes.
  static Future<void> exportCsv({
    required BuildContext context,
    required List<Appointment> appointments,
    required Map<String, Service> servicesCache,
    required Map<String, provider_model.Provider> providersCache,
    required Map<String, Location> locationsCache,
    Future<void> Function(int recordCount)? onExportComplete,
  }) async {
    if (appointments.isEmpty) {
      _showMessage(context, 'No appointments to export yet');
      return;
    }

    try {
      final rows = buildCsvRows(
        appointments: appointments,
        servicesCache: servicesCache,
        providersCache: providersCache,
        locationsCache: locationsCache,
      );
      final csvData = const ListToCsvConverter().convert(rows);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/appointment_history.csv');
      await file.writeAsString(csvData);

      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile(
              file.path,
              mimeType: 'text/csv',
              name: 'appointment_history.csv',
            ),
          ],
          subject: 'Appointment history',
        ),
      );

      // HIPAA audit callback
      await onExportComplete?.call(appointments.length);
    } catch (error) {
      if (context.mounted) {
        _showMessage(context, SafeErrorHandler.handle(error));
      }
    }
  }

  /// Exports appointments to PDF.
  ///
  /// [onExportComplete] is called after successful export with the record count
  /// for HIPAA audit logging purposes.
  static Future<void> exportPdf({
    required BuildContext context,
    required List<Appointment> appointments,
    required Map<String, Service> servicesCache,
    required Map<String, provider_model.Provider> providersCache,
    required Map<String, Location> locationsCache,
    Future<void> Function(int recordCount)? onExportComplete,
  }) async {
    if (appointments.isEmpty) {
      _showMessage(context, 'No appointments to export yet');
      return;
    }

    try {
      final dateFormat = DateFormat('MMM d, yyyy • h:mm a');
      final doc = pw.Document();
      final rows = buildPdfTableData(
        appointments: appointments,
        servicesCache: servicesCache,
        providersCache: providersCache,
        locationsCache: locationsCache,
        dateFormat: dateFormat,
      );

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (context) => [
            pw.Text(
              'Appointment History',
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Total: ${appointments.length}',
              style: const pw.TextStyle(fontSize: 12),
            ),
            pw.SizedBox(height: 16),
            pw.TableHelper.fromTextArray(
              headers: const [
                'Date & Time',
                'Status',
                'Service',
                'Provider',
                'Location',
              ],
              data: rows,
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blueGrey900,
              ),
              cellAlignment: pw.Alignment.centerLeft,
              cellStyle: const pw.TextStyle(fontSize: 10),
              columnWidths: const {
                0: pw.FlexColumnWidth(2),
                1: pw.FlexColumnWidth(1),
                2: pw.FlexColumnWidth(2),
                3: pw.FlexColumnWidth(2),
                4: pw.FlexColumnWidth(2),
              },
            ),
          ],
        ),
      );

      await Printing.sharePdf(
        bytes: await doc.save(),
        filename: 'appointment_history.pdf',
      );

      // HIPAA audit callback
      await onExportComplete?.call(appointments.length);
    } catch (error) {
      if (context.mounted) {
        _showMessage(context, SafeErrorHandler.handle(error));
      }
    }
  }

  /// Pure helper used by tests.
  static List<List<String>> buildCsvRows({
    required List<Appointment> appointments,
    required Map<String, Service> servicesCache,
    required Map<String, provider_model.Provider> providersCache,
    required Map<String, Location> locationsCache,
  }) {
    final dateFormat = DateFormat('yyyy-MM-dd');
    final timeFormat = DateFormat('h:mm a');
    final sorted = [...appointments]
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    return <List<String>>[
      [
        'Date',
        'Time',
        'Status',
        'Service',
        'Provider',
        'Location',
        'Appointment ID',
      ],
      for (final appointment in sorted)
        [
          dateFormat.format(appointment.startTime.toLocal()),
          timeFormat.format(appointment.startTime.toLocal()),
          appointment.status.name,
          servicesCache[appointment.serviceId]?.name ?? appointment.serviceId,
          providersCache[appointment.providerId]?.fullName ??
              appointment.providerId,
          locationsCache[appointment.locationId]?.name ??
              locationsCache[appointment.locationId]?.city ??
              '—',
          appointment.id,
        ],
    ];
  }

  /// Pure helper used by tests.
  static List<List<String>> buildPdfTableData({
    required List<Appointment> appointments,
    required Map<String, Service> servicesCache,
    required Map<String, provider_model.Provider> providersCache,
    required Map<String, Location> locationsCache,
    required DateFormat dateFormat,
  }) {
    final sorted = [...appointments]
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    return sorted.map((appointment) {
      final serviceName =
          servicesCache[appointment.serviceId]?.name ?? appointment.serviceId;
      final providerName =
          providersCache[appointment.providerId]?.fullName ??
              appointment.providerId;
      final locationName =
          locationsCache[appointment.locationId]?.name ??
              locationsCache[appointment.locationId]?.city ??
              '—';
      return [
        dateFormat.format(appointment.startTime.toLocal()),
        appointment.status.name,
        serviceName,
        providerName,
        locationName,
      ];
    }).toList();
  }

  static void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
