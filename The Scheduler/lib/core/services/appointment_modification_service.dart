import 'package:uuid/uuid.dart';

import '../config/app_config.dart' show BookingPolicies;
import '../config/feature_flags.dart';
import '../../data/models/appointment.dart';
import '../../data/models/client.dart';
import '../../data/models/location.dart';
import '../../data/models/modification_request.dart';
import '../../data/models/payment.dart';
import '../../data/models/provider.dart';
import '../../data/models/security_context.dart';
import '../../data/models/service.dart';
import '../../data/repositories/appointments_repository.dart';
import '../../data/repositories/clients_repository.dart';
import '../../data/repositories/locations_repository.dart';
import '../../data/repositories/modification_requests_repository.dart';
import '../../data/repositories/providers_repository.dart';
import '../../data/repositories/services_repository.dart';
import '../../data/repositories/payment_repository.dart';
import 'automation_service.dart';
import 'availability_service.dart';
import 'booking_context_snapshot.dart';
import 'booking_payment_gateway.dart';

/// Result status for reschedule/cancellation attempts.
enum AppointmentModificationStatus { success, requiresApproval, denied, error }

/// Summary of a modification attempt.
class AppointmentModificationResult {
  AppointmentModificationResult({
    required this.status,
    this.message,
    this.policyViolations = const [],
    this.updatedAppointment,
    this.request,
    this.payment,
    this.cancellationCode,
  });

  final AppointmentModificationStatus status;
  final String? message;
  final List<String> policyViolations;
  final Appointment? updatedAppointment;
  final ModificationRequest? request;
  final Payment? payment;
  final String? cancellationCode;

  bool get isSuccess => status == AppointmentModificationStatus.success;
}

/// Internal evaluation payload.
class ModificationEvaluation {
  ModificationEvaluation({
    required this.isAllowed,
    required this.requiresApproval,
    required this.policyWindowBreached,
    this.feeAmount,
    this.notices = const [],
  });

  final bool isAllowed;
  final bool requiresApproval;
  final bool policyWindowBreached;
  final double? feeAmount;
  final List<String> notices;
}

/// Handles business rules for customer initiated reschedule/cancellation.
class AppointmentModificationService {
  AppointmentModificationService({
    required BookingPolicies bookingPolicies,
    required FeatureFlags featureFlags,
    required AppointmentsRepository appointmentsRepository,
    required ClientsRepository clientsRepository,
    required ProvidersRepository providersRepository,
    required ServicesRepository servicesRepository,
    required LocationsRepository locationsRepository,
    required AvailabilityService availabilityService,
    required AutomationService automationService,
    required ModificationRequestsRepository modificationRequestsRepository,
    BookingPaymentGateway? paymentGateway,
    PaymentRepository? paymentRepository,
    this.onSlotReleased,
  }) : _bookingPolicies = bookingPolicies,
       _featureFlags = featureFlags,
       _appointmentsRepository = appointmentsRepository,
       _clientsRepository = clientsRepository,
       _providersRepository = providersRepository,
       _servicesRepository = servicesRepository,
       _locationsRepository = locationsRepository,
       _availabilityService = availabilityService,
       _automationService = automationService,
       _paymentGateway = paymentGateway,
       _paymentRepository = paymentRepository ?? PaymentRepository(),
       _modificationRequestsRepository = modificationRequestsRepository;

  final BookingPolicies _bookingPolicies;
  final FeatureFlags _featureFlags;
  final AppointmentsRepository _appointmentsRepository;
  final ClientsRepository _clientsRepository;
  final ProvidersRepository _providersRepository;
  final ServicesRepository _servicesRepository;
  final LocationsRepository _locationsRepository;
  final AvailabilityService _availabilityService;
  final AutomationService _automationService;
  final BookingPaymentGateway? _paymentGateway;
  final PaymentRepository _paymentRepository;
  final ModificationRequestsRepository _modificationRequestsRepository;
  final Future<void> Function(Appointment appointment)? onSlotReleased;

  static const _uuid = Uuid();

  /// Preview reschedule policy impacts without persisting.
  Future<ModificationEvaluation> previewReschedule({
    required SecurityContext context,
    required Appointment appointment,
    required DateTime newStartTime,
  }) async {
    return _evaluateReschedulePolicy(context, appointment, newStartTime);
  }

  /// Attempts to reschedule an appointment.
  Future<AppointmentModificationResult> rescheduleAppointment({
    required SecurityContext context,
    required String appointmentId,
    required DateTime newStartTime,
    String? reason,
  }) async {
    try {
      final data = await _loadAppointmentContext(context, appointmentId);

      if (data.appointment.status == AppointmentStatus.cancelled) {
        return AppointmentModificationResult(
          status: AppointmentModificationStatus.denied,
          message: 'This appointment has already been cancelled.',
        );
      }

      if (data.appointment.endTime.isBefore(DateTime.now())) {
        return AppointmentModificationResult(
          status: AppointmentModificationStatus.denied,
          message: 'Past appointments cannot be rescheduled.',
        );
      }

      final evaluation = await _evaluateReschedulePolicy(
        context,
        data.appointment,
        newStartTime,
      );

      if (!evaluation.isAllowed && !evaluation.requiresApproval) {
        return AppointmentModificationResult(
          status: AppointmentModificationStatus.denied,
          message: 'Unable to reschedule this time.',
          policyViolations: evaluation.notices,
        );
      }

      final duration = data.appointment.endTime.difference(
        data.appointment.startTime,
      );
      final newEndTime = newStartTime.add(duration);

      final slot = AvailabilitySlot(
        providerId: data.appointment.providerId,
        locationId: data.appointment.locationId,
        start: newStartTime,
        end: newEndTime,
      );

      final slotAvailable = await _availabilityService.isSlotBookable(
        context: context,
        slot: slot,
      );

      if (!slotAvailable) {
        return AppointmentModificationResult(
          status: AppointmentModificationStatus.denied,
          message: 'Selected time is no longer available.',
        );
      }

      if (evaluation.requiresApproval) {
        final request = await _createModificationRequest(
          context: context,
          appointment: data.appointment,
          type: ModificationRequestType.reschedule,
          reason: reason,
          requestedStartTime: newStartTime,
          policyWindowBreached: evaluation.policyWindowBreached,
          feeAmount: evaluation.feeAmount,
        );

        return AppointmentModificationResult(
          status: AppointmentModificationStatus.requiresApproval,
          message:
              'Your request was routed to the provider because it is inside the protected notice window.',
          request: request,
          policyViolations: evaluation.notices,
        );
      }

      Payment? feePayment;
      if (evaluation.feeAmount != null && evaluation.feeAmount! > 0) {
        if (!_featureFlags.enablePayments || _paymentGateway == null) {
          return AppointmentModificationResult(
            status: AppointmentModificationStatus.error,
            message:
                'Unable to collect the reschedule fee. Please contact the office.',
          );
        }

        final snapshot = BookingContextSnapshot(
          client: data.client,
          provider: data.provider,
          service: data.service,
          location: data.location,
          startTime: newStartTime,
          endTime: newEndTime,
        );

        feePayment = await _paymentGateway.collectDeposit(
          snapshot: snapshot,
          context: context,
          amount: evaluation.feeAmount!,
          appointmentId: data.appointment.id,
          paymentType: PaymentType.rescheduleFee,
        );
        await _paymentRepository.upsertPayment(
          context: context,
          payment: feePayment,
        );
      }

      final updatedAppointment = data.appointment.copyWith(
        startTime: newStartTime,
        endTime: newEndTime,
        date: DateTime(newStartTime.year, newStartTime.month, newStartTime.day),
        rescheduleFeeRequired: evaluation.feeAmount != null,
        rescheduleFeeCents: evaluation.feeAmount != null
            ? (evaluation.feeAmount! * 100).round()
            : null,
        rescheduleFeeStatus: feePayment != null
            ? PaymentStatus.completed
            : PaymentStatus.none,
        reschedulePaymentId: feePayment?.id,
      );

      await _appointmentsRepository.upsertAppointment(
        context: context,
        appointment: updatedAppointment,
      );

      await _logAutoApproval(
        context: context,
        appointment: updatedAppointment,
        type: ModificationRequestType.reschedule,
        reason: reason,
        policyWindowBreached: evaluation.policyWindowBreached,
        feeAmount: evaluation.feeAmount,
      );

      await _automationService.onAppointmentRescheduled(
        appointmentId: updatedAppointment.id,
        clientId: data.client.id,
        clientName: data.client.fullName,
        clientEmail: data.client.email ?? '',
        clientPhone: data.client.phone,
        oldDate: data.appointment.startTime,
        newDate: newStartTime,
        newTime:
            '${newStartTime.hour.toString().padLeft(2, '0')}:${newStartTime.minute.toString().padLeft(2, '0')}',
        providerName: data.provider.fullName,
        location: data.location.name ?? data.location.address,
        businessId: context.businessId,
        userId: context.userId,
      );

      return AppointmentModificationResult(
        status: AppointmentModificationStatus.success,
        message: 'Appointment rescheduled successfully.',
        updatedAppointment: updatedAppointment,
        payment: feePayment,
      );
    } catch (error) {
      return AppointmentModificationResult(
        status: AppointmentModificationStatus.error,
        message: error.toString(),
      );
    }
  }

  /// Attempts to cancel an appointment.
  Future<AppointmentModificationResult> cancelAppointment({
    required SecurityContext context,
    required String appointmentId,
    String? reason,
  }) async {
    try {
      final data = await _loadAppointmentContext(context, appointmentId);

      if (data.appointment.status == AppointmentStatus.cancelled) {
        return AppointmentModificationResult(
          status: AppointmentModificationStatus.denied,
          message: 'This appointment is already cancelled.',
        );
      }

      if (data.appointment.endTime.isBefore(DateTime.now())) {
        return AppointmentModificationResult(
          status: AppointmentModificationStatus.denied,
          message: 'Past appointments cannot be cancelled.',
        );
      }

      final evaluation = _evaluateCancellationPolicy(data.appointment);

      if (evaluation.requiresApproval) {
        final request = await _createModificationRequest(
          context: context,
          appointment: data.appointment,
          type: ModificationRequestType.cancel,
          reason: reason,
          policyWindowBreached: evaluation.policyWindowBreached,
          feeAmount: evaluation.feeAmount,
        );

        return AppointmentModificationResult(
          status: AppointmentModificationStatus.requiresApproval,
          message:
              'Your cancellation request requires manual approval. We will notify you once the team reviews it.',
          request: request,
          policyViolations: evaluation.notices,
        );
      }

      Payment? cancellationFeePayment;
      if (evaluation.feeAmount != null && evaluation.feeAmount! > 0) {
        if (!_featureFlags.enablePayments || _paymentGateway == null) {
          return AppointmentModificationResult(
            status: AppointmentModificationStatus.error,
            message:
                'Unable to collect the cancellation fee. Please contact the office.',
          );
        }

        final snapshot = BookingContextSnapshot(
          client: data.client,
          provider: data.provider,
          service: data.service,
          location: data.location,
          startTime: data.appointment.startTime,
          endTime: data.appointment.endTime,
        );

        cancellationFeePayment = await _paymentGateway.collectDeposit(
          snapshot: snapshot,
          context: context,
          amount: evaluation.feeAmount!,
          appointmentId: data.appointment.id,
          paymentType: PaymentType.cancellationFee,
        );
        await _paymentRepository.upsertPayment(
          context: context,
          payment: cancellationFeePayment,
        );
      }

      Payment? refundPayment;
      final refundEligible = !evaluation.policyWindowBreached;
      if (refundEligible) {
        refundPayment = await _issueDepositRefund(
          context: context,
          data: data,
          reason: reason,
        );
      }

      final cancellationCode = _generateConfirmationCode(data.appointment.id);

      final updates = <String, dynamic>{
        'cancellationFeeRequired': evaluation.feeAmount != null,
        if (evaluation.feeAmount != null)
          'cancellationFeeCents': (evaluation.feeAmount! * 100).round(),
        'cancellationFeeStatus': cancellationFeePayment != null
            ? PaymentStatus.completed.name
            : PaymentStatus.none.name,
        if (cancellationFeePayment != null)
          'cancellationPaymentId': cancellationFeePayment.id,
        if (refundPayment != null) ...{
          'paymentStatus': PaymentStatus.refunded.name,
          'refundStatus': refundPayment.status.name,
          'refundAmountCents': refundPayment.amountCents,
          'refundPaymentId': refundPayment.id,
          'refundProcessedAt': refundPayment.completedAt ?? DateTime.now(),
        },
      };

      await _appointmentsRepository.cancelAppointment(
        context: context,
        appointmentId: data.appointment.id,
        reason: reason,
        cancellationCode: cancellationCode,
        additionalUpdates: updates,
      );

      await _logAutoApproval(
        context: context,
        appointment: data.appointment.copyWith(
          status: AppointmentStatus.cancelled,
        ),
        type: ModificationRequestType.cancel,
        reason: reason,
        policyWindowBreached: evaluation.policyWindowBreached,
        feeAmount: evaluation.feeAmount,
      );

      await _automationService.onAppointmentCancelled(
        appointmentId: data.appointment.id,
        clientId: data.client.id,
        clientName: data.client.fullName,
        clientEmail: data.client.email ?? '',
        clientPhone: data.client.phone,
        appointmentDate: data.appointment.startTime,
        appointmentTime:
            '${data.appointment.startTime.hour.toString().padLeft(2, '0')}:${data.appointment.startTime.minute.toString().padLeft(2, '0')}',
        providerName: data.provider.fullName,
        cancellationReason: reason,
        businessId: context.businessId,
        userId: context.userId,
      );

      if (onSlotReleased != null) {
        await onSlotReleased!(data.appointment);
      }

      return AppointmentModificationResult(
        status: AppointmentModificationStatus.success,
        message: 'Appointment cancelled.',
        cancellationCode: cancellationCode,
        payment: cancellationFeePayment ?? refundPayment,
      );
    } catch (error) {
      return AppointmentModificationResult(
        status: AppointmentModificationStatus.error,
        message: error.toString(),
      );
    }
  }

  Future<ModificationEvaluation> _evaluateReschedulePolicy(
    SecurityContext context,
    Appointment appointment,
    DateTime newStartTime,
  ) async {
    final now = DateTime.now();
    final notices = <String>[];

    if (newStartTime.isBefore(now)) {
      notices.add('Selected time occurs in the past.');
      return ModificationEvaluation(
        isAllowed: false,
        requiresApproval: false,
        policyWindowBreached: false,
        notices: notices,
      );
    }

    final minimumNotice = _bookingPolicies.minimumBookingNotice;
    if (minimumNotice != null &&
        newStartTime.isBefore(now.add(minimumNotice))) {
      notices.add(
        'Reschedules require at least ${minimumNotice.inHours} hours notice.',
      );
      return ModificationEvaluation(
        isAllowed: false,
        requiresApproval: false,
        policyWindowBreached: true,
        notices: notices,
      );
    }

    final cancellationWindow = _bookingPolicies.cancellationWindow;
    final timeUntilAppointment = appointment.startTime.difference(now).abs();
    final insideWindow = timeUntilAppointment < cancellationWindow;

    if (insideWindow) {
      notices.add(
        'This change is inside the ${cancellationWindow.inHours}-hour notice window.',
      );
    }

    const minShift = Duration(minutes: 5);
    if ((newStartTime.difference(appointment.startTime)).abs() < minShift) {
      notices.add('New time matches the existing appointment.');
      return ModificationEvaluation(
        isAllowed: false,
        requiresApproval: false,
        policyWindowBreached: false,
        notices: notices,
      );
    }

    final requiresApproval =
        insideWindow && _bookingPolicies.requireManualApprovalInsideWindow;

    final feeAmount = insideWindow
        ? _bookingPolicies.rescheduleFeeAmount
        : null;

    return ModificationEvaluation(
      isAllowed: true,
      requiresApproval: requiresApproval,
      policyWindowBreached: insideWindow,
      feeAmount: feeAmount,
      notices: notices,
    );
  }

  ModificationEvaluation _evaluateCancellationPolicy(Appointment appointment) {
    final now = DateTime.now();
    final cancellationWindow = _bookingPolicies.cancellationWindow;
    final timeUntilAppointment = appointment.startTime.difference(now).abs();
    final insideWindow = timeUntilAppointment < cancellationWindow;

    final requiresApproval =
        insideWindow && _bookingPolicies.requireManualApprovalInsideWindow;

    final feeAmount = insideWindow
        ? _bookingPolicies.cancellationFeeAmount
        : null;

    return ModificationEvaluation(
      isAllowed: true,
      requiresApproval: requiresApproval,
      policyWindowBreached: insideWindow,
      feeAmount: feeAmount,
      notices: insideWindow
          ? [
              'Cancellations inside ${cancellationWindow.inHours} hours are flagged for review.',
            ]
          : const [],
    );
  }

  Future<Payment?> _issueDepositRefund({
    required SecurityContext context,
    required _LoadedAppointmentContext data,
    String? reason,
  }) async {
    if (data.appointment.paymentId == null ||
        data.appointment.paymentStatus != PaymentStatus.completed ||
        (data.appointment.paymentAmountCents ?? 0) <= 0) {
      return null;
    }

    final sourcePayment = await _paymentRepository.getPaymentById(
      context,
      data.appointment.paymentId!,
    );

    if (sourcePayment == null) {
      return null;
    }

    final refundPayment = Payment(
      id: _uuid.v4(),
      businessId: sourcePayment.businessId,
      appointmentId: sourcePayment.appointmentId,
      clientId: sourcePayment.clientId,
      amountCents:
          data.appointment.paymentAmountCents ?? sourcePayment.amountCents,
      currency: sourcePayment.currency,
      status: PaymentStatus.completed,
      type: PaymentType.refund,
      stripePaymentIntentId: sourcePayment.stripePaymentIntentId,
      stripeRefundId:
          sourcePayment.stripeRefundId ??
          'manual_refund_${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now(),
      completedAt: DateTime.now(),
      parentPaymentId: sourcePayment.id,
      reason: reason ?? 'Appointment cancelled outside policy window',
    );

    await _paymentRepository.recordRefund(
      context: context,
      sourcePayment: sourcePayment,
      refundPayment: refundPayment,
    );

    return refundPayment;
  }

  Future<ModificationRequest> _createModificationRequest({
    required SecurityContext context,
    required Appointment appointment,
    required ModificationRequestType type,
    String? reason,
    DateTime? requestedStartTime,
    bool policyWindowBreached = false,
    double? feeAmount,
  }) async {
    final request = ModificationRequest(
      id: _uuid.v4(),
      businessId: context.businessId,
      appointmentId: appointment.id,
      clientId: appointment.clientId,
      providerId: appointment.providerId,
      type: type,
      requestedStartTime: requestedStartTime,
      reason: reason,
      policyWindowBreached: policyWindowBreached,
      feeRequired: feeAmount != null && feeAmount > 0,
      feeAmount: feeAmount,
      createdAt: DateTime.now(),
      metadata: {'statusAtRequest': appointment.status.name},
    );

    await _modificationRequestsRepository.saveRequest(
      context: context,
      request: request,
    );

    return request;
  }

  Future<void> _logAutoApproval({
    required SecurityContext context,
    required Appointment appointment,
    required ModificationRequestType type,
    String? reason,
    bool policyWindowBreached = false,
    double? feeAmount,
  }) async {
    final request = ModificationRequest(
      id: _uuid.v4(),
      businessId: context.businessId,
      appointmentId: appointment.id,
      clientId: appointment.clientId,
      providerId: appointment.providerId,
      type: type,
      status: ModificationRequestStatus.autoApproved,
      reason: reason,
      policyWindowBreached: policyWindowBreached,
      feeRequired: feeAmount != null && feeAmount > 0,
      feeAmount: feeAmount,
      createdAt: DateTime.now(),
      decisionAt: DateTime.now(),
      decidedBy: 'system',
      metadata: {'statusAfter': appointment.status.name},
    );

    await _modificationRequestsRepository.saveRequest(
      context: context,
      request: request,
    );
  }

  Future<_LoadedAppointmentContext> _loadAppointmentContext(
    SecurityContext context,
    String appointmentId,
  ) async {
    final appointment = await _appointmentsRepository.getAppointment(
      context: context,
      appointmentId: appointmentId,
    );

    if (appointment == null) {
      throw Exception('Appointment not found.');
    }

    final results = await Future.wait([
      _clientsRepository.getClient(
        context: context,
        clientId: appointment.clientId,
      ),
      _providersRepository.getProvider(
        context: context,
        providerId: appointment.providerId,
      ),
      _servicesRepository.getService(
        context: context,
        serviceId: appointment.serviceId,
      ),
      _locationsRepository.getLocation(
        context: context,
        locationId: appointment.locationId,
      ),
    ]);

    final client = results[0] as Client?;
    final provider = results[1] as Provider?;
    final service = results[2] as Service?;
    final location = results[3] as Location?;

    if (client == null ||
        provider == null ||
        service == null ||
        location == null) {
      throw Exception('Unable to load related appointment data.');
    }

    return _LoadedAppointmentContext(
      appointment: appointment,
      client: client,
      provider: provider,
      service: service,
      location: location,
    );
  }

  String _generateConfirmationCode(String appointmentId) {
    final trimmed = appointmentId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    return trimmed.length <= 8
        ? trimmed.toUpperCase()
        : trimmed.substring(0, 8).toUpperCase();
  }
}

class _LoadedAppointmentContext {
  _LoadedAppointmentContext({
    required this.appointment,
    required this.client,
    required this.provider,
    required this.service,
    required this.location,
  });

  final Appointment appointment;
  final Client client;
  final Provider provider;
  final Service service;
  final Location location;
}
