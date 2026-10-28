import 'package:uuid/uuid.dart';

import '../utils/date_formatters.dart';

import '../config/app_config.dart' show BookingPolicies;
import '../config/feature_flags.dart';
import '../../data/models/appointment.dart';
import '../../data/models/client.dart';
import '../../data/models/location.dart';
import '../../data/models/magic_link_token.dart';
import '../../data/models/payment.dart';
import '../../data/models/provider.dart';
import '../../data/models/recurrence_pattern.dart';
import '../../data/models/security_context.dart';
import '../../data/models/service.dart';
import '../../data/repositories/appointments_repository.dart';
import '../../data/repositories/clients_repository.dart';
import '../../data/repositories/locations_repository.dart';
import '../../data/repositories/providers_repository.dart';
import '../../data/repositories/services_repository.dart';
import '../../data/repositories/payment_repository.dart';
import 'automation_service.dart';
import 'availability_service.dart';
import 'booking_context_snapshot.dart';
import 'booking_payment_gateway.dart';
import 'magic_link_service.dart';
import 'recurrence_service.dart';

class BookingDraft {
  BookingDraft({
    this.appointmentId,
    required this.clientId,
    required this.providerId,
    required this.serviceId,
    required this.locationId,
    required this.startTime,
    this.notes,
    this.status = AppointmentStatus.confirmed,
    this.serviceDurationOverride,
    this.recurrencePattern,
  });

  final String? appointmentId;
  final String clientId;
  final String providerId;
  final String serviceId;
  final String locationId;
  final DateTime startTime;
  final String? notes;
  final AppointmentStatus status;
  final Duration? serviceDurationOverride;
  final RecurrencePattern? recurrencePattern;
}

enum BookingConflictType {
  missingService,
  missingProvider,
  missingClient,
  missingLocation,
  pastDate,
  insufficientNotice,
  beyondAdvanceWindow,
  providerUnavailable,
  doubleBooked,
  bufferViolation,
  capacityReached,
  registrationClosed,
  alreadyJoined,
  invalidGroupSession,
  recurrenceConflict,
}

class BookingConflict {
  const BookingConflict(this.type, this.message);

  final BookingConflictType type;
  final String message;
}

class BookingValidationResult {
  const BookingValidationResult({
    required this.isValid,
    required this.conflicts,
    this.requiresDeposit = false,
    this.depositAmount,
    this.waitlistAllowed = false,
    this.snapshot,
  });

  final bool isValid;
  final List<BookingConflict> conflicts;
  final bool requiresDeposit;
  final double? depositAmount;
  final bool waitlistAllowed;
  final BookingContextSnapshot? snapshot;
}

enum BookingSubmissionStatus { success, validationFailed, error }

class BookingSubmissionResult {
  const BookingSubmissionResult({
    required this.status,
    this.validationResult,
    this.appointment,
    this.error,
    this.payment,
    this.magicLinkToken,
  });

  final BookingSubmissionStatus status;
  final BookingValidationResult? validationResult;
  final Appointment? appointment;
  final Object? error;
  final Payment? payment;
  final MagicLinkToken? magicLinkToken;
}

class BookingRulesEngine {
  BookingRulesEngine({
    required this.bookingPolicies,
    required this.featureFlags,
    required this.appointmentsRepository,
    required this.clientsRepository,
    required this.providersRepository,
    required this.servicesRepository,
    required this.locationsRepository,
    required this.availabilityService,
    required this.automationService,
    required this.paymentRepository,
    this.paymentGateway,
    MagicLinkService? magicLinkService,
    RecurrenceService? recurrenceService,
  })  : magicLinkService = magicLinkService ?? MagicLinkService(),
        recurrenceService = recurrenceService ?? RecurrenceService();

  final BookingPolicies bookingPolicies;
  final FeatureFlags featureFlags;
  final AppointmentsRepository appointmentsRepository;
  final ClientsRepository clientsRepository;
  final ProvidersRepository providersRepository;
  final ServicesRepository servicesRepository;
  final LocationsRepository locationsRepository;
  final AvailabilityService availabilityService;
  final AutomationService automationService;
  final PaymentRepository paymentRepository;
  final BookingPaymentGateway? paymentGateway;
  final MagicLinkService magicLinkService;
  final RecurrenceService recurrenceService;

  static const _uuid = Uuid();

  Future<BookingValidationResult> validateDraft({
    required SecurityContext context,
    required BookingDraft draft,
  }) async {
    final conflicts = <BookingConflict>[];

    // Parallelize initial data lookups for better performance
    final results = await Future.wait([
      clientsRepository.getClient(
        context: context,
        clientId: draft.clientId,
      ),
      providersRepository.getProvider(
        context: context,
        providerId: draft.providerId,
      ),
      servicesRepository.getService(
        context: context,
        serviceId: draft.serviceId,
      ),
      locationsRepository.getLocation(
        context: context,
        locationId: draft.locationId,
      ),
    ]);

    final client = results[0] as Client?;
    final provider = results[1] as Provider?;
    final service = results[2] as Service?;
    final location = results[3] as Location?;

    if (client == null) {
      conflicts.add(
        const BookingConflict(
          BookingConflictType.missingClient,
          'Client no longer exists.',
        ),
      );
    }

    if (provider == null) {
      conflicts.add(
        const BookingConflict(
          BookingConflictType.missingProvider,
          'Provider record missing.',
        ),
      );
    }

    if (service == null) {
      conflicts.add(
        const BookingConflict(
          BookingConflictType.missingService,
          'Service was removed.',
        ),
      );
    }

    if (location == null) {
      conflicts.add(
        const BookingConflict(
          BookingConflictType.missingLocation,
          'Location unavailable.',
        ),
      );
    }

    if (service == null ||
        provider == null ||
        client == null ||
        location == null) {
      return BookingValidationResult(
        isValid: false,
        conflicts: conflicts,
        waitlistAllowed: bookingPolicies.allowWaitlist,
      );
    }

    final now = DateTime.now();
    final duration =
        draft.serviceDurationOverride ??
        Duration(minutes: service.durationMinutes);
    final endTime = draft.startTime.add(duration);
    final notice = draft.startTime.difference(now);
    if (draft.startTime.isBefore(now)) {
      conflicts.add(
        const BookingConflict(
          BookingConflictType.pastDate,
          'Selected time is in the past.',
        ),
      );
    }

    final minNotice = bookingPolicies.minimumBookingNotice;
    if (minNotice != null && notice < minNotice) {
      conflicts.add(
        BookingConflict(
          BookingConflictType.insufficientNotice,
          'Requires at least ${minNotice.inHours}h notice.',
        ),
      );
    }

    final maxAdvance = bookingPolicies.maximumAdvanceBooking;
    if (maxAdvance != null && draft.startTime.isAfter(now.add(maxAdvance))) {
      conflicts.add(
        BookingConflict(
          BookingConflictType.beyondAdvanceWindow,
          'Bookings only allowed ${maxAdvance.inDays} days out.',
        ),
      );
    }

    final slotsAvailable = await availabilityService.isSlotBookable(
      context: context,
      slot: AvailabilitySlot(
        providerId: provider.id,
        locationId: location.id,
        start: draft.startTime,
        end: endTime,
      ),
    );

    if (!slotsAvailable) {
      conflicts.add(
        const BookingConflict(
          BookingConflictType.providerUnavailable,
          'Provider not available for this slot.',
        ),
      );
    }

    final buffer = bookingPolicies.bufferBetweenAppointments;
    final conflictingAppointments = await appointmentsRepository
        .loadAppointmentsInRange(
          context: context,
          start: draft.startTime.subtract(buffer),
          end: endTime.add(buffer),
          providerId: provider.id,
        );

    if (conflictingAppointments.isNotEmpty) {
      conflicts.add(
        BookingConflict(
          BookingConflictType.doubleBooked,
          'Provider already has ${conflictingAppointments.length} appointment(s) near this time.',
        ),
      );
    }

    final clientConflicts = await appointmentsRepository
        .loadAppointmentsInRange(
          context: context,
          start: draft.startTime.subtract(buffer),
          end: endTime.add(buffer),
          clientId: client.id,
        );

    if (clientConflicts.isNotEmpty) {
      conflicts.add(
        const BookingConflict(
          BookingConflictType.bufferViolation,
          'Client already has an appointment within the buffer window.',
        ),
      );
    }

    if (draft.recurrencePattern != null &&
        conflicts.isEmpty) {
      final recurrenceId = draft.appointmentId ?? _uuid.v4();
      final normalizedPattern = draft.recurrencePattern!.copyWith(
        id: recurrenceId,
        createdAt: DateTime.now(),
      );

      final parentAppointment = Appointment(
        id: recurrenceId,
        businessId: context.businessId,
        clientId: client.id,
        providerId: provider.id,
        serviceId: service.id,
        locationId: location.id,
        startTime: draft.startTime,
        endTime: endTime,
        date: DateTime(
          draft.startTime.year,
          draft.startTime.month,
          draft.startTime.day,
        ),
        status: draft.status,
        notes: draft.notes,
        createdAt: DateTime.now(),
        isRecurring: true,
        recurrenceId: recurrenceId,
        recurrencePattern: normalizedPattern,
      );

      final instances = recurrenceService.generateRecurringInstances(
        parentAppointment: parentAppointment,
        pattern: normalizedPattern,
      );

      final recurrenceConflicts = await recurrenceService
          .checkRecurrenceConflicts(
        businessId: context.businessId,
        providerId: provider.id,
        proposedInstances: [parentAppointment, ...instances],
      );

      if (recurrenceConflicts.isNotEmpty) {
        conflicts.add(
          BookingConflict(
            BookingConflictType.recurrenceConflict,
            'Recurring series has ${recurrenceConflicts.length} conflicting appointment(s).',
          ),
        );
      }
    }

    final requiresDeposit = bookingPolicies.allowDeposits;
    final depositAmount = bookingPolicies.depositAmount ??
        (service.price * bookingPolicies.defaultDepositPercentage);

    return BookingValidationResult(
      isValid: conflicts.isEmpty,
      conflicts: conflicts,
      requiresDeposit: requiresDeposit,
      depositAmount: requiresDeposit ? depositAmount : null,
      waitlistAllowed: bookingPolicies.allowWaitlist,
      snapshot: BookingContextSnapshot(
        client: client,
        provider: provider,
        service: service,
        location: location,
        startTime: draft.startTime,
        endTime: endTime,
      ),
    );
  }

  /// Validate that a client can join a group session (capacity + deadlines).
  Future<BookingValidationResult> validateGroupJoin({
    required SecurityContext context,
    required String appointmentId,
    required String clientId,
  }) async {
    final conflicts = <BookingConflict>[];
    final appointment = await appointmentsRepository.getAppointment(
      context: context,
      appointmentId: appointmentId,
    );
    if (appointment == null || !appointment.isGroupSession) {
      conflicts.add(
        const BookingConflict(
          BookingConflictType.invalidGroupSession,
          'This session is no longer available.',
        ),
      );
      return BookingValidationResult(
        isValid: false,
        conflicts: conflicts,
        waitlistAllowed: bookingPolicies.allowWaitlist,
      );
    }

    if (appointment.registrationDeadline != null &&
        appointment.registrationDeadline!.isBefore(DateTime.now())) {
      conflicts.add(
        const BookingConflict(
          BookingConflictType.registrationClosed,
          'Registration is closed for this session.',
        ),
      );
    }

    if (appointment.attendeeIds.contains(clientId)) {
      conflicts.add(
        const BookingConflict(
          BookingConflictType.alreadyJoined,
          'You are already registered.',
        ),
      );
    }

    final remaining = appointment.remainingSeats;
    if (remaining != null && remaining <= 0) {
      conflicts.add(
        const BookingConflict(
          BookingConflictType.capacityReached,
          'This session is at capacity.',
        ),
      );
    }

    return BookingValidationResult(
      isValid: conflicts.isEmpty,
      conflicts: conflicts,
      waitlistAllowed: bookingPolicies.allowWaitlist,
    );
  }

  Future<BookingSubmissionResult> submit({
    required SecurityContext context,
    required BookingDraft draft,
  }) async {
    try {
      final appointmentId = draft.appointmentId ?? _uuid.v4();

      final validation = await validateDraft(context: context, draft: draft);
      if (!validation.isValid || validation.snapshot == null) {
        return BookingSubmissionResult(
          status: BookingSubmissionStatus.validationFailed,
          validationResult: validation,
        );
      }

      final snapshot = validation.snapshot!;
      Payment? depositPayment;
      final requiresDeposit =
          validation.requiresDeposit && validation.depositAmount != null;

      if (requiresDeposit) {
        if (!featureFlags.enablePayments || paymentGateway == null) {
          return BookingSubmissionResult(
            status: BookingSubmissionStatus.error,
            validationResult: validation,
            error: BookingPaymentException(
              'Payments must be enabled and configured before collecting deposits.',
            ),
          );
        }

        depositPayment = await paymentGateway!.collectDeposit(
          snapshot: snapshot,
          context: context,
          amount: validation.depositAmount!,
          appointmentId: appointmentId,
        );
        await paymentRepository.upsertPayment(
          context: context,
          payment: depositPayment,
        );
      }

      final normalizedPattern = draft.recurrencePattern != null
          ? draft.recurrencePattern!.copyWith(
              id: appointmentId,
              createdAt: DateTime.now(),
            )
          : null;

      final appointment = Appointment(
        id: appointmentId,
        businessId: context.businessId,
        clientId: snapshot.client.id,
        providerId: snapshot.provider.id,
        serviceId: snapshot.service.id,
        locationId: snapshot.location.id,
        startTime: snapshot.startTime,
        endTime: snapshot.endTime,
        date: DateTime(
          snapshot.startTime.year,
          snapshot.startTime.month,
          snapshot.startTime.day,
        ),
        status: draft.status,
        notes: draft.notes,
        createdAt: DateTime.now(),
        requiresPayment: depositPayment != null,
        paymentType: depositPayment != null
            ? PaymentType.deposit
            : PaymentType.full,
        paymentAmountCents: depositPayment?.amountCents,
        paymentStatus: depositPayment?.status ?? PaymentStatus.none,
        paymentId: depositPayment?.id,
        refundEligible: bookingPolicies.cancellationWindow.inMinutes > 0,
        refundStatus: depositPayment != null ? PaymentStatus.none : null,
        isRecurring: normalizedPattern != null,
        recurrenceId: normalizedPattern != null ? appointmentId : null,
        recurrencePattern: normalizedPattern,
      );

      if (normalizedPattern != null) {
        await appointmentsRepository.createRecurringAppointment(
          context: context,
          parentAppointment: appointment,
          pattern: normalizedPattern,
        );
      } else {
        await appointmentsRepository.upsertAppointment(
          context: context,
          appointment: appointment,
        );
      }

      // Generate magic link token for customer access
      MagicLinkToken? magicLinkToken;
      if (snapshot.client.email != null && snapshot.client.email!.isNotEmpty) {
        try {
          magicLinkToken = await magicLinkService.generateToken(
            context: context,
            appointmentId: appointment.id,
            clientId: snapshot.client.id,
            clientEmail: snapshot.client.email!,
          );
        } catch (e) {
          // Log error but don't fail the booking
          // Magic link can be regenerated later if needed
        }
      }

      if (featureFlags.enableAutomatedReminders) {
        await automationService.onAppointmentCreated(
          appointmentId: appointment.id,
          clientId: snapshot.client.id,
          clientName: snapshot.client.fullName,
          clientEmail: snapshot.client.email ?? '',
          clientPhone: snapshot.client.phone,
          appointmentDate: snapshot.startTime,
          appointmentTime: AppDateFormatters.time24Hour.format(snapshot.startTime),
          providerName: snapshot.provider.fullName,
          location: snapshot.location.name ?? snapshot.location.address,
          serviceType: snapshot.service.name,
          businessId: context.businessId,
          userId: context.userId,
        );
      }

      return BookingSubmissionResult(
        status: BookingSubmissionStatus.success,
        appointment: appointment,
        validationResult: validation,
        payment: depositPayment,
        magicLinkToken: magicLinkToken,
      );
    } catch (error) {
      return BookingSubmissionResult(
        status: BookingSubmissionStatus.error,
        error: error,
      );
    }
  }
}
