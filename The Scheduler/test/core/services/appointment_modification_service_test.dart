import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_scheduler/core/config/app_config.dart';
import 'package:the_scheduler/core/config/feature_flags.dart';
import 'package:the_scheduler/core/config/communication_config.dart';
import 'package:the_scheduler/core/services/appointment_modification_service.dart';
import 'package:the_scheduler/core/services/automation_service.dart';
import 'package:the_scheduler/core/services/availability_service.dart';
import 'package:the_scheduler/core/services/booking_context_snapshot.dart';
import 'package:the_scheduler/core/services/booking_payment_gateway.dart';
import 'package:the_scheduler/core/services/email_service.dart';
import 'package:the_scheduler/core/services/recurrence_service.dart';
import 'package:the_scheduler/core/services/sms_service.dart';
import 'package:the_scheduler/data/models/appointment.dart';
import 'package:the_scheduler/data/models/modification_request.dart';
import 'package:the_scheduler/data/models/payment.dart';
import 'package:the_scheduler/data/models/security_context.dart';
import 'package:the_scheduler/data/repositories/appointments_repository.dart';
import 'package:the_scheduler/data/repositories/audit_log_repository.dart';
import 'package:the_scheduler/data/repositories/clients_repository.dart';
import 'package:the_scheduler/data/repositories/communication_repository.dart';
import 'package:the_scheduler/data/repositories/group_attendees_repository.dart';
import 'package:the_scheduler/data/repositories/locations_repository.dart';
import 'package:the_scheduler/data/repositories/modification_requests_repository.dart';
import 'package:the_scheduler/data/repositories/payment_repository.dart';
import 'package:the_scheduler/data/repositories/providers_repository.dart';
import 'package:the_scheduler/data/repositories/services_repository.dart';

import '../../helpers/test_data_factories.dart';
import '../../helpers/mock_repositories.dart';

void main() {
  group('AppointmentModificationService', () {
    late FakeFirebaseFirestore firestore;
    late AppointmentsRepository appointmentsRepository;
    late ClientsRepository clientsRepository;
    late ProvidersRepository providersRepository;
    late ServicesRepository servicesRepository;
    late LocationsRepository locationsRepository;
    late PaymentRepository paymentRepository;
    late InMemoryModificationRequestsRepository modificationRequestsRepository;
    late RecordingAvailabilityService availabilityService;
    late RecordingAutomationService automationService;

    final adminContext = TestData.securityContext(role: UserRole.admin);
    final clientContext = TestData.securityContext(
      role: UserRole.client,
      clientId: 'client-1',
    );

    setUp(() async {
      firestore = FakeFirebaseFirestore();
      appointmentsRepository = AppointmentsRepository(
        firestore: firestore,
        recurrenceService: RecurrenceService(firestore: firestore),
        groupAttendeesRepository: GroupAttendeesRepository(
          firestore: firestore,
          auditLogRepository: AuditLogRepository(firestore: firestore),
        ),
        auditLogRepository: MockAuditLogRepository(),
      );
      clientsRepository = ClientsRepository(
        firestore: firestore,
        auditLogRepository: MockAuditLogRepository(),
      );
      providersRepository = ProvidersRepository(
        firestore: firestore,
        auditLogRepository: MockAuditLogRepository(),
      );
      servicesRepository = ServicesRepository(firestore: firestore);
      locationsRepository = LocationsRepository(firestore: firestore);
      paymentRepository = PaymentRepository(
        firestore: firestore,
        auditLogRepository: MockAuditLogRepository(),
      );
      modificationRequestsRepository =
          InMemoryModificationRequestsRepository();
      availabilityService = RecordingAvailabilityService(isBookable: true);
      automationService = RecordingAutomationService();

      await clientsRepository.upsertClient(
        context: adminContext,
        client: TestData.client(id: clientContext.clientId),
      );
      await providersRepository.upsertProvider(
        context: adminContext,
        provider: TestData.provider(),
      );
      await servicesRepository.upsertService(
        context: adminContext,
        service: TestData.service(),
      );
      await locationsRepository.upsertLocation(
        context: adminContext,
        location: TestData.location(),
      );
    });

    test('requires approval when rescheduling inside notice window', () async {
      final startTime = DateTime.now().add(const Duration(hours: 2));
      final appointment = TestData.appointment(
        id: 'appt-approval',
        clientId: clientContext.clientId!,
        startTime: startTime,
        endTime: startTime.add(const Duration(hours: 1)),
      );

      await appointmentsRepository.upsertAppointment(
        context: adminContext,
        appointment: appointment,
      );

      final service = AppointmentModificationService(
        bookingPolicies: const BookingPolicies(
          defaultSlotLength: Duration(minutes: 30),
          bufferBetweenAppointments: Duration(minutes: 5),
          cancellationWindow: Duration(hours: 24),
          requireManualApprovalInsideWindow: true,
        ),
        featureFlags: const FeatureFlags(enablePayments: false),
        appointmentsRepository: appointmentsRepository,
        clientsRepository: clientsRepository,
        providersRepository: providersRepository,
        servicesRepository: servicesRepository,
        locationsRepository: locationsRepository,
        availabilityService: availabilityService,
        automationService: automationService,
        modificationRequestsRepository: modificationRequestsRepository,
        paymentRepository: paymentRepository,
      );

      final newStart = startTime.add(const Duration(hours: 1));
      final result = await service.rescheduleAppointment(
        context: clientContext,
        appointmentId: appointment.id,
        newStartTime: newStart,
        reason: 'Need later time',
      );

      expect(result.status, AppointmentModificationStatus.requiresApproval);
      expect(result.request, isNotNull);
      expect(result.request?.policyWindowBreached, isTrue);
      expect(result.request?.requestedStartTime, newStart);
      expect(modificationRequestsRepository.savedRequests.length, 1);
      expect(
        modificationRequestsRepository.savedRequests.first.type,
        ModificationRequestType.reschedule,
      );
      expect(automationService.rescheduledEvents, isEmpty);
    });

    test('cancels outside window, issues refund, and releases slot', () async {
      final startTime = DateTime.now().add(const Duration(days: 3));
      final appointment = TestData.appointment(
        id: 'appt-cancel',
        clientId: clientContext.clientId!,
        startTime: startTime,
        endTime: startTime.add(const Duration(hours: 1)),
      ).copyWith(
        paymentId: 'pay-1',
        paymentStatus: PaymentStatus.completed,
        paymentAmountCents: 5000,
      );

      await appointmentsRepository.upsertAppointment(
        context: adminContext,
        appointment: appointment,
      );

      await paymentRepository.upsertPayment(
        context: clientContext,
        payment: TestData.payment(
          id: 'pay-1',
          appointmentId: appointment.id,
          clientId: appointment.clientId,
          amountCents: 5000,
        ),
      );

      var slotReleased = false;
      final service = AppointmentModificationService(
        bookingPolicies: const BookingPolicies(
          defaultSlotLength: Duration(minutes: 30),
          bufferBetweenAppointments: Duration(minutes: 5),
          cancellationWindow: Duration(hours: 24),
        ),
        featureFlags: const FeatureFlags(enablePayments: true),
        appointmentsRepository: appointmentsRepository,
        clientsRepository: clientsRepository,
        providersRepository: providersRepository,
        servicesRepository: servicesRepository,
        locationsRepository: locationsRepository,
        availabilityService: availabilityService,
        automationService: automationService,
        modificationRequestsRepository: modificationRequestsRepository,
        paymentGateway: FakePaymentGateway(),
        paymentRepository: paymentRepository,
        onSlotReleased: (_) async {
          slotReleased = true;
        },
      );

      final result = await service.cancelAppointment(
        context: clientContext,
        appointmentId: appointment.id,
        reason: 'Out of town',
      );

      expect(result.status, AppointmentModificationStatus.success);
      expect(result.payment, isNotNull);
      expect(result.payment?.type, PaymentType.refund);
      expect(slotReleased, isTrue);
      expect(automationService.cancelledEvents.length, 1);
      expect(
        modificationRequestsRepository.savedRequests
            .where((r) => r.type == ModificationRequestType.cancel)
            .length,
        1,
      );

      final cancelledDoc = await firestore
          .collection('businesses')
          .doc(clientContext.businessId)
          .collection('appointments')
          .doc(appointment.id)
          .get();
      expect(cancelledDoc.data()?['status'], AppointmentStatus.cancelled.name);

      final refundRecords = await paymentRepository.fetchPayments(
        clientContext,
        appointmentId: appointment.id,
      );
      expect(
        refundRecords.any((p) => p.type == PaymentType.refund),
        isTrue,
      );
    });

    test('reschedules outside protected window and notifies automation',
        () async {
      final startTime = DateTime.now().add(const Duration(days: 5));
      final appointment = TestData.appointment(
        id: 'appt-reschedule',
        clientId: clientContext.clientId!,
        startTime: startTime,
        endTime: startTime.add(const Duration(hours: 1)),
      );

      await appointmentsRepository.upsertAppointment(
        context: adminContext,
        appointment: appointment,
      );

      final service = AppointmentModificationService(
        bookingPolicies: const BookingPolicies(
          defaultSlotLength: Duration(minutes: 30),
          bufferBetweenAppointments: Duration(minutes: 5),
          cancellationWindow: Duration(hours: 24),
          requireManualApprovalInsideWindow: true,
        ),
        featureFlags: const FeatureFlags(enablePayments: false),
        appointmentsRepository: appointmentsRepository,
        clientsRepository: clientsRepository,
        providersRepository: providersRepository,
        servicesRepository: servicesRepository,
        locationsRepository: locationsRepository,
        availabilityService: availabilityService,
        automationService: automationService,
        modificationRequestsRepository: modificationRequestsRepository,
        paymentRepository: paymentRepository,
      );

      final newStart = startTime.add(const Duration(days: 1));
      final result = await service.rescheduleAppointment(
        context: clientContext,
        appointmentId: appointment.id,
        newStartTime: newStart,
        reason: 'Need later date',
      );

      expect(result.status, AppointmentModificationStatus.success);
      expect(result.updatedAppointment?.startTime, newStart);
      expect(automationService.rescheduledEvents, contains(appointment.id));
      final stored = await appointmentsRepository.getAppointment(
        context: adminContext,
        appointmentId: appointment.id,
      );
      expect(stored?.startTime, newStart);
      expect(
        modificationRequestsRepository.savedRequests.length,
        1,
      );
      expect(
        modificationRequestsRepository.savedRequests.single.status,
        ModificationRequestStatus.autoApproved,
      );
    });

    test('cancel inside policy window routes to manual approval', () async {
      final startTime = DateTime.now().add(const Duration(hours: 2));
      final appointment = TestData.appointment(
        id: 'appt-manual',
        clientId: clientContext.clientId!,
        startTime: startTime,
        endTime: startTime.add(const Duration(hours: 1)),
      );

      await appointmentsRepository.upsertAppointment(
        context: adminContext,
        appointment: appointment,
      );

      var slotReleased = false;
      final service = AppointmentModificationService(
        bookingPolicies: const BookingPolicies(
          defaultSlotLength: Duration(minutes: 30),
          bufferBetweenAppointments: Duration(minutes: 5),
          cancellationWindow: Duration(hours: 24),
          requireManualApprovalInsideWindow: true,
        ),
        featureFlags: const FeatureFlags(enablePayments: false),
        appointmentsRepository: appointmentsRepository,
        clientsRepository: clientsRepository,
        providersRepository: providersRepository,
        servicesRepository: servicesRepository,
        locationsRepository: locationsRepository,
        availabilityService: availabilityService,
        automationService: automationService,
        modificationRequestsRepository: modificationRequestsRepository,
        paymentRepository: paymentRepository,
        onSlotReleased: (_) async {
          slotReleased = true;
        },
      );

      final result = await service.cancelAppointment(
        context: clientContext,
        appointmentId: appointment.id,
        reason: 'Emergency',
      );

      expect(result.status, AppointmentModificationStatus.requiresApproval);
      expect(result.request, isNotNull);
      expect(modificationRequestsRepository.savedRequests.length, 1);
      expect(slotReleased, isFalse);
    });

    test('collects reschedule fee when inside window without manual approval',
        () async {
      final startTime = DateTime.now().add(const Duration(hours: 3));
      final appointment = TestData.appointment(
        id: 'appt-fee',
        clientId: clientContext.clientId!,
        startTime: startTime,
        endTime: startTime.add(const Duration(hours: 1)),
      );

      await appointmentsRepository.upsertAppointment(
        context: adminContext,
        appointment: appointment,
      );

      final service = AppointmentModificationService(
        bookingPolicies: const BookingPolicies(
          defaultSlotLength: Duration(minutes: 30),
          bufferBetweenAppointments: Duration(minutes: 5),
          cancellationWindow: Duration(hours: 24),
          requireManualApprovalInsideWindow: false,
          rescheduleFeeAmount: 20.0,
        ),
        featureFlags: const FeatureFlags(enablePayments: true),
        appointmentsRepository: appointmentsRepository,
        clientsRepository: clientsRepository,
        providersRepository: providersRepository,
        servicesRepository: servicesRepository,
        locationsRepository: locationsRepository,
        availabilityService: availabilityService,
        automationService: automationService,
        modificationRequestsRepository: modificationRequestsRepository,
        paymentGateway: FakePaymentGateway(),
        paymentRepository: paymentRepository,
      );

      final newStart = startTime.add(const Duration(hours: 2));
      final result = await service.rescheduleAppointment(
        context: clientContext,
        appointmentId: appointment.id,
        newStartTime: newStart,
        reason: 'Need later slot',
      );

      expect(result.status, AppointmentModificationStatus.success);
      expect(result.payment, isNotNull);
      expect(result.payment?.type, PaymentType.rescheduleFee);
      expect(result.payment?.amountCents, 2000);

      final updated = await appointmentsRepository.getAppointment(
        context: adminContext,
        appointmentId: appointment.id,
      );
      expect(updated?.rescheduleFeeStatus, PaymentStatus.completed);
      expect(updated?.reschedulePaymentId, result.payment?.id);
    });

    test('collects cancellation fee when inside window without manual approval',
        () async {
      final startTime = DateTime.now().add(const Duration(hours: 5));
      final appointment = TestData.appointment(
        id: 'appt-cancel-fee',
        clientId: clientContext.clientId!,
        startTime: startTime,
        endTime: startTime.add(const Duration(hours: 1)),
      );

      await appointmentsRepository.upsertAppointment(
        context: adminContext,
        appointment: appointment,
      );

      var slotReleased = false;
      final service = AppointmentModificationService(
        bookingPolicies: const BookingPolicies(
          defaultSlotLength: Duration(minutes: 30),
          bufferBetweenAppointments: Duration(minutes: 5),
          cancellationWindow: Duration(hours: 24),
          cancellationFeeAmount: 35.0,
          requireManualApprovalInsideWindow: false,
        ),
        featureFlags: const FeatureFlags(enablePayments: true),
        appointmentsRepository: appointmentsRepository,
        clientsRepository: clientsRepository,
        providersRepository: providersRepository,
        servicesRepository: servicesRepository,
        locationsRepository: locationsRepository,
        availabilityService: availabilityService,
        automationService: automationService,
        modificationRequestsRepository: modificationRequestsRepository,
        paymentGateway: FakePaymentGateway(),
        paymentRepository: paymentRepository,
        onSlotReleased: (_) async {
          slotReleased = true;
        },
      );

      final result = await service.cancelAppointment(
        context: clientContext,
        appointmentId: appointment.id,
        reason: 'Late change',
      );

      expect(result.status, AppointmentModificationStatus.success);
      expect(result.payment, isNotNull);
      expect(result.payment?.type, PaymentType.cancellationFee);
      expect(result.payment?.amountCents, 3500);
      expect(slotReleased, isTrue);

      final cancelledDoc = await firestore
          .collection('businesses')
          .doc(clientContext.businessId)
          .collection('appointments')
          .doc(appointment.id)
          .get();

      expect(cancelledDoc.data()?['cancellationFeeStatus'],
          PaymentStatus.completed.name);
    });
  });
}

class RecordingAvailabilityService implements AvailabilityService {
  RecordingAvailabilityService({required this.isBookable});

  bool isBookable;

  @override
  Future<List<AvailabilitySlot>> generateSlots({
    required SecurityContext context,
    required AvailabilityQuery query,
  }) async {
    return const [];
  }

  @override
  Future<bool> isSlotBookable({
    required SecurityContext context,
    required AvailabilitySlot slot,
  }) async {
    return isBookable;
  }

  @override
  Stream<List<AvailabilitySlot>> watchSlots({
    required SecurityContext context,
    required AvailabilityQuery query,
  }) {
    return const Stream.empty();
  }
}

class RecordingAutomationService extends AutomationService {
  RecordingAutomationService()
      : super(
          emailService: MockEmailService(),
          smsService: MockSmsService(),
          communicationRepository: InMemoryCommunicationRepository(
            CommunicationConfig.defaultClinic(),
          ),
          communicationConfig: CommunicationConfig.defaultClinic(),
        );

  final List<String> rescheduledEvents = [];
  final List<String> cancelledEvents = [];

  @override
  Future<void> onAppointmentRescheduled({
    required String appointmentId,
    required String clientId,
    required String clientName,
    required String clientEmail,
    required String? clientPhone,
    required DateTime oldDate,
    required DateTime newDate,
    required String newTime,
    required String providerName,
    required String location,
    String? businessId,
    String? userId,
    Map<String, String>? additionalVariables,
  }) async {
    rescheduledEvents.add(appointmentId);
  }

  @override
  Future<void> onAppointmentCancelled({
    required String appointmentId,
    required String clientId,
    required String clientName,
    required String clientEmail,
    required String? clientPhone,
    required DateTime appointmentDate,
    required String appointmentTime,
    required String providerName,
    String? cancellationReason,
    String? businessId,
    String? userId,
    Map<String, String>? additionalVariables,
  }) async {
    cancelledEvents.add(appointmentId);
  }
}

class FakePaymentGateway implements BookingPaymentGateway {
  @override
  Future<Payment> collectDeposit({
    required BookingContextSnapshot snapshot,
    required SecurityContext context,
    required double amount,
    required String appointmentId,
    PaymentType paymentType = PaymentType.deposit,
  }) async {
    return Payment(
      id: 'pay-${DateTime.now().millisecondsSinceEpoch}',
      businessId: context.businessId,
      appointmentId: appointmentId,
      clientId: snapshot.client.id,
      amountCents: (amount * 100).round(),
      currency: 'USD',
      status: PaymentStatus.completed,
      type: paymentType,
      createdAt: DateTime.now(),
      completedAt: DateTime.now(),
    );
  }

  @override
  Future<Payment> chargeRescheduleFee({
    required BookingContextSnapshot snapshot,
    required SecurityContext context,
    required double feeAmount,
    required String appointmentId,
    String? attendeeId,
  }) async {
    return Payment(
      id: 'pay-reschedule-${DateTime.now().millisecondsSinceEpoch}',
      businessId: context.businessId,
      appointmentId: appointmentId,
      clientId: attendeeId ?? snapshot.client.id,
      amountCents: (feeAmount * 100).round(),
      currency: 'USD',
      status: PaymentStatus.completed,
      type: PaymentType.rescheduleFee,
      createdAt: DateTime.now(),
      completedAt: DateTime.now(),
    );
  }

  @override
  Future<Payment> chargeCancellationFee({
    required BookingContextSnapshot snapshot,
    required SecurityContext context,
    required double feeAmount,
    required String appointmentId,
    String? attendeeId,
  }) async {
    return Payment(
      id: 'pay-cancellation-${DateTime.now().millisecondsSinceEpoch}',
      businessId: context.businessId,
      appointmentId: appointmentId,
      clientId: attendeeId ?? snapshot.client.id,
      amountCents: (feeAmount * 100).round(),
      currency: 'USD',
      status: PaymentStatus.completed,
      type: PaymentType.cancellationFee,
      createdAt: DateTime.now(),
      completedAt: DateTime.now(),
    );
  }

  @override
  int calculateRefundAmount({
    required int originalAmountCents,
    required DateTime appointmentStartTime,
    required Duration cancellationWindow,
    DateTime? cancelledAt,
  }) {
    final now = cancelledAt ?? DateTime.now();
    final timeUntilAppointment = appointmentStartTime.difference(now);
    // If cancelled before the cancellation window, full refund
    if (timeUntilAppointment > cancellationWindow) {
      return originalAmountCents;
    }
    // Otherwise, no refund (for simplicity in tests)
    return 0;
  }
}

class InMemoryModificationRequestsRepository
    extends ModificationRequestsRepository {
  InMemoryModificationRequestsRepository()
      : super(firestore: FakeFirebaseFirestore());

  final List<ModificationRequest> savedRequests = [];

  @override
  Future<void> saveRequest({
    required SecurityContext context,
    required ModificationRequest request,
  }) async {
    savedRequests.removeWhere((existing) => existing.id == request.id);
    savedRequests.add(request);
  }
}
