import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../data/models/appointment.dart';
import '../../../../data/models/provider.dart' as provider_model;

/// Card with appointment management actions.
class AppointmentActionsCard extends StatelessWidget {
  const AppointmentActionsCard({
    required this.appointment,
    required this.provider,
    required this.onReschedule,
    required this.onCancel,
    super.key,
  });

  final Appointment appointment;
  final provider_model.Provider provider;
  final VoidCallback onReschedule;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPastAppointment = appointment.endTime.isBefore(DateTime.now());
    final isCancelled = appointment.status == AppointmentStatus.cancelled;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Manage Appointment',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (!isPastAppointment && !isCancelled) ...[
              FilledButton.icon(
                onPressed: onReschedule,
                icon: const Icon(Icons.calendar_today_outlined),
                label: const Text('Reschedule'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onCancel,
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Cancel Appointment'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  foregroundColor: theme.colorScheme.error,
                  side: BorderSide(color: theme.colorScheme.error),
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isPastAppointment
                            ? 'This appointment has already occurred.'
                            : 'This appointment has been cancelled.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                final phone = provider.phone ?? 'N/A';
                Clipboard.setData(ClipboardData(text: phone));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Phone number copied')),
                );
              },
              icon: const Icon(Icons.contact_phone_outlined),
              label: const Text('Contact Provider'),
            ),
          ],
        ),
      ),
    );
  }
}
