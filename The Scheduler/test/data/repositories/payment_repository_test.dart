import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_scheduler/data/models/payment.dart';
import 'package:the_scheduler/data/models/security_context.dart';
import 'package:the_scheduler/data/repositories/audit_log_repository.dart';
import 'package:the_scheduler/data/repositories/payment_repository.dart';

import '../../helpers/mock_repositories.dart';
import '../../helpers/test_data_factories.dart';

void main() {
  group('Payment Repository', () {
    late MockPaymentRepository repository;
    late SecurityContext adminContext;
    late SecurityContext staffContext;

    setUp(() {
      repository = MockPaymentRepository();
      adminContext = TestData.securityContext(
        role: UserRole.admin,
        businessId: 'test-business',
      );
      staffContext = TestData.securityContext(
        role: UserRole.staff,
        businessId: 'test-business',
      );
    });

    group('CRUD Operations', () {
      test('creates payment', () async {
        final payment = TestData.payment(
          businessId: 'test-business',
          clientId: 'client-1',
          appointmentId: 'appt-1',
          amountCents: 10000,
          status: PaymentStatus.pending,
        );

        await repository.upsertPayment(adminContext, payment);

        expect(repository.count, 1);
      });

      test('updates existing payment', () async {
        final pending = TestData.payment(
          id: 'payment-1',
          businessId: 'test-business',
          clientId: 'client-1',
          amountCents: 10000,
          status: PaymentStatus.pending,
        );

        await repository.upsertPayment(adminContext, pending);

        final completed = pending.copyWith(
          status: PaymentStatus.completed,
          completedAt: DateTime.now(),
        );

        await repository.upsertPayment(adminContext, completed);

        expect(repository.count, 1);
        final stored = await repository.getPayment(adminContext, 'payment-1');
        expect(stored?.status, PaymentStatus.completed);
        expect(stored?.completedAt, isNotNull);
      });

      test('gets payment by ID', () async {
        final payment = TestData.payment(
          id: 'payment-123',
          businessId: 'test-business',
          clientId: 'client-1',
          amountCents: 15000,
        );

        repository.addPayment(payment);

        final result = await repository.getPayment(adminContext, 'payment-123');

        expect(result, isNotNull);
        expect(result?.id, 'payment-123');
        expect(result?.amountCents, 15000);
      });

      test('watches payments for client', () async {
        final payment1 = TestData.payment(
          id: 'payment-1',
          businessId: 'test-business',
          clientId: 'client-1',
          amountCents: 10000,
        );

        final payment2 = TestData.payment(
          id: 'payment-2',
          businessId: 'test-business',
          clientId: 'client-1',
          amountCents: 15000,
        );

        repository.addPayment(payment1);
        repository.addPayment(payment2);

        final stream = repository.watchPaymentsForClient(
          adminContext,
          'client-1',
        );

        await expectLater(
          stream,
          emits(predicate<List<Payment>>((payments) {
            return payments.length == 2 &&
                payments.every((p) => p.clientId == 'client-1');
          })),
        );
      });

      test('watches payments for appointment', () async {
        final payment = TestData.payment(
          businessId: 'test-business',
          clientId: 'client-1',
          appointmentId: 'appt-1',
          amountCents: 10000,
        );

        repository.addPayment(payment);

        final stream = repository.watchPaymentsForAppointment(
          adminContext,
          'appt-1',
        );

        await expectLater(
          stream,
          emits(predicate<List<Payment>>((payments) {
            return payments.length == 1 &&
                payments.first.appointmentId == 'appt-1';
          })),
        );
      });

      test('deletes payment', () async {
        final payment = TestData.payment(
          id: 'payment-1',
          businessId: 'test-business',
          clientId: 'client-1',
        );

        repository.addPayment(payment);
        expect(repository.count, 1);

        await repository.deletePayment(adminContext, 'payment-1');

        expect(repository.count, 0);
      });
    });

    group('Security & Permissions', () {
      test('enforces business isolation', () async {
        final businessAPayment = TestData.payment(
          businessId: 'business-a',
          clientId: 'client-1',
          amountCents: 10000,
        );

        repository.addPayment(businessAPayment);

        final businessBContext = TestData.securityContext(
          role: UserRole.admin,
          businessId: 'business-b',
        );

        final stream = repository.watchPaymentsForClient(
          businessBContext,
          'client-1',
        );

        await expectLater(
          stream,
          emits(predicate<List<Payment>>((payments) => payments.isEmpty)),
        );
      });

      test('staff can manage payments', () async {
        final payment = TestData.payment(
          businessId: 'test-business',
          clientId: 'client-1',
          amountCents: 10000,
        );

        await repository.upsertPayment(staffContext, payment);
        expect(repository.count, 1);
      });

      test('enforces payment access permissions', () async {
        final clientContext = TestData.securityContext(
          role: UserRole.client,
          businessId: 'test-business',
          clientId: 'client-1',
        );

        final payment = TestData.payment(
          businessId: 'test-business',
          clientId: 'client-1',
          amountCents: 10000,
        );

        expect(
          () => repository.upsertPayment(clientContext, payment),
          throwsA(isA<SecurityException>()),
        );
      });
    });

    group('Payment Status Lifecycle', () {
      test('tracks payment from pending to completed', () async {
        final pending = TestData.payment(
          id: 'payment-1',
          businessId: 'test-business',
          clientId: 'client-1',
          amountCents: 10000,
          status: PaymentStatus.pending,
        );

        await repository.upsertPayment(adminContext, pending);

        final completed = pending.copyWith(
          status: PaymentStatus.completed,
          completedAt: DateTime.now(),
        );
        await repository.upsertPayment(adminContext, completed);

        final result = await repository.getPayment(adminContext, 'payment-1');
        expect(result?.status, PaymentStatus.completed);
        expect(result?.completedAt, isNotNull);
      });

      test('handles failed payment', () async {
        final payment = TestData.payment(
          id: 'payment-1',
          businessId: 'test-business',
          clientId: 'client-1',
          amountCents: 10000,
          status: PaymentStatus.pending,
        );

        await repository.upsertPayment(adminContext, payment);

        final failed = payment.copyWith(
          status: PaymentStatus.failed,
          errorMessage: 'Insufficient funds',
        );

        await repository.upsertPayment(adminContext, failed);

        final result = await repository.getPayment(adminContext, 'payment-1');
        expect(result?.status, PaymentStatus.failed);
        expect(result?.errorMessage, 'Insufficient funds');
      });

      test('processes refund', () async {
        final completed = TestData.payment(
          id: 'payment-1',
          businessId: 'test-business',
          clientId: 'client-1',
          amountCents: 10000,
          status: PaymentStatus.completed,
          completedAt: DateTime.now(),
        );

        await repository.upsertPayment(adminContext, completed);

        final refunded = completed.copyWith(
          status: PaymentStatus.refunded,
          refundAmountCents: 10000,
          refundedAt: DateTime.now(),
        );

        await repository.upsertPayment(adminContext, refunded);

        final result = await repository.getPayment(adminContext, 'payment-1');
        expect(result?.status, PaymentStatus.refunded);
        expect(result?.refundAmountCents, 10000);
        expect(result?.refundedAt, isNotNull);
      });

      test('processes partial refund', () async {
        final completed = TestData.payment(
          id: 'payment-1',
          businessId: 'test-business',
          clientId: 'client-1',
          amountCents: 10000,
          status: PaymentStatus.completed,
          completedAt: DateTime.now(),
        );

        await repository.upsertPayment(adminContext, completed);

        final partialRefund = completed.copyWith(
          status: PaymentStatus.partiallyRefunded,
          refundAmountCents: 5000,
          refundedAt: DateTime.now(),
        );

        await repository.upsertPayment(adminContext, partialRefund);

        final result = await repository.getPayment(adminContext, 'payment-1');
        expect(result?.status, PaymentStatus.partiallyRefunded);
        expect(result?.refundAmountCents, 5000);
        expect(result?.netAmountCents, 5000);
      });
    });

    group('Payment Types', () {
      test('processes deposit payment', () async {
        final payment = TestData.payment(
          businessId: 'test-business',
          clientId: 'client-1',
          amountCents: 2500,
          type: PaymentType.deposit,
          status: PaymentStatus.completed,
          completedAt: DateTime.now(),
        );

        await repository.upsertPayment(adminContext, payment);

        final result = await repository.getPayment(adminContext, payment.id);
        expect(result?.type, PaymentType.deposit);
      });

      test('processes full payment', () async {
        final payment = TestData.payment(
          businessId: 'test-business',
          clientId: 'client-1',
          amountCents: 10000,
          type: PaymentType.full,
          status: PaymentStatus.completed,
          completedAt: DateTime.now(),
        );

        await repository.upsertPayment(adminContext, payment);

        final result = await repository.getPayment(adminContext, payment.id);
        expect(result?.type, PaymentType.full);
      });

      test('processes cancellation fee', () async {
        final payment = TestData.payment(
          businessId: 'test-business',
          clientId: 'client-1',
          amountCents: 5000,
          type: PaymentType.cancellationFee,
          status: PaymentStatus.completed,
        );

        await repository.upsertPayment(adminContext, payment);

        final result = await repository.getPayment(adminContext, payment.id);
        expect(result?.type, PaymentType.cancellationFee);
        expect(result?.isFee, true);
      });

      test('processes reschedule fee', () async {
        final payment = TestData.payment(
          businessId: 'test-business',
          clientId: 'client-1',
          amountCents: 2500,
          type: PaymentType.rescheduleFee,
          status: PaymentStatus.completed,
        );

        await repository.upsertPayment(adminContext, payment);

        final result = await repository.getPayment(adminContext, payment.id);
        expect(result?.type, PaymentType.rescheduleFee);
        expect(result?.isFee, true);
      });
    });

    group('Payment Helpers & Calculations', () {
      test('calculates net amount after refund', () {
        final payment = TestData.payment(
          amountCents: 10000,
          refundAmountCents: 3000,
          businessId: 'test-business',
          clientId: 'client-1',
        );

        expect(payment.netAmountCents, 7000);
      });

      test('isCompleted returns true for completed payment', () {
        final completed = TestData.payment(
          status: PaymentStatus.completed,
          businessId: 'test-business',
          clientId: 'client-1',
        );

        expect(completed.isCompleted, isTrue);
      });

      test('isCompleted returns false for pending payment', () {
        final pending = TestData.payment(
          status: PaymentStatus.pending,
          businessId: 'test-business',
          clientId: 'client-1',
        );

        expect(pending.isCompleted, isFalse);
      });

      test('isPending returns true for pending payment', () {
        final pending = TestData.payment(
          status: PaymentStatus.pending,
          businessId: 'test-business',
          clientId: 'client-1',
        );

        expect(pending.isPending, isTrue);
      });

      test('isFailed returns true for failed payment', () {
        final failed = TestData.payment(
          status: PaymentStatus.failed,
          businessId: 'test-business',
          clientId: 'client-1',
        );

        expect(failed.isFailed, isTrue);
      });

      test('isRefunded returns true for refunded payment', () {
        final refunded = TestData.payment(
          status: PaymentStatus.refunded,
          businessId: 'test-business',
          clientId: 'client-1',
        );

        expect(refunded.isRefunded, isTrue);
      });
    });

    group('Real-World Payment Scenarios', () {
      test('dental cleaning with copay', () async {
        final payment = TestData.payment(
          id: 'dental-payment-1',
          businessId: 'test-business',
          clientId: 'patient-1',
          appointmentId: 'cleaning-appt-1',
          amountCents: 2500, // $25 copay
          type: PaymentType.deposit,
          status: PaymentStatus.completed,
          completedAt: DateTime.now(),
        );

        await repository.upsertPayment(adminContext, payment);

        final result =
            await repository.getPayment(adminContext, 'dental-payment-1');
        expect(result?.amountCents, 2500);
        expect(result?.type, PaymentType.deposit);
        expect(result?.status, PaymentStatus.completed);
      });

      test('therapy session payment', () async {
        final payment = TestData.payment(
          id: 'therapy-payment-1',
          businessId: 'test-business',
          clientId: 'client-1',
          appointmentId: 'session-1',
          amountCents: 15000, // $150
          type: PaymentType.full,
          status: PaymentStatus.pending,
        );

        await repository.upsertPayment(adminContext, payment);

        // Later, payment completes
        final processed = payment.copyWith(
          status: PaymentStatus.completed,
          completedAt: DateTime.now(),
        );
        await repository.upsertPayment(adminContext, processed);

        final result =
            await repository.getPayment(adminContext, 'therapy-payment-1');
        expect(result?.status, PaymentStatus.completed);
      });

      test('massage package purchase', () async {
        final payment = TestData.payment(
          id: 'massage-payment-1',
          businessId: 'test-business',
          clientId: 'client-1',
          amountCents: 40000, // $400 for 5-session package
          type: PaymentType.full,
          status: PaymentStatus.completed,
          completedAt: DateTime.now(),
        );

        await repository.upsertPayment(adminContext, payment);

        final result =
            await repository.getPayment(adminContext, 'massage-payment-1');
        expect(result?.amountCents, 40000);
      });

      test('cancelled appointment with full refund', () async {
        final originalPayment = TestData.payment(
          id: 'payment-1',
          businessId: 'test-business',
          clientId: 'client-1',
          appointmentId: 'appt-1',
          amountCents: 10000,
          type: PaymentType.full,
          status: PaymentStatus.completed,
          completedAt: DateTime.now().subtract(const Duration(days: 5)),
        );

        await repository.upsertPayment(adminContext, originalPayment);

        // Client cancels within refund window
        final refunded = originalPayment.copyWith(
          status: PaymentStatus.refunded,
          refundAmountCents: 10000,
          refundedAt: DateTime.now(),
          reason: 'Appointment cancelled by client',
        );

        await repository.upsertPayment(adminContext, refunded);

        final result = await repository.getPayment(adminContext, 'payment-1');
        expect(result?.status, PaymentStatus.refunded);
        expect(result?.refundAmountCents, 10000);
        expect(result?.netAmountCents, 0);
      });

      test('late cancellation with partial refund', () async {
        final originalPayment = TestData.payment(
          id: 'payment-1',
          businessId: 'test-business',
          clientId: 'client-1',
          appointmentId: 'appt-1',
          amountCents: 10000,
          type: PaymentType.full,
          status: PaymentStatus.completed,
          completedAt: DateTime.now().subtract(const Duration(hours: 12)),
        );

        await repository.upsertPayment(adminContext, originalPayment);

        // Client cancels within 24 hours - 50% refund
        final partialRefund = originalPayment.copyWith(
          status: PaymentStatus.partiallyRefunded,
          refundAmountCents: 5000,
          refundedAt: DateTime.now(),
          reason: 'Late cancellation - 50% refund per policy',
        );

        await repository.upsertPayment(adminContext, partialRefund);

        final result = await repository.getPayment(adminContext, 'payment-1');
        expect(result?.status, PaymentStatus.partiallyRefunded);
        expect(result?.refundAmountCents, 5000);
        expect(result?.netAmountCents, 5000);
      });

      test('failed payment retry', () async {
        final failed = TestData.payment(
          id: 'payment-1',
          businessId: 'test-business',
          clientId: 'client-1',
          amountCents: 10000,
          type: PaymentType.full,
          status: PaymentStatus.failed,
          errorMessage: 'Card declined',
        );

        await repository.upsertPayment(adminContext, failed);

        // Create new payment for retry
        final retry = TestData.payment(
          id: 'payment-2',
          businessId: 'test-business',
          clientId: 'client-1',
          appointmentId: failed.appointmentId,
          amountCents: 10000,
          type: PaymentType.full,
          status: PaymentStatus.completed,
          completedAt: DateTime.now(),
        );

        await repository.upsertPayment(adminContext, retry);

        expect(repository.count, 2);
      });
    });

    group('Payment Filtering & Queries', () {
      test('filters payments by client', () async {
        final payment1 = TestData.payment(
          businessId: 'test-business',
          clientId: 'client-1',
          amountCents: 10000,
        );

        final payment2 = TestData.payment(
          businessId: 'test-business',
          clientId: 'client-2',
          amountCents: 15000,
        );

        repository.addPayment(payment1);
        repository.addPayment(payment2);

        final stream = repository.watchPaymentsForClient(
          adminContext,
          'client-1',
        );

        await expectLater(
          stream,
          emits(predicate<List<Payment>>((payments) {
            return payments.length == 1 &&
                payments.first.clientId == 'client-1';
          })),
        );
      });

      test('filters payments by appointment', () async {
        final payment1 = TestData.payment(
          businessId: 'test-business',
          clientId: 'client-1',
          appointmentId: 'appt-1',
          amountCents: 10000,
        );

        final payment2 = TestData.payment(
          businessId: 'test-business',
          clientId: 'client-1',
          appointmentId: 'appt-2',
          amountCents: 15000,
        );

        repository.addPayment(payment1);
        repository.addPayment(payment2);

        final stream = repository.watchPaymentsForAppointment(
          adminContext,
          'appt-1',
        );

        await expectLater(
          stream,
          emits(predicate<List<Payment>>((payments) {
            return payments.length == 1 &&
                payments.first.appointmentId == 'appt-1';
          })),
        );
      });
    });
  });

  group('PaymentRepository Firestore queries', () {
    late FakeFirebaseFirestore firestore;
    late PaymentRepository repository;
    late SecurityContext ownerContext;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      repository = PaymentRepository(
        firestore: firestore,
        auditLogRepository: AuditLogRepository(firestore: firestore),
      );
      ownerContext = SecurityContext(
        userId: 'owner-1',
        businessId: 'biz-fire',
        role: UserRole.owner,
      );
    });

    test('fetchPaymentsForAppointments chunks appointment IDs', () async {
      final payments = List.generate(12, (index) {
        return TestData.payment(
          id: 'fire-pay-$index',
          businessId: ownerContext.businessId,
          clientId: 'client-${index % 3}',
          appointmentId: 'appt-$index',
          amountCents: 5000 + index,
          status: PaymentStatus.completed,
        );
      });

      for (final payment in payments) {
        await repository.upsertPayment(
          context: ownerContext,
          payment: payment,
        );
      }

      final appointmentIds = payments.map((p) => p.appointmentId).toList();
      final results = await repository.fetchPaymentsForAppointments(
        context: ownerContext,
        appointmentIds: appointmentIds,
      );

      expect(results.length, appointmentIds.length);
      expect(
        results.map((p) => p.id).toSet(),
        payments.map((p) => p.id).toSet(),
      );
    });
  });
}
