import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/magic_link_appointment_loader.dart';

/// Displays a summary of the appointment being rescheduled
class AppointmentSummaryCard extends StatelessWidget {
  const AppointmentSummaryCard({
    required this.data,
    super.key,
  });

  final MagicLinkAppointmentData data;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, MMM d');
    final timeFormat = DateFormat('h:mm a');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data.service.name,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '${dateFormat.format(data.appointment.startTime)} • '
              '${timeFormat.format(data.appointment.startTime)}',
            ),
            const SizedBox(height: 8),
            Text(
              data.provider.fullName,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (data.location.name != null) ...[
              const SizedBox(height: 4),
              Text(
                data.location.name!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
