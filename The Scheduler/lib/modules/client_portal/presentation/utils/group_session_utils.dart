import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/appointment.dart';
import '../../../../data/models/location.dart';
import '../../../../data/models/provider.dart';
import '../../../../data/models/service.dart';

/// Helper utilities for group session UX (ICS export, lookups).
class GroupSessionUtils {
  static Future<void> copyIcsToClipboard({
    required BuildContext context,
    required Appointment session,
    required String serviceName,
    required String providerName,
    required String locationName,
  }) async {
    final startUtc = session.startTime.toUtc();
    final endUtc = session.endTime.toUtc();
    final buffer = StringBuffer()
      ..writeln('BEGIN:VCALENDAR')
      ..writeln('VERSION:2.0')
      ..writeln('PRODID:-//The Scheduler//Group Session//EN')
      ..writeln('BEGIN:VEVENT')
      ..writeln('UID:${session.id}@scheduler.example.com')
      ..writeln(
        'DTSTAMP:${DateFormat("yyyyMMdd'T'HHmmss'Z'").format(DateTime.now().toUtc())}',
      )
      ..writeln(
        'DTSTART:${DateFormat("yyyyMMdd'T'HHmmss'Z'").format(startUtc)}',
      )
      ..writeln(
        'DTEND:${DateFormat("yyyyMMdd'T'HHmmss'Z'").format(endUtc)}',
      )
      ..writeln('SUMMARY:$serviceName')
      ..writeln('DESCRIPTION:Provider: $providerName\\n${session.notes ?? ''}')
      ..writeln('LOCATION:$locationName')
      ..writeln('END:VEVENT')
      ..writeln('END:VCALENDAR');

    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ICS copied. Paste into your calendar.')),
    );
  }

  static String lookupServiceName(String id, List<Service> services) {
    final match = services.where((service) => service.id == id);
    if (match.isEmpty) return id;
    return match.first.name;
  }

  static String lookupProviderName(String id, List<Provider> providers) {
    final match = providers.where((provider) => provider.id == id);
    if (match.isEmpty) return id;
    return match.first.fullName;
  }

  static String lookupLocationName(String id, List<Location> locations) {
    final match = locations.where((location) => location.id == id);
    if (match.isEmpty) return id;
    return match.first.name ?? id;
  }
}
