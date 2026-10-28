import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/providers/providers.dart';
import '../../../core/services/appointment_modification_service.dart';
import '../../../core/services/availability_service.dart';
import '../../../core/services/booking_payment_gateway.dart';
import '../../../core/services/magic_link_appointment_loader.dart';
import '../../../core/services/recurrence_service.dart';
import '../../../core/services/waitlist_service.dart';
import '../../../core/ui/components/components.dart';
import '../../../core/utils/safe_error_handler.dart';
import 'widgets/appointment_summary_card.dart';
import 'widgets/date_picker_row.dart';
import 'widgets/recurring_scope_selector.dart';
import 'widgets/reschedule_error_state.dart';
import 'widgets/reschedule_policy_notice.dart';
import 'widgets/reschedule_result_banner.dart';
import 'widgets/time_slots_widget.dart';

/// Enum for recurring appointment reschedule scope
enum RecurringRescheduleScope {
  thisOnly,
  allFuture,
}

/// Allows clients to reschedule their appointment via magic link access.
class RescheduleAppointmentPage extends ConsumerStatefulWidget {
  const RescheduleAppointmentPage({
    required this.tokenString,
    required this.businessId,
    super.key,
  });

  final String tokenString;
  final String businessId;

  @override
  ConsumerState<RescheduleAppointmentPage> createState() =>
      _RescheduleAppointmentPageState();
}

class _RescheduleAppointmentPageState
    extends ConsumerState<RescheduleAppointmentPage> {
  late final MagicLinkAppointmentLoader _appointmentLoader;
  late final AppointmentModificationService _modificationService;
  late final AvailabilityService _availabilityService;
  late final BookingPaymentGateway? _paymentGateway;
  late final WaitlistService _waitlistService;
  late final RecurrenceService _recurrenceService;

  MagicLinkAppointmentData? _data;
  bool _isLoading = true;
  bool _loadingSlots = false;
  bool _isSubmitting = false;
  String? _error;
  List<AvailabilitySlot> _slots = [];
  AvailabilitySlot? _selectedSlot;
  DateTime _selectedDate = DateTime.now();
  AppointmentModificationResult? _result;
  final _reasonController = TextEditingController();
  late AppConfig _config;
  bool _initialized = false;
  RecurringRescheduleScope? _recurringScope;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _config = ref.read(appConfigProvider);
    _buildServices();
    _loadAppointment();
  }

  void _buildServices() {
    _recurrenceService = ref.read(recurrenceServiceProvider);
    _appointmentLoader = ref.read(magicLinkAppointmentLoaderProvider);
    _availabilityService = ref.read(availabilityServiceProvider);
    _paymentGateway = ref.read(bookingPaymentGatewayProvider);
    final automationService = ref.read(automationServiceProvider);
    _waitlistService = ref.read(waitlistServiceProvider);

    _modificationService = AppointmentModificationService(
      bookingPolicies: _config.bookingPolicies,
      featureFlags: _config.featureFlags,
      appointmentsRepository: ref.read(appointmentsRepositoryProvider),
      clientsRepository: ref.read(clientsRepositoryProvider),
      providersRepository: ref.read(providersRepositoryProvider),
      servicesRepository: ref.read(servicesRepositoryProvider),
      locationsRepository: ref.read(locationsRepositoryProvider),
      availabilityService: _availabilityService,
      automationService: automationService,
      modificationRequestsRepository:
          ref.read(modificationRequestsRepositoryProvider),
      paymentGateway: _paymentGateway,
      paymentRepository: ref.read(paymentRepositoryProvider),
      onSlotReleased: (appointment) async {
        final slot = AvailabilitySlot(
          providerId: appointment.providerId,
          locationId: appointment.locationId,
          start: appointment.startTime,
          end: appointment.endTime,
        );

        await _waitlistService.handleReleasedSlot(
          actorContext: _data?.securityContext,
          appointment: appointment,
          slot: slot,
        );
      },
    );
  }

  Future<void> _loadAppointment() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _result = null;
    });

    try {
      final data = await _appointmentLoader.load(
        tokenString: widget.tokenString,
        businessId: widget.businessId,
      );

      setState(() {
        _data = data;
        _selectedDate = data.appointment.startTime;
      });

      await _fetchSlots();
    } on MagicLinkLoadException catch (error) {
      setState(() {
        _error = error.message;
      });
    } catch (error) {
      setState(() {
        _error = 'Unable to load appointment. Please try again later.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchSlots() async {
    final data = _data;
    if (data == null) return;

    setState(() {
      _loadingSlots = true;
      _slots = [];
    });

    final startOfDay = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );

    final query = AvailabilityQuery(
      start: startOfDay,
      end: startOfDay.add(const Duration(days: 1)),
      providerId: data.appointment.providerId,
      locationId: data.appointment.locationId,
      serviceDuration: data.appointment.endTime.difference(
        data.appointment.startTime,
      ),
    );

    try {
      final slots = await _availabilityService.generateSlots(
        context: data.securityContext,
        query: query,
      );

      setState(() {
        _slots = slots
            .where((slot) => slot.start.isAfter(DateTime.now()))
            .toList();
        _loadingSlots = false;
      });
    } catch (error) {
      setState(() {
        _loadingSlots = false;
      });
      _showSnack('Unable to load availability.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reschedule Appointment')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return RescheduleErrorState(
        error: _error,
        onRetry: _loadAppointment,
      );
    }

    if (_data == null) {
      return RescheduleErrorState(
        error: _error,
        onRetry: _loadAppointment,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAppointment,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppSpacing.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppointmentSummaryCard(data: _data!),
            VSpace.md,
            if (_data!.appointment.isRecurring) ...[
              RecurringScopeSelector(
                recurringScope: _recurringScope,
                onChanged: (value) => setState(() => _recurringScope = value),
              ),
              VSpace.md,
            ],
            ReschedulePolicyNotice(policy: _config.bookingPolicies),
            VSpace.md,
            DatePickerRow(
              selectedDate: _selectedDate,
              onPickDate: _pickDate,
            ),
            VSpace.md,
            TimeSlotsWidget(
              loadingSlots: _loadingSlots,
              slots: _slots,
              selectedSlot: _selectedSlot,
              onSlotSelected: (slot) {
                setState(() {
                  _selectedSlot = slot;
                });
              },
            ),
            VSpace.md,
            _buildNotesField(),
            VSpace.md,
            _buildSubmitButton(),
            if (_result != null) ...[
              VSpace.md,
              RescheduleResultBanner(result: _result),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNotesField() {
    return TextField(
      controller: _reasonController,
      maxLines: 3,
      decoration: const InputDecoration(
        labelText: 'Share details for your provider (optional)',
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildSubmitButton() {
    final enabled = !_isSubmitting && _selectedSlot != null;

    return FilledButton(
      onPressed: enabled ? _submit : null,
      child: _isSubmitting
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Text('Request new time'),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedSlot = null;
      });
      await _fetchSlots();
    }
  }

  Future<void> _submit() async {
    final data = _data;
    if (data == null || _selectedSlot == null) return;

    // If recurring, require scope selection
    if (data.appointment.isRecurring && _recurringScope == null) {
      _showSnack('Please select whether to reschedule just this appointment or all future appointments.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _result = null;
    });

    // Handle recurring series reschedule
    if (data.appointment.isRecurring && 
        _recurringScope == RecurringRescheduleScope.allFuture) {
      await _rescheduleAllFuture(data);
      return;
    }

    // For single appointment or "this only" for recurring
    if (data.appointment.isRecurring && 
        _recurringScope == RecurringRescheduleScope.thisOnly) {
      await _rescheduleAsException(data);
      return;
    }

    // Standard single appointment reschedule
    final result = await _modificationService.rescheduleAppointment(
      context: data.securityContext,
      appointmentId: data.appointment.id,
      newStartTime: _selectedSlot!.start,
      reason: _reasonController.text.trim().isEmpty
          ? null
          : _reasonController.text.trim(),
    );

    setState(() {
      _isSubmitting = false;
      _result = result;
      if (result.isSuccess && result.updatedAppointment != null) {
        _data = MagicLinkAppointmentData(
          token: data.token,
          appointment: result.updatedAppointment!,
          client: data.client,
          provider: data.provider,
          service: data.service,
          location: data.location,
          securityContext: data.securityContext,
        );
      }
    });

    if (result.status == AppointmentModificationStatus.error &&
        result.message != null) {
      _showSnack(result.message!);
    }
  }

  /// Reschedules a single instance in a recurring series as an exception.
  Future<void> _rescheduleAsException(MagicLinkAppointmentData data) async {
    try {
      final duration = data.appointment.endTime.difference(data.appointment.startTime);
      final updatedAppointment = data.appointment.copyWith(
        startTime: _selectedSlot!.start,
        endTime: _selectedSlot!.start.add(duration),
        date: DateTime(
          _selectedSlot!.start.year,
          _selectedSlot!.start.month,
          _selectedSlot!.start.day,
        ),
      );

      await _recurrenceService.updateRecurringInstance(
        businessId: data.securityContext.businessId,
        instance: data.appointment,
        updatedInstance: updatedAppointment,
      );

      setState(() {
        _isSubmitting = false;
        _result = AppointmentModificationResult(
          status: AppointmentModificationStatus.success,
          message: 'This appointment has been rescheduled. Other appointments in the series remain unchanged.',
          updatedAppointment: updatedAppointment,
        );
        _data = MagicLinkAppointmentData(
          token: data.token,
          appointment: updatedAppointment,
          client: data.client,
          provider: data.provider,
          service: data.service,
          location: data.location,
          securityContext: data.securityContext,
        );
      });
    } catch (error) {
      setState(() {
        _isSubmitting = false;
        _result = AppointmentModificationResult(
          status: AppointmentModificationStatus.error,
          message: SafeErrorHandler.handle(error),
        );
      });
    }
  }

  /// Reschedules all future appointments in the series.
  Future<void> _rescheduleAllFuture(MagicLinkAppointmentData data) async {
    try {
      final recurrenceId = data.appointment.recurrenceId;
      if (recurrenceId == null) {
        setState(() {
          _isSubmitting = false;
          _result = AppointmentModificationResult(
            status: AppointmentModificationStatus.error,
            message: 'Unable to identify the recurring series.',
          );
        });
        return;
      }

      // Get all future appointments in series
      final futureAppointments = await _recurrenceService.getUpcomingRecurringSeries(
        businessId: data.securityContext.businessId,
        recurrenceId: recurrenceId,
      );

      if (futureAppointments.isEmpty) {
        setState(() {
          _isSubmitting = false;
          _result = AppointmentModificationResult(
            status: AppointmentModificationStatus.error,
            message: 'No future appointments found in this series.',
          );
        });
        return;
      }

      // Calculate time shift from original to new time (for future use)
      final originalTime = data.appointment.startTime;
      final newTime = _selectedSlot!.start;
      // ignore: unused_local_variable
      final timeShift = Duration(
        hours: newTime.hour - originalTime.hour,
        minutes: newTime.minute - originalTime.minute,
      );

      // Update each future appointment with the time shift
      int updatedCount = 0;
      for (final apt in futureAppointments) {
        final duration = apt.endTime.difference(apt.startTime);
        final shiftedStart = DateTime(
          apt.startTime.year,
          apt.startTime.month,
          apt.startTime.day,
          newTime.hour,
          newTime.minute,
        );
        
        final updatedApt = apt.copyWith(
          startTime: shiftedStart,
          endTime: shiftedStart.add(duration),
        );

        await _recurrenceService.updateRecurringInstance(
          businessId: data.securityContext.businessId,
          instance: apt,
          updatedInstance: updatedApt,
        );
        updatedCount++;
      }

      setState(() {
        _isSubmitting = false;
        _result = AppointmentModificationResult(
          status: AppointmentModificationStatus.success,
          message: '$updatedCount appointments in the series have been rescheduled to the new time.',
        );
      });
    } catch (error) {
      setState(() {
        _isSubmitting = false;
        _result = AppointmentModificationResult(
          status: AppointmentModificationStatus.error,
          message: SafeErrorHandler.handle(error),
        );
      });
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
