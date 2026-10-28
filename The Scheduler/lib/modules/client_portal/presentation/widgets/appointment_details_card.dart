import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/appointment.dart';
import '../../../../data/models/location.dart';
import '../../../../data/models/provider.dart' as provider_model;
import '../../../../data/models/service.dart';
import 'appointment_detail_row.dart';

/// Card displaying appointment details.
class AppointmentDetailsCard extends StatelessWidget {
  const AppointmentDetailsCard({
    required this.appointment,
    required this.service,
    required this.provider,
    required this.location,
    required this.dateFormat,
    required this.timeFormat,
    super.key,
  });

  final Appointment appointment;
  final Service service;
  final provider_model.Provider provider;
  final Location location;
  final DateFormat dateFormat;
  final DateFormat timeFormat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Appointment Details',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            AppointmentDetailRow(
              icon: Icons.event_outlined,
              label: 'Date',
              value: dateFormat.format(appointment.startTime),
            ),
            const Divider(height: 24),
            AppointmentDetailRow(
              icon: Icons.access_time_outlined,
              label: 'Time',
              value:
                  '${timeFormat.format(appointment.startTime)} - '
                  '${timeFormat.format(appointment.endTime)}',
            ),
            const Divider(height: 24),
            AppointmentDetailRow(
              icon: Icons.design_services_outlined,
              label: 'Service',
              value: service.name,
              subtitle: service.durationDisplay,
            ),
            const Divider(height: 24),
            AppointmentDetailRow(
              icon: Icons.person_outline,
              label: 'Provider',
              value: provider.fullName,
              subtitle: provider.email,
            ),
            const Divider(height: 24),
            AppointmentDetailRow(
              icon: Icons.location_on_outlined,
              label: 'Location',
              value: location.name ?? location.address,
              subtitle: location.name != null ? location.address : null,
            ),
            if (appointment.notes != null) ...[
              const Divider(height: 24),
              AppointmentDetailRow(
                icon: Icons.notes_outlined,
                label: 'Notes',
                value: appointment.notes!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
