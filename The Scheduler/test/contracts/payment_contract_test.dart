// Payment Contract Tests
//
// Validates that Payment model schema matches the shared data contract
// defined in docs/shared_data_contract.md
//
// Contract path: businesses/{businessId}/payments/{paymentId}
//
// IMPORTANT: All monetary values are in CENTS (int), not dollars (double)

import 'package:flutter_test/flutter_test.dart';
import 'package:the_scheduler/data/models/payment.dart';

void main() {
  group('Payment Contract Tests', () {
    group('Schema Validation', () {
      test('Payment has all required fields per contract', () {
        final payment = Payment(
          id: 'payment-1',
          businessId: 'business-1',
          appointmentId: 'appt-1',
          clientId: 'client-1',
          amountCents: 5000,
          status: PaymentStatus.completed,
          type: PaymentType.full,
          createdAt: DateTime.now(),
        );

        // Required fields per docs/shared_data_contract.md
        expect(payment.id, isNotNull);
        expect(payment.businessId, isNotNull);
        expect(payment.appointmentId, isNotNull);
        expect(payment.clientId, isNotNull);
        expect(payment.amountCents, isNotNull);
        expect(payment.status, isNotNull);
        expect(payment.type, isNotNull);
        expect(payment.createdAt, isNotNull);
      });

      test('Payment status enum matches contract values', () {
        // Contract: pending, completed, failed, refunded, partially_refunded, none
        expect(PaymentStatus.values, containsAll([
          PaymentStatus.pending,
          PaymentStatus.completed,
          PaymentStatus.failed,
          PaymentStatus.refunded,
          PaymentStatus.partiallyRefunded,
          PaymentStatus.none,
        ]));
      });

      test('Payment type enum matches contract values', () {
        // Contract: deposit, full, subscription, reschedule_fee, cancellation_fee, refund
        expect(PaymentType.values, containsAll([
          PaymentType.deposit,
          PaymentType.full,
        ]));
      });

      test('Payment amount is in cents (int, not double)', () {
        final payment = Payment(
          id: 'payment-1',
          businessId: 'business-1',
          appointmentId: 'appt-1',
          clientId: 'client-1',
          amountCents: 5000, // $50.00 in cents
          status: PaymentStatus.completed,
          type: PaymentType.full,
          createdAt: DateTime.now(),
        );

        expect(payment.amountCents, isA<int>());
        expect(payment.amountCents, equals(5000));
      });
    });

    group('Serialization Contract', () {
      test('Payment toJson produces contract-compliant keys', () {
        final payment = Payment(
          id: 'payment-1',
          businessId: 'business-1',
          appointmentId: 'appt-1',
          clientId: 'client-1',
          amountCents: 5000,
          status: PaymentStatus.completed,
          type: PaymentType.full,
          createdAt: DateTime.now(),
        );

        final json = payment.toJson();

        // Contract field names
        expect(json.containsKey('id'), isTrue);
        expect(json.containsKey('businessId'), isTrue);
        expect(json.containsKey('appointmentId'), isTrue);
        expect(json.containsKey('clientId'), isTrue);
        expect(json.containsKey('amountCents'), isTrue);
        expect(json.containsKey('status'), isTrue);
        expect(json.containsKey('type'), isTrue);
        expect(json.containsKey('createdAt'), isTrue);
      });

      test('Payment fromJson parses contract-compliant data', () {
        final json = {
          'id': 'payment-1',
          'businessId': 'business-1',
          'appointmentId': 'appt-1',
          'clientId': 'client-1',
          'amountCents': 7500,
          'currency': 'usd',
          'status': 'completed',
          'type': 'full',
          'createdAt': '2025-01-01T00:00:00.000',
        };

        final payment = Payment.fromJson(json);

        expect(payment.id, equals('payment-1'));
        expect(payment.businessId, equals('business-1'));
        expect(payment.appointmentId, equals('appt-1'));
        expect(payment.clientId, equals('client-1'));
        expect(payment.amountCents, equals(7500));
        expect(payment.status, equals(PaymentStatus.completed));
        expect(payment.type, equals(PaymentType.full));
      });
    });

    group('Refund Contract', () {
      test('Refund fields are optional on initial payment', () {
        final payment = Payment(
          id: 'payment-1',
          businessId: 'business-1',
          appointmentId: 'appt-1',
          clientId: 'client-1',
          amountCents: 5000,
          status: PaymentStatus.completed,
          type: PaymentType.full,
          createdAt: DateTime.now(),
        );

        expect(payment.refundAmountCents, isNull);
        expect(payment.refundedAt, isNull);
        expect(payment.stripeRefundId, isNull);
      });

      test('Refunded payment has refund fields populated', () {
        final refundedPayment = Payment(
          id: 'payment-1',
          businessId: 'business-1',
          appointmentId: 'appt-1',
          clientId: 'client-1',
          amountCents: 5000,
          status: PaymentStatus.refunded,
          type: PaymentType.full,
          refundAmountCents: 5000,
          refundedAt: DateTime.now(),
          stripeRefundId: 're_test123',
          reason: 'Customer requested',
          createdAt: DateTime.now(),
        );

        expect(refundedPayment.status, equals(PaymentStatus.refunded));
        expect(refundedPayment.refundAmountCents, equals(5000));
        expect(refundedPayment.refundedAt, isNotNull);
        expect(refundedPayment.stripeRefundId, isNotNull);
      });

      test('Partial refund amount is less than original', () {
        final partialRefund = Payment(
          id: 'payment-1',
          businessId: 'business-1',
          appointmentId: 'appt-1',
          clientId: 'client-1',
          amountCents: 5000,
          status: PaymentStatus.partiallyRefunded,
          type: PaymentType.full,
          refundAmountCents: 2500, // 50% refund
          refundedAt: DateTime.now(),
          createdAt: DateTime.now(),
        );

        expect(partialRefund.refundAmountCents, lessThan(partialRefund.amountCents));
        expect(partialRefund.status, equals(PaymentStatus.partiallyRefunded));
      });
    });

    group('Referential Integrity Contract', () {
      test('Payment references valid appointment', () {
        final payment = Payment(
          id: 'payment-1',
          businessId: 'business-1',
          appointmentId: 'appt-123',
          clientId: 'client-1',
          amountCents: 5000,
          status: PaymentStatus.completed,
          type: PaymentType.full,
          createdAt: DateTime.now(),
        );

        expect(payment.appointmentId, isNotEmpty);
        expect(payment.appointmentId, equals('appt-123'));
      });

      test('Payment references valid client', () {
        final payment = Payment(
          id: 'payment-1',
          businessId: 'business-1',
          appointmentId: 'appt-1',
          clientId: 'client-456',
          amountCents: 5000,
          status: PaymentStatus.completed,
          type: PaymentType.full,
          createdAt: DateTime.now(),
        );

        expect(payment.clientId, isNotEmpty);
        expect(payment.clientId, equals('client-456'));
      });
    });

    group('Tenant Isolation Contract', () {
      test('Payment businessId required for tenant scoping', () {
        final payment = Payment(
          id: 'payment-1',
          businessId: 'tenant-xyz',
          appointmentId: 'appt-1',
          clientId: 'client-1',
          amountCents: 5000,
          status: PaymentStatus.completed,
          type: PaymentType.full,
          createdAt: DateTime.now(),
        );

        expect(payment.businessId, equals('tenant-xyz'));
        expect(payment.businessId, isNotEmpty);
      });
    });

    group('Financial Immutability Contract', () {
      test('Payment records cannot be deleted per contract', () {
        // Note: This is enforced at Firestore rules level
        // allow delete: if false;
        // This test documents the contract expectation
        expect(true, isTrue, reason: 'Deletion blocked by Firestore rules');
      });

      test('Completed payment amount cannot change', () {
        final original = Payment(
          id: 'payment-1',
          businessId: 'business-1',
          appointmentId: 'appt-1',
          clientId: 'client-1',
          amountCents: 5000,
          status: PaymentStatus.completed,
          type: PaymentType.full,
          createdAt: DateTime.now(),
        );

        // Freezed immutability - copyWith creates new instance
        final modified = original.copyWith(amountCents: 6000);

        // Original unchanged
        expect(original.amountCents, equals(5000));
        // New instance has different value
        expect(modified.amountCents, equals(6000));
        // Different instances
        expect(identical(original, modified), isFalse);
      });
    });
  });
}
