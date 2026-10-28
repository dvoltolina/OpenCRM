import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:the_scheduler/core/services/analytics_service.dart';
import 'package:the_scheduler/core/services/recurrence_service.dart';
import 'package:the_scheduler/data/models/appointment.dart';
import 'package:the_scheduler/data/models/client.dart';
import 'package:the_scheduler/data/models/payment.dart';
import 'package:the_scheduler/data/models/security_context.dart';
import 'package:the_scheduler/data/models/subscription.dart';
import 'package:the_scheduler/data/repositories/appointments_repository.dart';
import 'package:the_scheduler/data/repositories/audit_log_repository.dart';
import 'package:the_scheduler/data/repositories/clients_repository.dart';
import 'package:the_scheduler/data/repositories/group_attendees_repository.dart';
import 'package:the_scheduler/data/repositories/payment_repository.dart';
import 'package:the_scheduler/data/repositories/subscription_repository.dart';

class FakeAppointmentsRepository extends AppointmentsRepository {
  factory FakeAppointmentsRepository(List<Appointment> appointments) {
    final firestore = FakeFirebaseFirestore();
    final auditLogRepository = AuditLogRepository(firestore: firestore);
    return FakeAppointmentsRepository._(appointments, firestore, auditLogRepository);
  }

  FakeAppointmentsRepository._(
    this.appointments,
    FakeFirebaseFirestore firestore,
    AuditLogRepository auditLogRepository,
  ) : super(
          firestore: firestore,
          recurrenceService: RecurrenceService(firestore: firestore),
          groupAttendeesRepository: GroupAttendeesRepository(
            firestore: firestore,
            auditLogRepository: auditLogRepository,
          ),
          auditLogRepository: auditLogRepository,
        );

  final List<Appointment> appointments;

  @override
  Future<List<Appointment>> loadAppointmentsInRange({
    required SecurityContext context,
    required DateTime start,
    required DateTime end,
    String? providerId,
    String? clientId,
    String? locationId,
  }) async {
    return appointments;
  }
}

class FakeClientsRepository extends ClientsRepository {
  FakeClientsRepository(this.clients)
      : super(
          firestore: FakeFirebaseFirestore(),
          auditLogRepository: AuditLogRepository(firestore: FakeFirebaseFirestore()),
        );

  final List<Client> clients;

  @override
  Future<List<Client>> getClients(
    SecurityContext context, {
    int limit = 100,
    String? startAfterId,
    bool allowSalesRead = false,
  }) async => clients;
}

class FakePaymentRepository extends PaymentRepository {
  FakePaymentRepository(this.payments)
      : super(
          firestore: FakeFirebaseFirestore(),
          auditLogRepository: AuditLogRepository(firestore: FakeFirebaseFirestore()),
        );

  final List<Payment> payments;

  @override
  Future<List<Payment>> fetchPayments(
    SecurityContext context, {
    String? appointmentId,
    String? clientId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return payments;
  }

  @override
  Future<List<Payment>> getPaymentsByAppointmentIds({
    required SecurityContext context,
    required List<String> appointmentIds,
  }) async {
    return payments
        .where((p) => appointmentIds.contains(p.appointmentId))
        .toList();
  }
}

class FakeSubscriptionRepository implements SubscriptionRepository {
  const FakeSubscriptionRepository({this.subscription});

  final Subscription? subscription;

  @override
  Future<void> cancelSubscription(
    SecurityContext context,
    String subscriptionId,
  ) async {}

  @override
  Future<Subscription?> getSubscription(SecurityContext context) async =>
      subscription;

  @override
  Future<Map<String, int>> getUsageStats(SecurityContext context) async =>
      {};

  @override
  Future<void> reactivateSubscription(
    SecurityContext context,
    String subscriptionId,
  ) async {}

  @override
  Future<void> updateSubscriptionStatus(
    SecurityContext context,
    String subscriptionId,
    SubscriptionStatus status,
  ) async {}

  @override
  Future<void> upsertSubscription(
    SecurityContext context,
    Subscription subscription,
  ) async {}

  @override
  Stream<Subscription?> watchSubscription(SecurityContext context) =>
      const Stream.empty();
}

void main() {
  const businessId = 'biz-1';
  final context = SecurityContext(
    userId: 'user-1',
    businessId: businessId,
    role: UserRole.owner,
  );

  group('AnalyticsService', () {
    test('uses payment data for revenue and provider/service breakdowns', () async {
      final startDate = DateTime(2024, 1, 1);
      final endDate = DateTime(2024, 1, 31);

      final appointments = [
        Appointment(
          id: 'a1',
          businessId: businessId,
          clientId: 'client-1',
          providerId: 'provider-1',
          serviceId: 'service-1',
          locationId: 'loc-1',
          startTime: DateTime(2024, 1, 10, 9),
          endTime: DateTime(2024, 1, 10, 10),
          date: DateTime(2024, 1, 10),
          status: AppointmentStatus.completed,
          createdAt: DateTime(2023, 12, 31),
        ),
        Appointment(
          id: 'a2',
          businessId: businessId,
          clientId: 'client-2',
          providerId: 'provider-2',
          serviceId: 'service-2',
          locationId: 'loc-1',
          startTime: DateTime(2024, 1, 11, 11),
          endTime: DateTime(2024, 1, 11, 12),
          date: DateTime(2024, 1, 11),
          status: AppointmentStatus.confirmed,
          createdAt: DateTime(2024, 1, 5),
        ),
      ];

      final payments = [
        Payment(
          id: 'pay-1',
          businessId: businessId,
          appointmentId: 'a1',
          clientId: 'client-1',
          amountCents: 1000,
          status: PaymentStatus.completed,
          type: PaymentType.full,
          createdAt: DateTime(2024, 1, 10),
        ),
        Payment(
          id: 'pay-2',
          businessId: businessId,
          appointmentId: 'a1',
          clientId: 'client-1',
          amountCents: 500,
          status: PaymentStatus.pending,
          type: PaymentType.deposit,
          createdAt: DateTime(2024, 1, 10),
        ),
        Payment(
          id: 'pay-3',
          businessId: businessId,
          appointmentId: 'a2',
          clientId: 'client-2',
          amountCents: 800,
          status: PaymentStatus.partiallyRefunded,
          refundAmountCents: 300,
          type: PaymentType.full,
          createdAt: DateTime(2024, 1, 11),
        ),
        Payment(
          id: 'pay-4',
          businessId: businessId,
          appointmentId: 'a2',
          clientId: 'client-2',
          amountCents: 200,
          status: PaymentStatus.completed,
          type: PaymentType.refund,
          createdAt: DateTime(2024, 1, 11),
        ),
        // Irrelevant payment should be ignored by appointment filter
        Payment(
          id: 'pay-noop',
          businessId: businessId,
          appointmentId: 'other',
          clientId: 'client-3',
          amountCents: 9999,
          status: PaymentStatus.completed,
          type: PaymentType.full,
          createdAt: DateTime(2024, 1, 12),
        ),
      ];

      final clients = [
        Client(
          id: 'client-1',
          businessId: businessId,
          firstName: 'Ana',
          lastName: 'A',
          createdAt: DateTime(2023, 12, 1),
        ),
        Client(
          id: 'client-2',
          businessId: businessId,
          firstName: 'Ben',
          lastName: 'B',
          createdAt: DateTime(2023, 12, 1),
        ),
      ];

      final service = AnalyticsService(
        appointmentsRepository: FakeAppointmentsRepository(appointments),
        clientsRepository: FakeClientsRepository(clients),
        paymentRepository: FakePaymentRepository(payments),
        subscriptionRepository: const FakeSubscriptionRepository(),
      );

      final metrics = await service.computeMetrics(
        context: context,
        startDate: startDate,
        endDate: endDate,
      );

      expect(metrics.totalRevenueCents, 1800);
      expect(metrics.paidRevenueCents, 1800);
      expect(metrics.pendingRevenueCents, 500);
      expect(metrics.refundedRevenueCents, 500);
      expect(metrics.revenueByProvider['provider-1'], 1500);
      expect(metrics.revenueByProvider['provider-2'], 300);
      expect(metrics.revenueByService['service-1'], 1500);
      expect(metrics.revenueByService['service-2'], 300);
    });

    test('counts group session attendance in breakdowns and returning clients', () async {
      final startDate = DateTime(2024, 1, 1);
      final endDate = DateTime(2024, 1, 31);

      final appointments = [
        Appointment(
          id: 'g1',
          businessId: businessId,
          clientId: 'host-client',
          providerId: 'provider-1',
          serviceId: 'service-1',
          locationId: 'loc-1',
          startTime: DateTime(2024, 1, 5, 10),
          endTime: DateTime(2024, 1, 5, 11),
          date: DateTime(2024, 1, 5),
          status: AppointmentStatus.confirmed,
          createdAt: DateTime(2024, 1, 3),
          isGroupSession: true,
          capacity: 6,
          attendeeIds: const ['client-1', 'client-2', 'client-3'],
        ),
        Appointment(
          id: 's1',
          businessId: businessId,
          clientId: 'client-1',
          providerId: 'provider-1',
          serviceId: 'service-1',
          locationId: 'loc-1',
          startTime: DateTime(2024, 1, 6, 12),
          endTime: DateTime(2024, 1, 6, 13),
          date: DateTime(2024, 1, 6),
          status: AppointmentStatus.completed,
          createdAt: DateTime(2024, 1, 4),
        ),
      ];

      final clients = [
        Client(
          id: 'client-1',
          businessId: businessId,
          firstName: 'Alex',
          lastName: 'One',
          createdAt: DateTime(2024, 1, 2),
        ),
        Client(
          id: 'client-2',
          businessId: businessId,
          firstName: 'Blair',
          lastName: 'Two',
          createdAt: DateTime(2024, 1, 2),
        ),
        Client(
          id: 'client-3',
          businessId: businessId,
          firstName: 'Casey',
          lastName: 'Three',
          createdAt: DateTime(2024, 1, 7),
        ),
        Client(
          id: 'client-4',
          businessId: businessId,
          firstName: 'Dana',
          lastName: 'Four',
          createdAt: DateTime(2024, 1, 1),
        ),
      ];

      final service = AnalyticsService(
        appointmentsRepository: FakeAppointmentsRepository(appointments),
        clientsRepository: FakeClientsRepository(clients),
        paymentRepository: FakePaymentRepository(const []),
        subscriptionRepository: const FakeSubscriptionRepository(),
      );

      final metrics = await service.computeMetrics(
        context: context,
        startDate: startDate,
        endDate: endDate,
      );

      expect(metrics.appointmentsByProvider['provider-1'], 5);
      expect(metrics.appointmentsByService['service-1'], 5);
      expect(metrics.appointmentsByHourOfDay[10], 4);
      expect(metrics.appointmentsByHourOfDay[12], 1);
      expect(metrics.appointmentsByDate['2024-01-05'], 4);
      expect(metrics.appointmentsByDate['2024-01-06'], 1);
      expect(metrics.returningClients, 1); // client-1 attended twice
    });
  });
}
