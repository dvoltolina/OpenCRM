import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/providers/providers.dart';
import '../../../core/ui/components/components.dart';
import '../../../data/models/provider.dart' as provider_model;
import '../../../data/models/security_context.dart';
import '../../../data/models/service.dart';
import '../../../data/models/waitlist_entry.dart';

/// Staff-facing waitlist management page.
class WaitlistPage extends ConsumerStatefulWidget {
  const WaitlistPage({super.key});

  @override
  ConsumerState<WaitlistPage> createState() => _WaitlistPageState();
}

class _WaitlistPageState extends ConsumerState<WaitlistPage> {
  String? _serviceFilter;
  String? _providerFilter;
  WaitlistStatus? _statusFilter = WaitlistStatus.active;
  List<Service> _servicesCache = [];
  List<provider_model.Provider> _providersCache = [];

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(appConfigProvider);
    final securityContextAsync = ref.watch(securityContextProvider);

    if (!config.featureFlags.enableWaitlist ||
        !config.bookingPolicies.allowWaitlist) {
      return const Center(
        child: Text('Waitlist is disabled in configuration.'),
      );
    }

    return securityContextAsync.when(
      loading: () => const LoadingStateWidget(
        message: 'Loading waitlist...',
      ),
      error: (error, _) => ErrorStateWidget(
        error: error,
        message: 'Unable to load waitlist',
      ),
      data: (securityContext) {
        if (securityContext == null) {
          return const Center(child: Text('Sign in to manage the waitlist.'));
        }

        final servicesAsync = ref.watch(servicesStreamProvider(securityContext));
        final providersAsync = ref.watch(providersStreamProvider(securityContext));
        final entriesAsync = ref.watch(
          waitlistEntriesStreamProviderFamily(
            WaitlistEntriesFilter(
              serviceId: _serviceFilter,
              providerId: _providerFilter,
              status: _statusFilter,
            ),
          ),
        );

        servicesAsync.whenData((value) => _servicesCache = value);
        providersAsync.whenData((value) => _providersCache = value);

        return Scaffold(
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openCreateDialog(
              config,
              securityContext,
            ),
            label: const Text('Add entry'),
            icon: const Icon(Icons.add),
          ),
          body: SafeArea(
            top: false,
            child: Padding(
              padding: AppSpacing.pagePadding,
              child: Column(
                children: [
                  _buildFilters(servicesAsync, providersAsync),
                  VSpace.sm,
                  Expanded(
                    child: _buildEntriesList(
                      securityContext,
                      entriesAsync,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilters(
    AsyncValue<List<Service>> servicesAsync,
    AsyncValue<List<provider_model.Provider>> providersAsync,
  ) {
    if (servicesAsync.isLoading || providersAsync.isLoading) {
      return const LinearProgressIndicator();
    }

    final services = servicesAsync.valueOrNull ?? _servicesCache;
    var providers = providersAsync.valueOrNull ?? _providersCache;

    if (_serviceFilter != null) {
      providers = providers
          .where(
            (provider) => provider.serviceIds.contains(_serviceFilter),
          )
          .toList();
    }

    final hasFilters = _serviceFilter != null ||
                       _providerFilter != null ||
                       _statusFilter != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Filters',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const Spacer(),
            if (hasFilters)
              TextButton.icon(
                onPressed: () => setState(() {
                  _serviceFilter = null;
                  _providerFilter = null;
                  _statusFilter = WaitlistStatus.active;
                }),
                icon: const Icon(Icons.clear, size: AppIconSize.xs),
                label: const Text('Clear'),
              ),
          ],
        ),
        VSpace.xs,
        AppChipGroup(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          chips: [
            // Service filters
            ...services.map((service) => AppFilterChip(
              label: service.name,
              selected: _serviceFilter == service.id,
              onSelected: (selected) => setState(() {
                _serviceFilter = selected ? service.id : null;
                if (!selected) _providerFilter = null;
              }),
            )),
            // Provider filters (if service selected)
            if (_serviceFilter != null && providers.isNotEmpty) ...[
              const SizedBox(width: AppSpacing.sm),
              ...providers.map((provider) => AppFilterChip(
                label: provider.fullName,
                selected: _providerFilter == provider.id,
                icon: Icons.person,
                onSelected: (selected) => setState(() {
                  _providerFilter = selected ? provider.id : null;
                }),
              )),
            ],
            // Status filters
            const SizedBox(width: AppSpacing.sm),
            ...WaitlistStatus.values.map((status) => AppFilterChip(
              label: status.name.toUpperCase(),
              selected: _statusFilter == status,
              onSelected: (selected) => setState(() {
                _statusFilter = selected ? status : null;
              }),
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildEntriesList(
    SecurityContext ctx,
    AsyncValue<List<WaitlistEntry>> entriesAsync,
  ) {
    return entriesAsync.when(
      loading: () => const LoadingStateWidget(
        message: 'Loading entries...',
      ),
      error: (error, _) => ErrorStateWidget(
        error: error,
        message: 'Unable to load waitlist entries',
      ),
      data: (entries) {
        if (entries.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.list_alt_outlined,
            title: 'No waitlist entries',
            subtitle: _statusFilter != null
                ? 'No ${_statusFilter!.name} entries found. Try changing filters or add a new entry.'
                : 'Add clients to the waitlist when appointments are not available',
            actionLabel: 'Add Entry',
            onAction: () => _openCreateDialog(
              ref.read(appConfigProvider),
              ctx,
            ),
          );
        }

        return ListView.separated(
          itemCount: entries.length,
          separatorBuilder: (context, index) => VSpace.xs,
          itemBuilder: (context, index) {
            final entry = entries[index];
            final statusPill = _buildStatusPill(entry.status);

            return AppCard(
              child: AppListTile(
                title: entry.clientName,
                subtitle: entry.serviceName ?? entry.serviceId,
                leading: CircleAvatar(
                  child: Text(
                    entry.clientName.isNotEmpty
                        ? entry.clientName[0].toUpperCase()
                        : '?',
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    statusPill,
                    HSpace.xs,
                    PopupMenuButton<String>(
                      onSelected: (value) => _handleAction(ctx, value, entry),
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'convert',
                          child: Text('Mark converted'),
                        ),
                        PopupMenuItem(
                          value: 'expire',
                          child: Text('Expire'),
                        ),
                      ],
                    ),
                  ],
                ),
                onTap: () => _showEntryDetails(entry),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatusPill(WaitlistStatus status) {
    switch (status) {
      case WaitlistStatus.active:
        return StatusPill.success(label: status.name);
      case WaitlistStatus.converted:
        return StatusPill.info(label: status.name);
      case WaitlistStatus.expired:
        return StatusPill.error(label: status.name);
      case WaitlistStatus.notified:
        return StatusPill.warning(label: status.name);
    }
  }

  Future<void> _handleAction(
    SecurityContext _,
    String action,
    WaitlistEntry entry,
  ) async {
    final waitlistService = ref.read(waitlistServiceProvider);

    switch (action) {
      case 'convert':
        await waitlistService.markConverted(entry);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Entry marked as converted.')),
          );
        }
        break;
      case 'expire':
        await ref.read(waitlistRepositoryProvider).updateStatus(
          businessId: entry.businessId,
          entryId: entry.id,
          status: WaitlistStatus.expired,
          expiresAt: DateTime.now(),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Entry expired.')),
          );
        }
        break;
    }
  }

  void _showEntryDetails(WaitlistEntry entry) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: AppSpacing.cardPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(entry.clientName,
                  style: Theme.of(context).textTheme.titleMedium),
              VSpace.xs,
              Text('Service: ${entry.serviceName ?? entry.serviceId}'),
              if (entry.providerName != null)
                Text('Provider: ${entry.providerName}'),
              Text(
                'Range: ${entry.earliestDate.toLocal().toString().split(' ').first}'
                ' → ${entry.latestDate.toLocal().toString().split(' ').first}',
              ),
              Text('Time prefs: ${entry.timeOfDayPreferences.map((e) => e.name).join(', ')}'),
              if (entry.notes != null && entry.notes!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text('Notes: ${entry.notes}'),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openCreateDialog(
    AppConfig config,
    SecurityContext securityContext,
  ) async {
    final waitlistService = ref.read(waitlistServiceProvider);
    if (_servicesCache.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add services before creating entries.')),
      );
      return;
    }

    String? serviceId = _serviceFilter;
    String? providerId;
    DateTime start = DateTime.now();
    DateTime end = DateTime.now().add(const Duration(days: 14));
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final noteController = TextEditingController();
    NotificationPreference preference = NotificationPreference.email;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add to waitlist'),
          content: StatefulBuilder(
            builder: (context, setModalState) {
              final services = _servicesCache;
              var providers = _providersCache;
              if (serviceId != null) {
                providers = providers
                    .where(
                      (provider) => provider.serviceIds.contains(serviceId),
                    )
                    .toList();
              }

              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String?>(
                      initialValue: serviceId,
                      decoration: const InputDecoration(labelText: 'Service'),
                      items: services
                          .map(
                            (service) => DropdownMenuItem(
                              value: service.id,
                              child: Text(service.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setModalState(() => serviceId = value),
                    ),
                    VSpace.xs,
                    DropdownButtonFormField<String?>(
                      initialValue: providerId,
                      decoration: const InputDecoration(
                        labelText: 'Provider (optional)',
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('No preference'),
                        ),
                        ...providers.map(
                          (provider) => DropdownMenuItem(
                            value: provider.id,
                            child: Text(provider.fullName),
                          ),
                        ),
                      ],
                      onChanged: (value) =>
                          setModalState(() => providerId = value),
                    ),
                    VSpace.xs,
                    TextField(
                      controller: nameController,
                      decoration:
                          const InputDecoration(labelText: 'Client name'),
                    ),
                    VSpace.xs,
                    TextField(
                      controller: emailController,
                      decoration:
                          const InputDecoration(labelText: 'Email (optional)'),
                    ),
                    VSpace.xs,
                    TextField(
                      controller: phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone (optional)',
                      ),
                    ),
                    VSpace.xs,
                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Earliest'),
                            subtitle: Text(
                              start.toLocal().toString().split(' ').first,
                            ),
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: start,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 365)),
                              );
                              if (picked != null) {
                                setModalState(() => start = picked);
                              }
                            },
                          ),
                        ),
                        Expanded(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Latest'),
                            subtitle: Text(
                              end.toLocal().toString().split(' ').first,
                            ),
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: end,
                                firstDate: start,
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 365)),
                              );
                              if (picked != null) {
                                setModalState(() => end = picked);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    DropdownButtonFormField<NotificationPreference>(
                      initialValue: preference,
                      decoration:
                          const InputDecoration(labelText: 'Notify via'),
                      items: NotificationPreference.values
                          .map(
                            (pref) => DropdownMenuItem(
                              value: pref,
                              child: Text(pref.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setModalState(() => preference = value);
                        }
                      },
                    ),
                    VSpace.xs,
                    TextField(
                      controller: noteController,
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    if (result != true || serviceId == null) return;

    try {
      final service =
          _servicesCache.firstWhere((element) => element.id == serviceId);
      final provider = providerId != null
          ? _providersCache.firstWhere(
              (element) => element.id == providerId,
              orElse: () => provider_model.Provider(
                id: providerId!,
                businessId: securityContext.businessId,
                firstName: '',
                lastName: '',
                email: '',
                createdAt: DateTime.now(),
              ),
            )
          : null;

      await waitlistService.joinWaitlist(
        context: securityContext,
        serviceId: service.id,
        serviceName: service.name,
        providerId: provider?.id,
        providerName: provider?.fullName,
        locationId: provider?.locationId,
        earliestDate: start,
        latestDate: end,
        preferredDays: _buildDayPrefs(start, end),
        timeOfDayPreferences: const [TimeOfDayPreference.anytime],
        clientName: nameController.text.isEmpty
            ? 'Unnamed client'
            : nameController.text,
        clientEmail:
            emailController.text.isEmpty ? null : emailController.text,
        clientPhone:
            phoneController.text.isEmpty ? null : phoneController.text,
        notificationPreference: preference,
        notes: noteController.text.isEmpty ? null : noteController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Entry added to waitlist.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add entry: $error')),
        );
      }
    }
  }

  List<int> _buildDayPrefs(DateTime start, DateTime end) {
    final days = <int>{};
    for (var date = start;
        !date.isAfter(end);
        date = date.add(const Duration(days: 1))) {
      days.add(date.weekday);
    }
    return days.toList();
  }
}
