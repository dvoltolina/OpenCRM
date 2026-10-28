import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/appointment.dart';
import '../../../../data/models/client.dart';
import '../../../../core/providers/providers.dart';
import '../../providers/front_desk_providers.dart';
import '../../services/front_desk_service.dart';

/// Dialog for client lookup and check-in.
///
/// Allows front desk to search for a client by name, phone, or email,
/// then check them in for their appointment.
class CheckInDialog extends ConsumerStatefulWidget {
  const CheckInDialog({super.key});

  @override
  ConsumerState<CheckInDialog> createState() => _CheckInDialogState();
}

class _CheckInDialogState extends ConsumerState<CheckInDialog> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedClientId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Client> _filterClients(List<Client> clients) {
    if (_searchQuery.isEmpty) return [];

    final query = _searchQuery.toLowerCase();
    return clients.where((client) {
      return client.fullName.toLowerCase().contains(query) ||
          (client.email?.toLowerCase().contains(query) ?? false) ||
          (client.phone?.contains(query) ?? false);
    }).toList();
  }

  List<Appointment> _getClientAppointmentsToday(
    List<Appointment> allAppointments,
    String clientId,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return allAppointments
        .where((a) =>
            a.clientId == clientId &&
            a.startTime.isAfter(today) &&
            a.startTime
                .isBefore(today.add(const Duration(days: 1))) &&
            a.status != AppointmentStatus.cancelled)
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  Future<void> _checkIn(Appointment appointment) async {
    final securityContext = ref.read(securityContextProvider).valueOrNull;
    if (securityContext == null) return;

    final service = FrontDeskService(
      appointmentsRepository: ref.read(appointmentsRepositoryProvider),
      waitlistRepository: ref.read(waitlistRepositoryProvider),
    );

    try {
      await service.checkInClient(securityContext, appointment.id);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Client checked in successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Check-in failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(allClientsProvider);
    final allAppointments =
        ref.watch(todayAllAppointmentsProvider).valueOrNull ?? [];

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search),
                  const SizedBox(width: 8),
                  const Text(
                    'Check In Client',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Search field
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search by name, phone, or email...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                    _selectedClientId = null;
                  });
                },
              ),
            ),
            const Divider(height: 1),
            // Results
            Expanded(
              child: clientsAsync.when(
                data: (clients) {
                  if (_searchQuery.isEmpty) {
                    return const Center(
                      child: Text(
                        'Start typing to search for a client',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  final filteredClients = _filterClients(clients);

                  if (filteredClients.isEmpty) {
                    return const Center(
                      child: Text(
                        'No clients found',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredClients.length,
                    itemBuilder: (context, index) {
                      final client = filteredClients[index];
                      final isSelected = _selectedClientId == client.id;
                      final appointments =
                          _getClientAppointmentsToday(allAppointments, client.id);

                      return Column(
                        children: [
                          ListTile(
                            selected: isSelected,
                            leading: CircleAvatar(
                              child: Text(client.initials),
                            ),
                            title: Text(client.fullName),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (client.email != null)
                                  Text(client.email!),
                                if (client.phone != null)
                                  Text(client.phone!),
                              ],
                            ),
                            trailing: appointments.isEmpty
                                ? const Chip(
                                    label: Text('No appointments today'),
                                    backgroundColor: Colors.grey,
                                  )
                                : Chip(
                                    label: Text(
                                      '${appointments.length} appointment${appointments.length > 1 ? 's' : ''}',
                                    ),
                                    backgroundColor: Colors.blue,
                                  ),
                            onTap: () {
                              setState(() {
                                _selectedClientId =
                                    isSelected ? null : client.id;
                              });
                            },
                          ),
                          if (isSelected && appointments.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Today\'s Appointments:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ...appointments.map((appointment) {
                                    final isCheckedIn = appointment.status ==
                                        AppointmentStatus.confirmed;
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Row(
                                        children: [
                                          Text(
                                            DateFormat.jm()
                                                .format(appointment.startTime),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              appointment.serviceType ?? 'Service',
                                            ),
                                          ),
                                          if (isCheckedIn)
                                            const Chip(
                                              label: Text('Checked In'),
                                              backgroundColor: Colors.green,
                                            )
                                          else
                                            ElevatedButton(
                                              onPressed: () =>
                                                  _checkIn(appointment),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green,
                                                foregroundColor: Colors.white,
                                              ),
                                              child: const Text('Check In'),
                                            ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          const Divider(height: 1),
                        ],
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => const Center(
                  child: Text('Error loading clients'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
