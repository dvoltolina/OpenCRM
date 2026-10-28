// ignore_for_file: invalid_use_of_protected_member

part of 'booking_form_shell.dart';

extension _BookingFormShellActions on _BookingFormShellState {
  Future<void> _pickDate(
    BuildContext context,
    SecurityContext securityContext,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedSlot = null;
        _recurrencePattern = null;
      });
      _fetchSlotsIfReady(securityContext);
      _validateDraft(securityContext);
    }
  }

  Future<void> _fetchSlotsIfReady(SecurityContext securityContext) async {
    if (_selectedServiceId == null ||
        _selectedProviderId == null ||
        _selectedLocationId == null) {
      return;
    }

    final service = _services.firstWhere(
      (s) => s.id == _selectedServiceId,
      orElse: () => _services.first,
    );

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
      providerId: _selectedProviderId,
      locationId: _selectedLocationId,
      serviceDuration: Duration(minutes: service.durationMinutes),
    );

    final slots = await _availabilityService.generateSlots(
      context: securityContext,
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

  Future<void> _validateDraft(SecurityContext securityContext) async {
    if (!_isDraftReady) {
      _showSnackBar(
        'Select a client and time slot after choosing a service and provider, then try again.',
      );
      setState(() => _lastValidation = null);
      return;
    }

    final draft = _buildDraft();
    if (draft == null) return;

    final validation = await _rulesEngine.validateDraft(
      context: securityContext,
      draft: draft,
    );

    setState(() => _lastValidation = validation);
  }

  Future<void> _submitBooking(SecurityContext securityContext) async {
    if (!_formKey.currentState!.validate() || !_isDraftReady) {
      _showSnackBar('Complete all fields before booking.');
      return;
    }

    final draft = _buildDraft();
    if (draft == null) return;

    setState(() => _isSubmitting = true);

    final result = await _rulesEngine.submit(
      context: securityContext,
      draft: draft,
    );

    setState(() {
      _isSubmitting = false;
      _lastValidation = result.validationResult;
    });

    switch (result.status) {
      case BookingSubmissionStatus.success:
        if (result.magicLinkToken != null &&
            result.appointment != null &&
            mounted) {
          _navigateToConfirmation(
            securityContext: securityContext,
            appointment: result.appointment!,
            magicLinkToken: result.magicLinkToken!,
          );
        } else {
          final depositMessage = result.payment != null
              ? ' Deposit of \$${(result.payment!.amountCents / 100).toStringAsFixed(2)} collected.'
              : '';
          _showSnackBar(
            'Appointment confirmed for $_selectedSlotLabel.$depositMessage',
          );
        }

        _formKey.currentState?.reset();
        _notesController.clear();
        setState(() {
          _selectedServiceId = null;
          _selectedProviderId = null;
          _selectedClientId = null;
          _selectedSlot = null;
          _recurrencePattern = null;
        });
        break;
      case BookingSubmissionStatus.validationFailed:
        _showSnackBar('Resolve validation issues before booking.');
        break;
      case BookingSubmissionStatus.error:
        final safeMessage = SafeErrorHandler.handle(
          result.error ?? 'Unknown error',
          context: 'creating booking',
        );
        _showSnackBar(safeMessage);
        break;
    }
  }

  BookingDraft? _buildDraft() {
    if (!_isDraftReady || _selectedSlot == null) return null;
    final service = _services.firstWhere((s) => s.id == _selectedServiceId);

    return BookingDraft(
      clientId: _selectedClientId!,
      providerId: _selectedProviderId!,
      serviceId: service.id,
      locationId: _selectedLocationId ?? _locations.first.id,
      startTime: _selectedSlot!.start,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      serviceDurationOverride: Duration(minutes: service.durationMinutes),
      recurrencePattern: _recurrencePattern,
    );
  }

  bool get _isDraftReady =>
      _selectedServiceId != null &&
      _selectedProviderId != null &&
      _selectedLocationId != null &&
      _selectedClientId != null &&
      _selectedSlot != null;

  String get _selectedSlotLabel {
    if (_selectedSlot == null) return '';
    return '${_selectedSlot!.start.hour.toString().padLeft(2, '0')}:${_selectedSlot!.start.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _showQuickAddDialog(
    SecurityContext securityContext,
    List<Client> clients,
  ) async {
    final branding = ref.watch(appConfigProvider).branding;
    final theme = Theme.of(context);
    final formKey = GlobalKey<FormState>();
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: branding.backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Quick add client',
          style: theme.textTheme.titleLarge?.copyWith(
            color: branding.primaryColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: firstNameController,
                decoration: InputDecoration(
                  labelText: 'First name',
                  labelStyle: TextStyle(color: branding.primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: branding.accentColor, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: lastNameController,
                decoration: InputDecoration(
                  labelText: 'Last name',
                  labelStyle: TextStyle(color: branding.primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: branding.accentColor, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(color: branding.primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: branding.accentColor, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone',
                  labelStyle: TextStyle(color: branding.primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: branding.accentColor, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('Cancel', style: TextStyle(color: branding.primaryColor)),
          ),
          GradientButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(dialogContext).pop(true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final client = Client(
      id: _BookingFormShellState._uuid.v4(),
      businessId: securityContext.businessId,
      firstName: firstNameController.text.trim(),
      lastName: lastNameController.text.trim(),
      email: emailController.text.trim().isEmpty
          ? null
          : emailController.text.trim(),
      phone: phoneController.text.trim().isEmpty
          ? null
          : phoneController.text.trim(),
      notes: null,
      createdAt: DateTime.now(),
    );

    await _clientsRepository.upsertClient(
      context: securityContext,
      client: client,
    );

    setState(() => _selectedClientId = client.id);
    _showSnackBar('Client ${client.fullName} added.');
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _navigateToConfirmation({
    required SecurityContext securityContext,
    required Appointment appointment,
    required MagicLinkToken magicLinkToken,
  }) async {
    final client = await _clientsRepository.getClient(
      context: securityContext,
      clientId: appointment.clientId,
    );
    final provider = await _providersRepository.getProvider(
      context: securityContext,
      providerId: appointment.providerId,
    );
    final service = _services.firstWhere(
      (s) => s.id == appointment.serviceId,
      orElse: () => _services.first,
    );
    final location = _locations.firstWhere(
      (l) => l.id == appointment.locationId,
      orElse: () => _locations.first,
    );

    if (client == null || provider == null) {
      _showSnackBar('Booking confirmed, but unable to show details.');
      return;
    }

    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BookingConfirmationPage(
          appointment: appointment,
          magicLinkToken: magicLinkToken,
          client: client,
          provider: provider,
          service: service,
          location: location,
        ),
      ),
    );
  }
}
