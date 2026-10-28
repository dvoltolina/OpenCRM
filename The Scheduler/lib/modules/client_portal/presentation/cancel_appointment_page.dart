import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/config/app_config.dart';
import '../../../core/providers/providers.dart';
import '../../../core/ui/components/components.dart';
import '../../../core/services/appointment_modification_service.dart';
import '../../../core/services/availability_service.dart';
import '../../../core/services/magic_link_appointment_loader.dart';
import '../../../core/services/recurrence_service.dart';
import '../../../core/services/waitlist_service.dart';

/// Allows customers to cancel their appointment via secure magic link.
class CancelAppointmentPage extends ConsumerStatefulWidget {
  const CancelAppointmentPage({
    required this.tokenString,
    required this.businessId,
    super.key,
  });

  final String tokenString;
  final String businessId;

  @override
  ConsumerState<CancelAppointmentPage> createState() => _CancelAppointmentPageState();
}

/// Enum for recurring appointment cancellation scope
enum RecurringCancellationScope {
  thisOnly,
  entireSeries,
}

class _CancelAppointmentPageState extends ConsumerState<CancelAppointmentPage> {
  late final MagicLinkAppointmentLoader _appointmentLoader;
  late final AppointmentModificationService _modificationService;
  late final AvailabilityService _availabilityService;
  late final WaitlistService _waitlistService;
  late final RecurrenceService _recurrenceService;

  MagicLinkAppointmentData? _data;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;
  AppointmentModificationResult? _result;
  late AppConfig _config;
  bool _initialized = false;
  String? _selectedReason;
  final _detailsController = TextEditingController();
  RecurringCancellationScope? _recurringScope;

  static const _reasons = [
    'Feeling unwell',
    'Schedule conflict',
    'Found alternative',
    'Weather or travel issue',
    'Other',
  ];

  @override
  void dispose() {
    _detailsController.dispose();
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
      paymentGateway: ref.read(bookingPaymentGatewayProvider),
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
      });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cancel Appointment')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_data == null) {
      return _buildErrorState();
    }

    return RefreshIndicator(
      onRefresh: _loadAppointment,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppSpacing.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSummaryCard(),
            VSpace.md,
            if (_data!.appointment.isRecurring) ...[
              _buildRecurringScopeSelector(),
              VSpace.md,
            ],
            _buildPolicyNotice(),
            VSpace.md,
            _buildReasonField(),
            VSpace.md,
            _buildDetailsField(),
            VSpace.lg,
            _buildSubmitButton(),
            if (_result != null) ...[
              VSpace.md,
              _buildResultBanner(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final data = _data!;
    final dateFormat = DateFormat('EEEE, MMM d');
    final timeFormat = DateFormat('h:mm a');

    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data.service.name,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            VSpace.xs,
            Text(
              '${dateFormat.format(data.appointment.startTime)} • '
              '${timeFormat.format(data.appointment.startTime)}',
            ),
            VSpace.xs,
            Text(
              data.provider.fullName,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecurringScopeSelector() {
    final theme = Theme.of(context);
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.repeat,
                color: theme.colorScheme.primary,
                size: AppIconSize.sm,
              ),
              HSpace.xs,
              Text(
                'Recurring Appointment',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
          VSpace.sm,
          Text(
            'This appointment is part of a recurring series. What would you like to cancel?',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          VSpace.sm,
          RadioGroup<RecurringCancellationScope>(
            groupValue: _recurringScope ?? RecurringCancellationScope.thisOnly,
            onChanged: (value) => setState(() => _recurringScope = value),
            child: Column(
              children: [
                RadioListTile<RecurringCancellationScope>(
                  title: const Text('Cancel just this appointment'),
                  subtitle: const Text('Other appointments in the series will remain'),
                  value: RecurringCancellationScope.thisOnly,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
                RadioListTile<RecurringCancellationScope>(
                  title: const Text('Cancel entire series'),
                  subtitle: const Text('All future appointments in this series will be cancelled'),
                  value: RecurringCancellationScope.entireSeries,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyNotice() {
    final policy = _config.bookingPolicies;
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cancellation Policy',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          VSpace.xs,
          Text(
            'Cancellations are allowed up to '
            '${policy.cancellationWindow.inHours} hours before your visit.',
          ),
          if (policy.requireManualApprovalInsideWindow) ...[
            VSpace.xxs,
            const Text(
              'Requests inside the notice window may require approval.',
            ),
          ],
          if (policy.cancellationFeeAmount != null) ...[
            VSpace.xxs,
            Text(
              'Late cancellations may incur a fee of '
              '\$${policy.cancellationFeeAmount!.toStringAsFixed(2)}.',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReasonField() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedReason,
      items: _reasons
          .map((reason) => DropdownMenuItem(value: reason, child: Text(reason)))
          .toList(),
      onChanged: (value) => setState(() => _selectedReason = value),
      decoration: const InputDecoration(
        labelText: 'Reason for cancellation (optional)',
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildDetailsField() {
    return TextField(
      controller: _detailsController,
      maxLines: 4,
      decoration: const InputDecoration(
        labelText: 'Add details for your provider (optional)',
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return FilledButton(
      onPressed: _isSubmitting ? null : _submit,
      style: FilledButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
      child: _isSubmitting
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Text('Cancel appointment'),
    );
  }

  Widget _buildResultBanner() {
    final result = _result;
    if (result == null) return const SizedBox.shrink();

    final success = result.status == AppointmentModificationStatus.success;
    final color = success
        ? Theme.of(context).colorScheme.primaryContainer
        : Theme.of(context).colorScheme.secondaryContainer;

    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(result.message ?? ''),
          if (result.cancellationCode != null) ...[
            VSpace.xs,
            Text(
              'Confirmation code: ${result.cancellationCode}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
          if (result.request != null) ...[
            VSpace.xs,
            const Text(
              'We will notify you once the office reviews this request.',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: AppSpacing.pagePadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48),
            VSpace.sm,
            Text(
              _error ?? 'Unable to load appointment.',
              textAlign: TextAlign.center,
            ),
            VSpace.sm,
            FilledButton(
              onPressed: _loadAppointment,
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final data = _data;
    if (data == null) return;

    // If recurring, require scope selection
    if (data.appointment.isRecurring && _recurringScope == null) {
      _showSnack('Please select whether to cancel just this appointment or the entire series.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _result = null;
    });

    final reason = [
      if (_selectedReason != null) _selectedReason!,
      if (_detailsController.text.trim().isNotEmpty)
        _detailsController.text.trim(),
    ].join(' • ').trim();

    // Handle recurring series cancellation
    if (data.appointment.isRecurring && 
        _recurringScope == RecurringCancellationScope.entireSeries) {
      await _cancelEntireSeries(data, reason);
      return;
    }

    // Standard single appointment cancellation
    final result = await _modificationService.cancelAppointment(
      context: data.securityContext,
      appointmentId: data.appointment.id,
      reason: reason.isEmpty ? null : reason,
    );

    setState(() {
      _isSubmitting = false;
      _result = result;
    });

    if (result.status == AppointmentModificationStatus.error &&
        result.message != null) {
      _showSnack(result.message!);
    }
  }

  Future<void> _cancelEntireSeries(
    MagicLinkAppointmentData data,
    String reason,
  ) async {
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

      // Delete the entire series using RecurrenceService
      await _recurrenceService.deleteRecurringSeries(
        businessId: data.securityContext.businessId,
        recurrenceId: recurrenceId,
      );

      setState(() {
        _isSubmitting = false;
        _result = AppointmentModificationResult(
          status: AppointmentModificationStatus.success,
          message: 'All appointments in the series have been cancelled.',
          cancellationCode: recurrenceId.substring(0, 8).toUpperCase(),
        );
      });
    } catch (error) {
      setState(() {
        _isSubmitting = false;
        _result = AppointmentModificationResult(
          status: AppointmentModificationStatus.error,
          message: 'Failed to cancel series: ${error.toString()}',
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
