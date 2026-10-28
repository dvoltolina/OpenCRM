import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/appointment.dart';
import '../../../../data/models/provider.dart' as model;
import '../../../../data/models/client.dart';
import '../../../../core/providers/providers.dart';
import '../../providers/front_desk_providers.dart';
import '../../services/front_desk_service.dart';

/// Schedule panel showing appointments grid for all providers.
///
/// Displays time-based schedule with color-coded appointment statuses.
/// Supports quick actions on appointments (check-in, mark no-show, etc.).
class SchedulePanel extends ConsumerWidget {
  const SchedulePanel({super.key});

  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return Colors.grey;
      case AppointmentStatus.confirmed:
        return Colors.blue;
      case AppointmentStatus.completed:
        return Colors.purple;
      case AppointmentStatus.noShow:
        return Colors.red;
      case AppointmentStatus.cancelled:
        return Colors.orange;
    }
  }

  String _getStatusLabel(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return 'Pending';
      case AppointmentStatus.confirmed:
        return 'Confirmed';
      case AppointmentStatus.completed:
        return 'Completed';
      case AppointmentStatus.noShow:
        return 'No-Show';
      case AppointmentStatus.cancelled:
        return 'Cancelled';
    }
  }

  Future<void> _showAppointmentActions(
    BuildContext context,
    WidgetRef ref,
    Appointment appointment,
  ) async {
    final securityContext = ref.read(securityContextProvider).valueOrNull;
    if (securityContext == null) return;

    final action = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Appointment Actions'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Time: ${DateFormat.jm().format(appointment.startTime)}'),
            Text('Service: ${appointment.serviceType ?? 'N/A'}'),
            const SizedBox(height: 8),
            Text('Status: ${_getStatusLabel(appointment.status)}'),
          ],
        ),
        actions: [
          if (appointment.status != AppointmentStatus.confirmed)
            TextButton.icon(
              icon: const Icon(Icons.check_circle),
              label: const Text('Check In'),
              onPressed: () => Navigator.pop(context, 'check_in'),
            ),
          if (appointment.status != AppointmentStatus.noShow)
            TextButton.icon(
              icon: const Icon(Icons.cancel),
              label: const Text('Mark No-Show'),
              onPressed: () => Navigator.pop(context, 'no_show'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );

    if (action == null || !context.mounted) return;

    final service = FrontDeskService(
      appointmentsRepository: ref.read(appointmentsRepositoryProvider),
      waitlistRepository: ref.read(waitlistRepositoryProvider),
    );

    try {
      if (action == 'check_in') {
        await service.checkInClient(securityContext, appointment.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Client checked in successfully')),
          );
        }
      } else if (action == 'no_show') {
        await service.markNoShow(securityContext, appointment.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Marked as no-show')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Operation failed')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentsByProvider = ref.watch(appointmentsByProviderProvider);
    final providersAsync = ref.watch(todayProvidersProvider);
    final selectedProvider = ref.watch(selectedProviderFilterProvider);

    return Column(
      children: [
        // Filter bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Text(
                'Provider:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              DropdownButton<String?>(
                value: selectedProvider,
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('All Providers'),
                  ),
                  ...providersAsync.valueOrNull?.map((provider) {
                        return DropdownMenuItem(
                          value: provider.id,
                          child: Text(provider.fullName),
                        );
                      }) ??
                      [],
                ],
                onChanged: (value) {
                  ref.read(selectedProviderFilterProvider.notifier).state =
                      value;
                },
              ),
              const Spacer(),
              // Legend
              _buildLegend(),
            ],
          ),
        ),
        const Divider(height: 1),
        // Schedule grid
        Expanded(
          child: providersAsync.when(
            data: (providers) {
              if (providers.isEmpty) {
                return const Center(
                  child: Text('No providers found'),
                );
              }

              final filteredProviders = selectedProvider != null
                  ? providers.where((p) => p.id == selectedProvider).toList()
                  : providers;

              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: filteredProviders.map((provider) {
                      final appointments =
                          appointmentsByProvider[provider.id] ?? [];
                      return _buildProviderSchedule(
                        context,
                        ref,
                        provider,
                        appointments,
                      );
                    }).toList(),
                  ),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => const Center(
              child: Text('Error loading schedule'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildLegendItem(Colors.blue, 'Confirmed'),
        const SizedBox(width: 12),
        _buildLegendItem(Colors.purple, 'Completed'),
        const SizedBox(width: 12),
        _buildLegendItem(Colors.red, 'No-Show'),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildProviderSchedule(
    BuildContext context,
    WidgetRef ref,
    model.Provider provider,
    List<Appointment> appointments,
  ) {
    final sortedAppointments = [...appointments]
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Color(
                    int.parse('FF${provider.colorHex}', radix: 16),
                  ),
                  child: Text(
                    provider.initials,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  provider.fullName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${sortedAppointments.length} appointments',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (sortedAppointments.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No appointments today',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ...sortedAppointments.map((appointment) {
                return _buildAppointmentTile(context, ref, appointment);
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentTile(
    BuildContext context,
    WidgetRef ref,
    Appointment appointment,
  ) {
    final clientAsync = ref.watch(
      clientsRepositoryProvider.select(
        (repo) => repo.getClient(
          context: ref.watch(securityContextProvider).valueOrNull!,
          clientId: appointment.clientId,
        ),
      ),
    );

    return FutureBuilder<Client?>(
      future: clientAsync,
      builder: (context, snapshot) {
        final clientName = snapshot.data?.fullName ?? 'Loading...';

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: _getStatusColor(appointment.status).withValues(alpha: 0.1),
          child: InkWell(
            onTap: () => _showAppointmentActions(context, ref, appointment),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _getStatusColor(appointment.status),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat.jm().format(appointment.startTime),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          clientName,
                          style: const TextStyle(fontSize: 14),
                        ),
                        Text(
                          appointment.serviceType ?? 'Service',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Chip(
                    label: Text(
                      _getStatusLabel(appointment.status),
                      style: const TextStyle(fontSize: 11),
                    ),
                    backgroundColor:
                        _getStatusColor(appointment.status).withValues(alpha: 0.2),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
