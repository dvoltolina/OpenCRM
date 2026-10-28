import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/providers/providers.dart';
import '../../../core/ui/components/components.dart';
import '../../../core/utils/safe_error_handler.dart';
import '../../../core/services/reference_data_cache.dart';
import '../../../core/services/waitlist_service.dart';
import '../../../data/models/provider.dart' as provider_model;
import '../../../data/models/security_context.dart';
import '../../../data/models/service.dart';
import '../../../data/models/waitlist_entry.dart';

/// Customer-facing waitlist enrollment page.
class JoinWaitlistPage extends ConsumerStatefulWidget {
  const JoinWaitlistPage({
    required this.config,
    required this.securityContext,
    this.initialService,
    this.initialProvider,
    this.initialDate,
    super.key,
  });

  final AppConfig config;
  final SecurityContext securityContext;
  final Service? initialService;
  final provider_model.Provider? initialProvider;
  final DateTime? initialDate;

  @override
  ConsumerState<JoinWaitlistPage> createState() => _JoinWaitlistPageState();
}

class _JoinWaitlistPageState extends ConsumerState<JoinWaitlistPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();

  late WaitlistService _waitlistService;

  String? _selectedServiceId;
  String? _selectedProviderId;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 14));
  final Set<TimeOfDayPreference> _timePrefs = {
    TimeOfDayPreference.morning,
    TimeOfDayPreference.afternoon,
  };
  NotificationPreference _notificationPreference =
      NotificationPreference.email;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _waitlistService = ref.read(waitlistServiceProvider);
    _selectedServiceId = widget.initialService?.id;
    _selectedProviderId = widget.initialProvider?.id;
    _startDate = widget.initialDate ?? _startDate;
    _endDate = _startDate.add(const Duration(days: 14));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(appConfigProvider);

    if (!config.featureFlags.enableWaitlist ||
        !config.bookingPolicies.allowWaitlist) {
      return Scaffold(
        appBar: AppBar(title: const Text('Join waitlist')),
        body: const Center(
          child: Text('Waitlist is disabled for this business.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Join the waitlist')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'No slots available? We will notify you when something opens.',
              ),
              VSpace.md,
              Expanded(
                child: StreamBuilder<List<Service>>(
                  stream: ReferenceDataCache.instance.watchServices(
                    widget.securityContext,
                  ),
                  builder: (context, snapshot) {
                    final services = snapshot.data ?? [];
                    return Column(
                      children: [
                        _buildServiceSelector(services),
                        VSpace.sm,
                        _buildProviderSelector(),
                        VSpace.sm,
                        _buildDatePickers(context),
                        VSpace.sm,
                        _buildTimePreferences(),
                        VSpace.sm,
                        _buildNotificationPrefs(),
                        VSpace.sm,
                        _buildContactFields(),
                        VSpace.sm,
                        TextFormField(
                          controller: _notesController,
                          decoration: const InputDecoration(
                            labelText: 'Anything else?',
                            hintText: 'Scheduling constraints or preferences',
                          ),
                          maxLines: 3,
                        ),
                      ],
                    );
                  },
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submit,
                  icon: _isSubmitting
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: Text(_isSubmitting ? 'Joining...' : 'Join waitlist'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceSelector(List<Service> services) {
    return DropdownButtonFormField<String>(
      initialValue: _selectedServiceId,
      decoration: const InputDecoration(labelText: 'Service'),
      items: services
          .map(
            (service) => DropdownMenuItem(
              value: service.id,
              child: Text(service.name),
            ),
          )
          .toList(),
      onChanged: (value) => setState(() => _selectedServiceId = value),
      validator: (value) =>
          value == null ? 'Select a service to join the waitlist.' : null,
    );
  }

  Widget _buildProviderSelector() {
    return StreamBuilder<List<provider_model.Provider>>(
      stream: ReferenceDataCache.instance.watchProviders(widget.securityContext),
      builder: (context, snapshot) {
        var providers = snapshot.data ?? [];
        if (_selectedServiceId != null) {
          providers = providers
              .where((provider) => provider.serviceIds.contains(
                    _selectedServiceId,
                  ))
              .toList();
        }
        return DropdownButtonFormField<String?>(
          initialValue: _selectedProviderId,
          decoration: const InputDecoration(
            labelText: 'Preferred provider (optional)',
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
          onChanged: (value) => setState(() => _selectedProviderId = value),
        );
      },
    );
  }

  Widget _buildDatePickers(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Earliest'),
            subtitle: Text(_startDate.toLocal().toString().split(' ').first),
            trailing: IconButton(
              icon: const Icon(Icons.edit_calendar_outlined),
              onPressed: () => _pickDate(isStart: true),
            ),
          ),
        ),
        Expanded(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Latest'),
            subtitle: Text(_endDate.toLocal().toString().split(' ').first),
            trailing: IconButton(
              icon: const Icon(Icons.event_available_outlined),
              onPressed: () => _pickDate(isStart: false),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimePreferences() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Time of day preference'),
        Wrap(
          spacing: AppSpacing.xs,
          children: TimeOfDayPreference.values
              .map(
                (pref) => FilterChip(
                  label: Text(pref.name),
                  selected: _timePrefs.contains(pref),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _timePrefs.add(pref);
                      } else {
                        _timePrefs.remove(pref);
                      }
                    });
                  },
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildNotificationPrefs() {
    return DropdownButtonFormField<NotificationPreference>(
      initialValue: _notificationPreference,
      decoration: const InputDecoration(labelText: 'Notify me via'),
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
          setState(() => _notificationPreference = value);
        }
      },
    );
  }

  Widget _buildContactFields() {
    return Column(
      children: [
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'Full name'),
          validator: (value) =>
              value == null || value.isEmpty ? 'Name is required.' : null,
        ),
        VSpace.xs,
        TextFormField(
          controller: _emailController,
          decoration: const InputDecoration(labelText: 'Email'),
          keyboardType: TextInputType.emailAddress,
        ),
        VSpace.xs,
        TextFormField(
          controller: _phoneController,
          decoration: const InputDecoration(labelText: 'Phone (optional)'),
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 7));
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedServiceId == null) return;

    setState(() => _isSubmitting = true);

    try {
      final services = await ReferenceDataCache.instance
          .watchServices(widget.securityContext)
          .first;
      final service =
          services.firstWhere((item) => item.id == _selectedServiceId);

      final providers = await ReferenceDataCache.instance
          .watchProviders(widget.securityContext)
          .first;
      provider_model.Provider? provider;
      if (_selectedProviderId != null) {
        try {
          provider = providers
              .firstWhere((item) => item.id == _selectedProviderId);
        } catch (_) {
          provider = null;
        }
      }

      await _waitlistService.joinWaitlist(
        context: widget.securityContext,
        serviceId: service.id,
        serviceName: service.name,
        providerId: provider?.id,
        providerName: provider?.fullName,
        locationId: provider?.locationId,
        earliestDate: _startDate,
        latestDate: _endDate,
        preferredDays: _buildDayPrefs(),
        timeOfDayPreferences: _timePrefs.toList(),
        clientName: _nameController.text.trim(),
        clientId: widget.securityContext.clientId,
        clientEmail: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        clientPhone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        notificationPreference: _notificationPreference,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Added to waitlist. We will notify you when a slot opens.'),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(SafeErrorHandler.handle(error))),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  List<int> _buildDayPrefs() {
    final days = <int>{};
    for (var date = _startDate;
        !date.isAfter(_endDate);
        date = date.add(const Duration(days: 1))) {
      days.add(date.weekday);
    }
    return days.toList();
  }
}
