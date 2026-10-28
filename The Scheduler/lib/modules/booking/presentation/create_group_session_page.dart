import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/config/app_config.dart';
import '../../../core/constants/user_messages.dart';
import '../../../core/providers/providers.dart';
import '../../../core/ui/components/components.dart';
import '../../../core/utils/safe_error_handler.dart';
import '../../../data/models/appointment.dart';
import '../../../data/models/recurrence_pattern.dart';
import '../../../data/models/security_context.dart';
import '../../../data/repositories/appointments_repository.dart';
import 'widgets/recurrence_picker.dart';

/// Staff-facing form to create group sessions/classes.
class CreateGroupSessionPage extends ConsumerStatefulWidget {
  const CreateGroupSessionPage({super.key});

  @override
  ConsumerState<CreateGroupSessionPage> createState() =>
      _CreateGroupSessionPageState();
}

class _CreateGroupSessionPageState
    extends ConsumerState<CreateGroupSessionPage> {
  static const _uuid = Uuid();
  final _formKey = GlobalKey<FormState>();
  AppointmentsRepository get _appointmentsRepository =>
      ref.read(appointmentsRepositoryProvider);

  String? _serviceId;
  String? _providerId;
  String? _locationId;
  String? _notes;
  bool _publicVisibility = true;
  int _capacity = 10;
  int _durationMinutes = 60;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  DateTime? _registrationDeadline;
  RecurrencePattern? _recurrencePattern;
  bool _submitting = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(appConfigProvider);
    final securityContextAsync = ref.watch(securityContextProvider);

    return securityContextAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) =>
          const Scaffold(body: Center(child: Text(UserMessages.authError))),
      data: (securityContext) {
        if (securityContext == null) {
          return const Scaffold(
            body: Center(child: Text('Sign in to create sessions.')),
          );
        }

        // Load services, providers, locations from streams
        final servicesAsync = ref.watch(servicesStreamProvider(securityContext));
        final providersAsync = ref.watch(providersStreamProvider(securityContext));
        final locationsAsync = ref.watch(locationsStreamProvider(securityContext));

        if (servicesAsync.isLoading ||
            providersAsync.isLoading ||
            locationsAsync.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (servicesAsync.hasError ||
            providersAsync.hasError ||
            locationsAsync.hasError) {
          return Scaffold(
            body: Center(
              child: Text(
                'Error loading data: ${servicesAsync.error ?? providersAsync.error ?? locationsAsync.error}',
              ),
            ),
          );
        }

        final services = servicesAsync.value ?? [];
        final providers = providersAsync.value ?? [];
        final locations = locationsAsync.value ?? [];

        return ScrollablePageScaffold(
          title: 'Create Group Session',
          body: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PageSection(
                  title: 'Session Details',
                  child: FormFieldGroup(
                    children: [
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Service'),
                        initialValue: _serviceId,
                        items: services
                            .map(
                              (service) => DropdownMenuItem(
                                value: service.id,
                                child: Text(service.name),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => setState(() => _serviceId = value),
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Select a service' : null,
                      ),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Provider'),
                        initialValue: _providerId,
                        items: providers
                            .map(
                              (provider) => DropdownMenuItem(
                                value: provider.id,
                                child: Text(provider.fullName),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => setState(() => _providerId = value),
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Select a provider' : null,
                      ),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Location'),
                        initialValue: _locationId,
                        items: locations
                            .map(
                              (location) => DropdownMenuItem(
                                value: location.id,
                                child: Text(location.name ?? location.id),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => setState(() => _locationId = value),
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Select a location' : null,
                      ),
                    ],
                  ),
                ),
                VSpace.lg,
                PageSection(
                  title: 'Capacity & Duration',
                  child: FormFieldGroup(
                    children: [
                      TextFormField(
                        decoration:
                            const InputDecoration(labelText: 'Capacity (attendees)'),
                        initialValue: '$_capacity',
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          final parsed = int.tryParse(value ?? '');
                          if (parsed == null || parsed <= 0) {
                            return 'Enter a valid capacity';
                          }
                          return null;
                        },
                        onChanged: (value) =>
                            setState(() => _capacity = int.tryParse(value) ?? 10),
                      ),
                      TextFormField(
                        decoration:
                            const InputDecoration(labelText: 'Duration (minutes)'),
                        initialValue: '$_durationMinutes',
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          final parsed = int.tryParse(value ?? '');
                          if (parsed == null || parsed <= 0) {
                            return 'Enter a valid duration';
                          }
                          return null;
                        },
                        onChanged: (value) => setState(
                            () => _durationMinutes = int.tryParse(value) ?? 60),
                      ),
                    ],
                  ),
                ),
                VSpace.lg,
                PageSection(
                  title: 'Schedule',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppListTile(
                        title: 'Date',
                        subtitle: DateFormat.yMMMd().format(_selectedDate),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setState(() => _selectedDate = picked);
                          }
                        },
                      ),
                      VSpace.sm,
                      AppListTile(
                        title: 'Start time',
                        subtitle: _selectedTime.format(context),
                        trailing: const Icon(Icons.access_time),
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: _selectedTime,
                          );
                          if (picked != null) {
                            setState(() => _selectedTime = picked);
                          }
                        },
                      ),
                      VSpace.sm,
                      AppListTile(
                        title: 'Registration deadline (optional)',
                        subtitle: _registrationDeadline == null
                            ? 'Not set'
                            : DateFormat.yMMMd().format(_registrationDeadline!),
                        trailing: const Icon(Icons.event_busy),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _registrationDeadline ?? _selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          setState(() => _registrationDeadline = picked);
                        },
                      ),
                    ],
                  ),
                ),
                VSpace.lg,
                PageSection(
                  title: 'Recurrence',
                  child: RecurrencePicker(
                    initialPattern: _recurrencePattern,
                    startDate: _selectedDate,
                    onChanged: (pattern) =>
                        setState(() => _recurrencePattern = pattern),
                  ),
                ),
                VSpace.lg,
                PageSection(
                  title: 'Visibility',
                  child: SwitchListTile(
                    value: _publicVisibility,
                    onChanged: (value) =>
                        setState(() => _publicVisibility = value),
                    title: const Text('Public visibility'),
                    subtitle: const Text('Show on client portal when enabled'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                VSpace.lg,
                PageSection(
                  title: 'Notes',
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      hintText: 'Add any additional notes about this session',
                    ),
                    maxLines: 3,
                    onChanged: (value) => _notes = value,
                  ),
                ),
                VSpace.xl,
                if (_error != null) ...[
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                  VSpace.md,
                ],
                FormButtonRow(
                  cancelLabel: 'Cancel',
                  submitLabel: 'Create Session',
                  onCancel: () => Navigator.pop(context),
                  onSubmit: () => _submit(config, securityContext),
                  isSubmitting: _submitting,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _submit(
    AppConfig config,
    SecurityContext securityContext,
  ) async {
    if (!_formKey.currentState!.validate()) return;
    final serviceId = _serviceId!;
    final providerId = _providerId!;
    final locationId = _locationId!;
    final start = _combineSelectedDateTime();
    final end = start.add(Duration(minutes: _durationMinutes));
    final appointmentId = _uuid.v4();
    final normalizedPattern = _recurrencePattern != null
        ? _recurrencePattern!.copyWith(
            id: appointmentId,
            createdAt: DateTime.now(),
          )
        : null;

    final appointment = Appointment(
      id: appointmentId,
      businessId: securityContext.businessId,
      clientId: 'group_session',
      providerId: providerId,
      serviceId: serviceId,
      locationId: locationId,
      startTime: start,
      endTime: end,
      date: DateTime(start.year, start.month, start.day),
      status: AppointmentStatus.confirmed,
      notes: _notes,
      createdAt: DateTime.now(),
      isGroupSession: true,
      capacity: _capacity,
      publicVisibility: _publicVisibility,
      registrationDeadline: _registrationDeadline,
      isRecurring: normalizedPattern != null,
      recurrenceId: normalizedPattern != null ? appointmentId : null,
      recurrencePattern: normalizedPattern,
    );

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      if (normalizedPattern != null) {
        await _appointmentsRepository.createRecurringAppointment(
          context: securityContext,
          parentAppointment: appointment,
          pattern: normalizedPattern,
        );
      } else {
        await _appointmentsRepository.upsertAppointment(
          context: securityContext,
          appointment: appointment,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group session created')),
      );
      Navigator.of(context).maybePop();
    } catch (e) {
      if (!mounted) return;
      final safeMessage = SafeErrorHandler.handle(e, context: 'creating group session');
      setState(() {
        _error = safeMessage;
        _submitting = false;
      });
    }
  }

  DateTime _combineSelectedDateTime() {
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
  }
}
