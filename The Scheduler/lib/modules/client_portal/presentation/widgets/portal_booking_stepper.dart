import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/services/availability_service.dart';
import '../../../../core/services/booking_rules_engine.dart';
import '../../../../data/models/appointment.dart';
import '../../../../data/models/client.dart';
import '../../../../data/models/location.dart';
import '../../../../data/models/provider.dart';
import '../../../../data/models/security_context.dart';
import '../../../../data/models/service.dart';
import '../../../../data/repositories/clients_repository.dart';

/// Portal booking stepper widget - handles the multi-step booking flow for clients
class PortalBookingStepper extends StatefulWidget {
  const PortalBookingStepper({
    required this.config,
    required this.securityContext,
    required this.services,
    required this.providers,
    required this.locations,
    required this.availabilityService,
    required this.rulesEngine,
    required this.clientsRepository,
    required this.onWaitlistPressed,
    super.key,
  });

  final AppConfig config;
  final SecurityContext securityContext;
  final List<Service> services;
  final List<Provider> providers;
  final List<Location> locations;
  final AvailabilityService availabilityService;
  final BookingRulesEngine rulesEngine;
  final ClientsRepository clientsRepository;
  final VoidCallback onWaitlistPressed;

  @override
  State<PortalBookingStepper> createState() => _PortalBookingStepperState();
}

class _PortalBookingStepperState extends State<PortalBookingStepper> {
  static const _uuid = Uuid();

  int _currentStep = 0;
  Service? _selectedService;
  Provider? _selectedProvider;
  Location? _selectedLocation;
  AvailabilitySlot? _selectedSlot;
  DateTime _selectedDate = DateTime.now();
  bool _loadingSlots = false;
  bool _isSubmitting = false;
  List<AvailabilitySlot> _slots = [];
  BookingSubmissionResult? _submissionResult;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.locations.isNotEmpty) {
      _selectedLocation = widget.locations.first;
    }
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
    final steps = _buildSteps();

    return Stepper(
      currentStep: _currentStep,
      steps: steps,
      onStepCancel: _currentStep == 0 ? null : () => setState(() => _currentStep -= 1),
      onStepContinue: () => _handleContinue(),
      controlsBuilder: (context, details) {
        return Row(
          children: [
            FilledButton(
              onPressed: details.onStepContinue,
              child: Text(
                _currentStep == steps.length - 1 ? 'Submit request' : 'Next',
              ),
            ),
            const SizedBox(width: 12),
            TextButton(
              onPressed: details.onStepCancel,
              child: const Text('Back'),
            ),
          ],
        );
      },
    );
  }

  List<Step> _buildSteps() {
    return [
      Step(
        title: const Text('Service'),
        isActive: _currentStep == 0,
        state: _selectedService != null ? StepState.complete : StepState.indexed,
        content: _buildServiceSelector(),
      ),
      Step(
        title: const Text('Provider'),
        isActive: _currentStep == 1,
        state: _selectedProvider != null ? StepState.complete : StepState.indexed,
        content: _buildProviderSelector(),
      ),
      Step(
        title: const Text('Time'),
        isActive: _currentStep == 2,
        state: _selectedSlot != null ? StepState.complete : StepState.indexed,
        content: _buildTimeSelector(),
      ),
      Step(
        title: const Text('Your info'),
        isActive: _currentStep == 3,
        state: _nameController.text.isNotEmpty && _emailController.text.isNotEmpty
            ? StepState.complete
            : StepState.indexed,
        content: _buildClientInfoForm(),
      ),
      Step(
        title: const Text('Confirm'),
        isActive: _currentStep == 4,
        state: _submissionResult?.status == BookingSubmissionStatus.success
            ? StepState.complete
            : StepState.indexed,
        content: _buildSummary(),
      ),
    ];
  }

  Widget _buildServiceSelector() {
    return RadioGroup<Service>(
      groupValue: _selectedService,
      onChanged: (value) {
        setState(() {
          _selectedService = value;
          _selectedSlot = null;
          _currentStep = 0;
        });
      },
      child: Column(
        children: widget.services
            .map(
              (service) => RadioListTile<Service>(
                title: Text(service.name),
                subtitle: Text(
                  '${service.durationDisplay} • \$${service.price.toStringAsFixed(2)}',
                ),
                value: service,
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildProviderSelector() {
    return RadioGroup<Provider>(
      groupValue: _selectedProvider,
      onChanged: (value) {
        setState(() {
          _selectedProvider = value;
          _selectedSlot = null;
          _currentStep = 1;
        });
      },
      child: Column(
        children: widget.providers
            .map(
              (provider) => RadioListTile<Provider>(
                title: Text(provider.fullName),
                value: provider,
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildTimeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Preferred date: ${_selectedDate.toLocal().toString().split(' ').first}',
              ),
            ),
            IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: _pickDate,
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_loadingSlots)
          const Center(child: CircularProgressIndicator())
        else if (_slots.isEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'No openings for this day. Choose a different date or join the waitlist.',
              ),
              if (widget.config.featureFlags.enableWaitlist &&
                  widget.config.bookingPolicies.allowWaitlist)
                TextButton.icon(
                  onPressed: widget.onWaitlistPressed,
                  icon: const Icon(Icons.hourglass_bottom_outlined),
                  label: const Text('Join waitlist'),
                ),
            ],
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _slots
                .map(
                  (slot) => ChoiceChip(
                    label: Text(
                      '${slot.start.hour.toString().padLeft(2, '0')}:${slot.start.minute.toString().padLeft(2, '0')}',
                    ),
                    selected: _selectedSlot == slot,
                    onSelected: (_) {
                      setState(() => _selectedSlot = slot);
                    },
                  ),
                )
                .toList(),
          ),
        TextButton(
          onPressed: _fetchSlotsIfReady,
          child: const Text('Refresh slots'),
        ),
      ],
    );
  }

  Widget _buildClientInfoForm() {
    return Column(
      children: [
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'Full name'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _emailController,
          decoration: const InputDecoration(labelText: 'Email'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _phoneController,
          decoration: const InputDecoration(labelText: 'Phone (optional)'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _notesController,
          decoration: const InputDecoration(
            labelText: 'Notes or requests (optional)',
          ),
          minLines: 2,
          maxLines: 4,
        ),
      ],
    );
  }

  Widget _buildSummary() {
    if (_selectedService == null ||
        _selectedProvider == null ||
        _selectedSlot == null) {
      return const Text('Complete previous steps to review your booking.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: const Icon(Icons.design_services_outlined),
          title: Text(_selectedService!.name),
          subtitle: Text(_selectedService!.durationDisplay),
        ),
        ListTile(
          leading: const Icon(Icons.person_outline),
          title: Text(_selectedProvider!.fullName),
          subtitle: Text(
            _selectedLocation?.name ?? _selectedLocation?.address ?? 'TBD',
          ),
        ),
        ListTile(
          leading: const Icon(Icons.schedule),
          title: Text(
            _selectedSlot!.start.toLocal().toString().split(".").first,
          ),
        ),
        if (_submissionResult != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              _submissionResult!.status == BookingSubmissionStatus.success
                  ? '✅ Request submitted! We emailed you a confirmation.'
                  : '⚠️ ${_submissionResult!.error ?? 'Submission failed'}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        if (_isSubmitting) ...[
          const SizedBox(height: 12),
          const CircularProgressIndicator(),
        ],
      ],
    );
  }

  Future<void> _handleContinue() async {
    switch (_currentStep) {
      case 0:
        if (_selectedService == null) {
          _showSnackBar('Please pick a service.');
          return;
        }
        break;
      case 1:
        if (_selectedProvider == null) {
          _showSnackBar('Please pick a provider.');
          return;
        }
        await _fetchSlotsIfReady();
        break;
      case 2:
        if (_selectedSlot == null) {
          _showSnackBar('Select a time slot to continue.');
          return;
        }
        break;
      case 3:
        if (_nameController.text.isEmpty || _emailController.text.isEmpty) {
          _showSnackBar('Provide your name and email.');
          return;
        }
        break;
      case 4:
        if (_isSubmitting) return;
        await _submitRequest();
        return;
    }

    setState(() => _currentStep = (_currentStep + 1).clamp(0, 4));
  }

  Future<void> _submitRequest() async {
    if (_selectedService == null ||
        _selectedProvider == null ||
        _selectedSlot == null) {
      _showSnackBar('Complete all steps before submitting.');
      return;
    }

    setState(() => _isSubmitting = true);

    final client = await _upsertClient();

    final draft = BookingDraft(
      clientId: client.id,
      providerId: _selectedProvider!.id,
      serviceId: _selectedService!.id,
      locationId: _selectedLocation?.id ?? widget.securityContext.businessId,
      startTime: _selectedSlot!.start,
      serviceDurationOverride: Duration(
        minutes: _selectedService!.durationMinutes,
      ),
      notes: _notesController.text.trim().isEmpty
          ? 'Client portal request'
          : _notesController.text.trim(),
      status: AppointmentStatus.pending,
    );

    final result = await widget.rulesEngine.submit(
      context: widget.securityContext,
      draft: draft,
    );

    setState(() {
      _isSubmitting = false;
      _submissionResult = result;
    });

    if (result.status == BookingSubmissionStatus.success) {
      final depositMessage = result.payment != null
          ? ' Deposit of \$${(result.payment!.amountCents / 100).toStringAsFixed(2)} collected.'
          : '';
      _showSnackBar(
        'Request submitted! We will confirm via email.$depositMessage',
      );
    } else {
      _showSnackBar(
        'Unable to submit: ${result.error ?? 'validation failed'}.',
      );
    }
  }

  Future<Client> _upsertClient() async {
    final names = _nameController.text.trim().split(' ');
    final firstName = names.first;
    final lastName = names.length > 1 ? names.sublist(1).join(' ') : 'Client';

    final client = Client(
      id: _uuid.v4(),
      businessId: widget.securityContext.businessId,
      firstName: firstName,
      lastName: lastName,
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      notes: 'Portal lead',
      createdAt: DateTime.now(),
    );

    await widget.clientsRepository.upsertClient(
      context: widget.securityContext,
      client: client,
    );

    return client;
  }

  Future<void> _fetchSlotsIfReady() async {
    if (_selectedService == null || _selectedProvider == null) return;

    setState(() {
      _loadingSlots = true;
      _slots = [];
    });

    final query = AvailabilityQuery(
      start: DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      ),
      end: DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      ).add(const Duration(days: 1)),
      providerId: _selectedProvider!.id,
      locationId: _selectedLocation?.id,
      serviceDuration: Duration(minutes: _selectedService!.durationMinutes),
    );

    final slots = await widget.availabilityService.generateSlots(
      context: widget.securityContext,
      query: query,
    );

    setState(() {
      _slots = slots;
      _loadingSlots = false;
      if (!_slots.contains(_selectedSlot)) {
        _selectedSlot = null;
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 120)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedSlot = null;
      });
      await _fetchSlotsIfReady();
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
