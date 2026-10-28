import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/client.dart';
import '../../../../data/models/service.dart';
import '../../../../data/models/provider.dart' as model;
import '../../../../core/providers/providers.dart';
import '../../providers/front_desk_providers.dart';
import '../../services/front_desk_service.dart';

/// Dialog for quick walk-in booking.
///
/// Allows front desk to quickly book a walk-in appointment or add to waitlist.
class WalkInBookingDialog extends ConsumerStatefulWidget {
  const WalkInBookingDialog({super.key});

  @override
  ConsumerState<WalkInBookingDialog> createState() =>
      _WalkInBookingDialogState();
}

class _WalkInBookingDialogState extends ConsumerState<WalkInBookingDialog> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  Client? _selectedClient;
  Service? _selectedService;
  model.Provider? _selectedProvider;
  bool _addToWaitlist = false;

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
    }).take(10).toList();
  }

  bool get _canSubmit =>
      _selectedClient != null &&
      _selectedService != null &&
      (_selectedProvider != null || _addToWaitlist);

  Future<void> _submit() async {
    if (!_canSubmit) return;

    final securityContext = ref.read(securityContextProvider).valueOrNull;
    if (securityContext == null) return;

    final service = FrontDeskService(
      appointmentsRepository: ref.read(appointmentsRepositoryProvider),
      waitlistRepository: ref.read(waitlistRepositoryProvider),
    );

    try {
      if (_addToWaitlist) {
        // Add to waitlist
        await service.addToWaitlist(
          securityContext,
          clientId: _selectedClient!.id,
          clientName: _selectedClient!.fullName,
          serviceId: _selectedService!.id,
          serviceName: _selectedService!.name,
          preferredProviderId: _selectedProvider?.id,
          clientEmail: _selectedClient!.email,
          clientPhone: _selectedClient!.phone,
        );
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Added to waitlist'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Create immediate appointment
        // Note: Using businessId from security context as location
        final securityContext = ref.read(securityContextProvider).valueOrNull;
        if (securityContext == null) return;

        final now = DateTime.now();
        await service.createWalkInAppointment(
          securityContext,
          clientId: _selectedClient!.id,
          serviceId: _selectedService!.id,
          providerId: _selectedProvider!.id,
          locationId: securityContext.businessId,
          startTime: now,
          durationMinutes: _selectedService!.durationMinutes,
          serviceType: _selectedService!.name,
        );
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Walk-in appointment created'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      // HIPAA: Generic error message - no PHI or exception details exposed
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Operation failed. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(allClientsProvider);
    final servicesAsync = ref.watch(allServicesProvider);
    final providersAsync = ref.watch(todayProvidersProvider);

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
                  const Icon(Icons.person_add),
                  const SizedBox(width: 8),
                  const Text(
                    'Walk-In Booking',
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
            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Client selection
                    const Text(
                      'Client *',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_selectedClient == null)
                      Column(
                        children: [
                          TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search client by name...',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onChanged: (value) {
                              setState(() => _searchQuery = value);
                            },
                          ),
                          if (_searchQuery.isNotEmpty)
                            clientsAsync.when(
                              data: (clients) {
                                final filtered = _filterClients(clients);
                                if (filtered.isEmpty) {
                                  return const Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Text('No clients found'),
                                  );
                                }
                                return Container(
                                  margin: const EdgeInsets.only(top: 8),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  constraints:
                                      const BoxConstraints(maxHeight: 200),
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: filtered.length,
                                    itemBuilder: (context, index) {
                                      final client = filtered[index];
                                      return ListTile(
                                        title: Text(client.fullName),
                                        subtitle: Text(
                                          client.phone ?? client.email ?? '',
                                        ),
                                        onTap: () {
                                          setState(() {
                                            _selectedClient = client;
                                            _searchQuery = '';
                                            _searchController.clear();
                                          });
                                        },
                                      );
                                    },
                                  ),
                                );
                              },
                              loading: () => const Padding(
                                padding: EdgeInsets.all(8),
                                child: CircularProgressIndicator(),
                              ),
                              error: (error, stackTrace) => const Padding(
                                padding: EdgeInsets.all(8),
                                child: Text('Error loading clients'),
                              ),
                            ),
                        ],
                      )
                    else
                      Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(_selectedClient!.initials),
                          ),
                          title: Text(_selectedClient!.fullName),
                          subtitle: Text(
                            _selectedClient!.phone ??
                                _selectedClient!.email ??
                                '',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() => _selectedClient = null);
                            },
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    // Service selection
                    const Text(
                      'Service *',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    servicesAsync.when(
                      data: (services) {
                        return DropdownButtonFormField<Service>(
                          initialValue: _selectedService,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          hint: const Text('Select service'),
                          items: services.map((service) {
                            return DropdownMenuItem(
                              value: service,
                              child: Text(
                                '${service.name} (${service.durationDisplay})',
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedService = value);
                          },
                        );
                      },
                      loading: () => const CircularProgressIndicator(),
                      error: (error, stackTrace) => const Text('Error loading services'),
                    ),
                    const SizedBox(height: 24),
                    // Provider selection
                    const Text(
                      'Provider',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    providersAsync.when(
                      data: (providers) {
                        return DropdownButtonFormField<model.Provider>(
                          initialValue: _selectedProvider,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          hint: const Text('Select provider or add to waitlist'),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Any available'),
                            ),
                            ...providers.map((provider) {
                              return DropdownMenuItem(
                                value: provider,
                                child: Text(provider.fullName),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            setState(() => _selectedProvider = value);
                          },
                        );
                      },
                      loading: () => const CircularProgressIndicator(),
                      error: (error, stackTrace) => const Text('Error loading providers'),
                    ),
                    const SizedBox(height: 16),
                    // Waitlist option
                    CheckboxListTile(
                      value: _addToWaitlist,
                      title: const Text('Add to waitlist if no immediate opening'),
                      onChanged: (value) {
                        setState(() => _addToWaitlist = value ?? false);
                      },
                    ),
                  ],
                ),
              ),
            ),
            // Actions
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _canSubmit ? _submit : null,
                    child: Text(_addToWaitlist ? 'Add to Waitlist' : 'Book Now'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
