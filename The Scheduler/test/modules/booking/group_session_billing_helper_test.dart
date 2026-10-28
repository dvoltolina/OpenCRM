import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_scheduler/data/models/appointment.dart';
import 'package:the_scheduler/data/models/group_attendee.dart';
import 'package:the_scheduler/data/models/payment.dart';
import 'package:the_scheduler/data/models/security_context.dart';
import 'package:the_scheduler/data/repositories/audit_log_repository.dart';
import 'package:the_scheduler/data/repositories/group_attendees_repository.dart';
import 'package:the_scheduler/data/repositories/payment_repository.dart';
import 'package:the_scheduler/modules/booking/presentation/utils/group_session_billing.dart';

import '../../helpers/test_data_factories.dart';

void main() {
  group('GroupSessionBillingHelper', () {
    late FakeFirebaseFirestore firestore;
    late PaymentRepository paymentRepository;
    late GroupAttendeesRepository attendeesRepository;
    late GroupSessionBillingHelper helper;
    late SecurityContext adminContext;
    late Appointment session;
    late GroupAttendee attendee;

    setUp(() async {
      firestore = FakeFirebaseFirestore();
      final auditLog = AuditLogRepository(firestore: firestore);
      paymentRepository = PaymentRepository(
        firestore: firestore,
        auditLogRepository: auditLog,
      );
      attendeesRepository = GroupAttendeesRepository(
        firestore: firestore,
        auditLogRepository: auditLog,
      );
      helper = GroupSessionBillingHelper(
        paymentRepository: paymentRepository,
        attendeesRepository: attendeesRepository,
        currency: 'EUR',
      );
      adminContext = TestData.securityContext(role: UserRole.admin);
      session = TestData.appointment(
        id: 'group-1',
        businessId: adminContext.businessId,
      ).copyWith(isGroupSession: true);
      attendee = GroupAttendee(
        id: 'attendee-1',
        clientId: 'client-1',
        displayName: 'Alex',
      );

      await attendeesRepository.upsertAttendee(
        context: adminContext,
        appointmentId: session.id,
        attendee: attendee,
      );
    });

    test('markPaid stores ledger payment and updates attendee status', () async {
      await helper.markPaid(
        actorContext: adminContext,
        appointment: session,
        attendee: attendee,
        amountCents: 4500,
      );

      final payments = await paymentRepository.fetchPayments(
        adminContext,
        appointmentId: session.id,
      );
      expect(payments.length, 1);
      expect(payments.first.currency, 'EUR');
      expect(payments.first.amountCents, 4500);
      expect(payments.first.paymentMethodDescription, isNotEmpty);

      final storedAttendee = await attendeesRepository.getAttendee(
        context: adminContext,
        appointmentId: session.id,
        attendeeId: attendee.id,
      );

      expect(storedAttendee?.paymentStatus, PaymentStatus.completed);
      expect(storedAttendee?.refundStatus, PaymentStatus.none);
      expect(storedAttendee?.paymentId, payments.first.id);
    });

    test('markRefunded records refund and syncs attendee refund status',
        () async {
      await helper.markPaid(
        actorContext: adminContext,
        appointment: session,
        attendee: attendee,
        amountCents: 6000,
      );

      final paidAttendee = await attendeesRepository.getAttendee(
        context: adminContext,
        appointmentId: session.id,
        attendeeId: attendee.id,
      );
      expect(paidAttendee?.paymentId, isNotNull);

      await helper.markRefunded(
        actorContext: adminContext,
        appointment: session,
        attendee: paidAttendee!,
        refundAmountCents: 2000,
      );

      final paymentsSnapshot = await firestore
          .collection('businesses')
          .doc(adminContext.businessId)
          .collection('payments')
          .get();

      final refundDoc = paymentsSnapshot.docs
          .firstWhere((doc) => doc.data()['type'] == PaymentType.refund.name);
      final sourceDoc = paymentsSnapshot.docs
          .firstWhere((doc) => doc.id == paidAttendee.paymentId);

      expect(refundDoc.data()['amountCents'], 2000);
      expect(
        sourceDoc.data()['status'],
        PaymentStatus.partiallyRefunded.name,
      );
      expect(sourceDoc.data()['refundAmountCents'], 2000);

      final refundedAttendee = await attendeesRepository.getAttendee(
        context: adminContext,
        appointmentId: session.id,
        attendeeId: attendee.id,
      );
      expect(refundedAttendee?.paymentStatus, PaymentStatus.refunded);
      expect(refundedAttendee?.refundStatus, PaymentStatus.refunded);
    });
  });
}
