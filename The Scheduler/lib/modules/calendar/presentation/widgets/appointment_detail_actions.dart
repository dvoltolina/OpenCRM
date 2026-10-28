import 'package:flutter/material.dart';

import '../../../../data/models/appointment.dart';
import '../../../../data/models/client.dart';
import '../../../../data/models/security_context.dart';
import '../../../../data/repositories/appointments_repository.dart';
import '../../../pos/presentation/quick_sale_page.dart';

/// Actions card for appointment status updates and quick sale.
class AppointmentDetailActions extends StatelessWidget {
  const AppointmentDetailActions({
    super.key,
    required this.appointment,
    required this.securityContext,
    required this.appointmentsRepository,
    this.client,
    this.onStatusChanged,
  });

  final Appointment appointment;
  final SecurityContext securityContext;
  final AppointmentsRepository appointmentsRepository;
  final Client? client;
  final VoidCallback? onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canModify = appointment.status != AppointmentStatus.cancelled &&
        appointment.status != AppointmentStatus.completed;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actions',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (canModify &&
                    appointment.status != AppointmentStatus.confirmed)
                  FilledButton.icon(
                    onPressed: () => _updateStatus(context, AppointmentStatus.confirmed),
                    icon: const Icon(Icons.check),
                    label: const Text('Confirm'),
                  ),
                if (canModify)
                  FilledButton.tonalIcon(
                    onPressed: () => _updateStatus(context, AppointmentStatus.completed),
                    icon: const Icon(Icons.done_all),
                    label: const Text('Mark Complete'),
                  ),
                if (canModify)
                  OutlinedButton.icon(
                    onPressed: () => _updateStatus(context, AppointmentStatus.noShow),
                    icon: const Icon(Icons.person_off),
                    label: const Text('No Show'),
                  ),
                if (appointment.canBeCancelled)
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                    ),
                    onPressed: () => _confirmCancel(context),
                    icon: const Icon(Icons.cancel),
                    label: const Text('Cancel'),
                  ),
                // Sell Products button - navigates to POS with client/appointment pre-filled
                OutlinedButton.icon(
                  onPressed: () => _openQuickSale(context),
                  icon: const Icon(Icons.point_of_sale),
                  label: const Text('Sell Products'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openQuickSale(BuildContext context) {
    Navigator.pop(context); // Close the detail sheet
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuickSalePage(
          clientId: appointment.clientId,
          clientName: client?.fullName,
          appointmentId: appointment.id,
        ),
      ),
    );
  }

  Future<void> _updateStatus(BuildContext context, AppointmentStatus newStatus) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final updated = appointment.copyWith(status: newStatus);
      await appointmentsRepository.upsertAppointment(
        context: securityContext,
        appointment: updated,
      );
      if (!context.mounted) return;
      onStatusChanged?.call();
      messenger.showSnackBar(
        SnackBar(content: Text('Appointment marked as ${newStatus.name}')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to update: $e')),
      );
    }
  }

  Future<void> _confirmCancel(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment?'),
        content: const Text(
          'Are you sure you want to cancel this appointment? '
          'The client will be notified.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel Appointment'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await _updateStatus(context, AppointmentStatus.cancelled);
    }
  }
}
