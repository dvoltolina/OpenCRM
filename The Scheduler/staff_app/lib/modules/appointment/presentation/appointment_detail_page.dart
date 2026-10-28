import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/local/staff_database.dart';
import '../../schedule/providers/schedule_providers.dart';
import '../providers/appointment_providers.dart';
import '../presentation/widgets/appointment_sections.dart';
import '../presentation/widgets/client_contact_actions.dart';

/// Appointment detail page with offline-capable actions.
class AppointmentDetailPage extends ConsumerStatefulWidget {
  const AppointmentDetailPage({super.key, required this.appointmentId});

  final String appointmentId;

  @override
  ConsumerState<AppointmentDetailPage> createState() =>
      _AppointmentDetailPageState();
}

class _AppointmentDetailPageState extends ConsumerState<AppointmentDetailPage> {
  bool _isBusy = false;

  @override
  Widget build(BuildContext context) {
    final appointmentAsync =
        ref.watch(appointmentProvider(widget.appointmentId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Detail'),
        actions: [
          appointmentAsync.when(
            data: (apt) => apt != null
                ? ClientContactActions(
                    phone: apt.clientPhone, address: apt.clientAddress)
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: appointmentAsync.when(
        data: (appointment) {
          if (appointment == null) {
            return const Center(child: Text('Appointment not found'));
          }
          final clientAsync = ref.watch(clientProvider(appointment.clientId));

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(
              appointmentProvider(widget.appointmentId),
            ),
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                StatusCard(appointment: appointment),
                TimeServiceCard(appointment: appointment),
                clientAsync.maybeWhen(
                  data: (client) => ClientInfoCard(
                    appointment: appointment,
                    client: client,
                  ),
                  orElse: () => ClientInfoCard(appointment: appointment),
                ),
                NotesCard(
                  initialNotes: appointment.staffNotes,
                  onSave: (notes) async {
                    final messenger = ScaffoldMessenger.of(context);
                    final actions = ref.read(appointmentActionsProvider);
                    if (actions != null) {
                      await actions.updateNotes(appointment.id, notes);
                      if (mounted) {
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Notes saved')),
                        );
                      }
                    }
                  },
                ),
                const SizedBox(height: 12),
                _ActionButtons(
                  appointment: appointment,
                  isBusy: _isBusy,
                  onCheckIn: () => _runAction(
                    () async {
                      await ref
                          .read(appointmentActionsProvider)
                          ?.checkIn(appointment.id);
                    },
                  ),
                  onComplete: () => _runAction(
                    () async {
                      await ref
                          .read(appointmentActionsProvider)
                          ?.complete(appointment.id);
                    },
                  ),
                  onNoShow: () => _runAction(
                    () async {
                      await ref
                          .read(appointmentActionsProvider)
                          ?.markNoShow(appointment.id);
                    },
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
      ),
    );
  }

  Future<void> _runAction(Future<void> Function() action) async {
    setState(() => _isBusy = true);
    try {
      await action();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Action queued for sync')),
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.appointment,
    required this.isBusy,
    required this.onCheckIn,
    required this.onComplete,
    required this.onNoShow,
  });

  final AppointmentsTableData appointment;
  final bool isBusy;
  final Future<void> Function() onCheckIn;
  final Future<void> Function() onComplete;
  final Future<void> Function() onNoShow;

  @override
  Widget build(BuildContext context) {
    final isCheckedIn = appointment.isCheckedIn;
    final isCompleted = appointment.isCompleted;
    final isCancelled = appointment.isCancelled || appointment.isNoShow;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Actions',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            if (!isCompleted && !isCancelled && !isCheckedIn) ...[
              FilledButton(
                onPressed: isBusy ? null : onCheckIn,
                child: const Text('Check In Client'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: isBusy ? null : onNoShow,
                child: const Text('Mark No-Show'),
              ),
            ],
            if (isCheckedIn && !isCompleted && !isCancelled) ...[
              FilledButton(
                onPressed: isBusy ? null : onComplete,
                child: const Text('Complete Appointment'),
              ),
            ],
            if (isCompleted)
              Text(
                'Appointment completed',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.green),
              ),
          ],
        ),
      ),
    );
  }
}
