import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/appointment.dart';
import '../../../../data/models/client.dart';
import '../../../../data/models/provider.dart' as model;
import '../../../../core/providers/providers.dart';
import '../../providers/front_desk_providers.dart';
import '../../services/front_desk_service.dart';
import '../dialogs/check_in_dialog.dart';
import '../dialogs/walk_in_booking_dialog.dart';

/// Arrivals panel showing expected arrivals for the next 60 minutes.
///
/// Displays clients who should arrive soon with one-tap check-in buttons.
/// Includes walk-in booking option.
class ArrivalsPanel extends ConsumerWidget {
  const ArrivalsPanel({super.key});

  Future<void> _checkInClient(
    BuildContext context,
    WidgetRef ref,
    Appointment appointment,
  ) async {
    final securityContext = ref.read(securityContextProvider).valueOrNull;
    if (securityContext == null) return;

    final service = FrontDeskService(
      appointmentsRepository: ref.read(appointmentsRepositoryProvider),
      waitlistRepository: ref.read(waitlistRepositoryProvider),
    );

    try {
      await service.checkInClient(securityContext, appointment.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Client checked in successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Check-in failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getTimeUntilArrival(DateTime appointmentTime) {
    final now = DateTime.now();
    final difference = appointmentTime.difference(now);

    if (difference.isNegative) {
      final minutesLate = difference.inMinutes.abs();
      if (minutesLate == 0) return 'Now';
      return '$minutesLate min late';
    }

    final minutesUntil = difference.inMinutes;
    if (minutesUntil == 0) return 'Now';
    return 'in $minutesUntil min';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expectedArrivals = ref.watch(expectedArrivalsProvider);

    return Column(
      children: [
        // Header with walk-in button
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Text(
                'Expected Arrivals',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => const WalkInBookingDialog(),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Walk-In'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => const CheckInDialog(),
                  );
                },
                icon: const Icon(Icons.search),
                label: const Text('Search Client'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Arrivals list
        Expanded(
          child: expectedArrivals.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.event_available, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No expected arrivals in the next hour',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: expectedArrivals.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final appointment = expectedArrivals[index];
                    return _buildArrivalCard(context, ref, appointment);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildArrivalCard(
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

    final providerAsync = ref.watch(
      providersRepositoryProvider.select(
        (repo) => repo.getProvider(
          context: ref.watch(securityContextProvider).valueOrNull!,
          providerId: appointment.providerId,
        ),
      ),
    );

    return FutureBuilder<List<dynamic>>(
      future: Future.wait([clientAsync, providerAsync]),
      builder: (context, snapshot) {
        final client = snapshot.data?[0] as Client?;
        final provider = snapshot.data?[1] as model.Provider?;
        final clientName = client?.fullName ?? 'Loading...';
        final providerName = provider?.fullName ?? 'Provider';

        final isLate = appointment.startTime.isBefore(DateTime.now());
        final isAlreadyCheckedIn =
            appointment.status == AppointmentStatus.confirmed;

        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Time and status indicator
                Column(
                  children: [
                    Text(
                      DateFormat.jm().format(appointment.startTime),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isLate ? Colors.red : Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isLate
                            ? Colors.red.shade100
                            : Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getTimeUntilArrival(appointment.startTime),
                        style: TextStyle(
                          fontSize: 11,
                          color: isLate ? Colors.red : Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                // Client and service info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        clientName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        appointment.serviceType ?? 'Service',
                        style: const TextStyle(fontSize: 14),
                      ),
                      Text(
                        'with $providerName',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                // Check-in button
                if (isAlreadyCheckedIn)
                  const Chip(
                    label: Text('Checked In'),
                    avatar: Icon(Icons.check_circle, size: 16),
                    backgroundColor: Colors.green,
                  )
                else
                  ElevatedButton.icon(
                    onPressed: () => _checkInClient(context, ref, appointment),
                    icon: const Icon(Icons.check),
                    label: const Text('Check In'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(120, 48),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
