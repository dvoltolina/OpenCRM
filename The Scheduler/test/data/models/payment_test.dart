import 'package:flutter_test/flutter_test.dart';
import 'package:the_scheduler/data/models/payment.dart';
import '../../helpers/test_data_factories.dart';

void main() {
  group('Payment Model', () {
    group('JSON Serialization', () {
      test('creates payment from JSON', () {
        final json = {
          'id': 'payment-1',
          'businessId': 'business-1',
          'appointmentId': 'appointment-1',
          'clientId': 'client-1',
          'amountCents': 10000,
          'currency': 'USD',
          'status': 'completed',
          'type': 'full',
          'stripePaymentIntentId': 'pi_123',
          'stripeChargeId': 'ch_123',
          'cardLast4': '4242',
          'cardBrand': 'visa',
          'createdAt': '2025-12-01T10:00:00.000Z',
          'completedAt': '2025-12-01T10:01:00.000Z',
        };

        final payment = Payment.fromJson(json);

        expect(payment.id, 'payment-1');
        expect(payment.businessId, 'business-1');
        expect(payment.appointmentId, 'appointment-1');
        expect(payment.clientId, 'client-1');
        expect(payment.amountCents, 10000);
        expect(payment.currency, 'USD');
        expect(payment.status, PaymentStatus.completed);
        expect(payment.type, PaymentType.full);
        expect(payment.stripePaymentIntentId, 'pi_123');
        expect(payment.stripeChargeId, 'ch_123');
        expect(payment.cardLast4, '4242');
        expect(payment.cardBrand, 'visa');
      });

      test('converts payment to JSON', () {
        final payment = TestData.payment(
          id: 'payment-1',
          amountCents: 10000,
          status: PaymentStatus.completed,
          type: PaymentType.full,
        );

        final json = payment.toJson();

        expect(json['id'], 'payment-1');
        expect(json['amountCents'], 10000);
        expect(json['status'], 'completed');
        expect(json['type'], 'full');
        expect(json['currency'], 'USD');
      });

      test('handles all payment statuses', () {
        expect(PaymentStatus.none.name, 'none');
        expect(PaymentStatus.pending.name, 'pending');
        expect(PaymentStatus.completed.name, 'completed');
        expect(PaymentStatus.failed.name, 'failed');
        expect(PaymentStatus.refunded.name, 'refunded');
        expect(PaymentStatus.partiallyRefunded.name, 'partiallyRefunded');
      });

      test('handles all payment types', () {
        expect(PaymentType.deposit.name, 'deposit');
        expect(PaymentType.full.name, 'full');
        expect(PaymentType.subscription.name, 'subscription');
        expect(PaymentType.rescheduleFee.name, 'rescheduleFee');
        expect(PaymentType.cancellationFee.name, 'cancellationFee');
        expect(PaymentType.refund.name, 'refund');
      });

      test('handles null optional fields', () {
        final payment = Payment(
          id: 'payment-1',
          businessId: 'business-1',
          appointmentId: 'appointment-1',
          clientId: 'client-1',
          amountCents: 5000,
          status: PaymentStatus.pending,
          type: PaymentType.deposit,
          createdAt: DateTime(2025, 12, 1),
        );

        expect(payment.stripePaymentIntentId, null);
        expect(payment.stripeChargeId, null);
        expect(payment.stripeRefundId, null);
        expect(payment.cardLast4, null);
        expect(payment.cardBrand, null);
        expect(payment.completedAt, null);
        expect(payment.refundedAt, null);
        expect(payment.refundAmountCents, null);
        expect(payment.parentPaymentId, null);
        expect(payment.reason, null);
        expect(payment.errorMessage, null);
        expect(payment.notes, null);
      });
    });

    group('copyWith', () {
      test('copies with new status', () {
        final payment = TestData.payment(status: PaymentStatus.pending);
        final updated = payment.copyWith(status: PaymentStatus.completed);

        expect(updated.status, PaymentStatus.completed);
        expect(updated.id, payment.id);
        expect(updated.amountCents, payment.amountCents);
      });

      test('copies with completion timestamp', () {
        final payment = TestData.payment(status: PaymentStatus.pending);
        final completedAt = DateTime(2025, 12, 1, 12, 0);
        final updated = payment.copyWith(
          status: PaymentStatus.completed,
          completedAt: completedAt,
        );

        expect(updated.status, PaymentStatus.completed);
        expect(updated.completedAt, completedAt);
      });

      test('copies with refund information', () {
        final payment = TestData.payment(
          amountCents: 10000,
          status: PaymentStatus.completed,
        );
        final refundedAt = DateTime(2025, 12, 2);
        final updated = payment.copyWith(
          status: PaymentStatus.partiallyRefunded,
          refundAmountCents: 5000,
          refundedAt: refundedAt,
          stripeRefundId: 're_123',
          reason: 'Customer request',
        );

        expect(updated.status, PaymentStatus.partiallyRefunded);
        expect(updated.refundAmountCents, 5000);
        expect(updated.refundedAt, refundedAt);
        expect(updated.stripeRefundId, 're_123');
        expect(updated.reason, 'Customer request');
      });

      test('copies with error message', () {
        final payment = TestData.payment(status: PaymentStatus.pending);
        final updated = payment.copyWith(
          status: PaymentStatus.failed,
          errorMessage: 'Insufficient funds',
        );

        expect(updated.status, PaymentStatus.failed);
        expect(updated.errorMessage, 'Insufficient funds');
      });

      test('preserves all fields when no changes', () {
        final payment = TestData.payment(
          id: 'payment-1',
          amountCents: 10000,
          cardLast4: '4242',
          cardBrand: 'visa',
        );
        final copy = payment.copyWith();

        expect(copy.id, payment.id);
        expect(copy.amountCents, payment.amountCents);
        expect(copy.cardLast4, payment.cardLast4);
        expect(copy.cardBrand, payment.cardBrand);
      });
    });

    group('Helper Methods', () {
      test('amountDollars converts cents to dollars', () {
        final payment1 = TestData.payment(amountCents: 10000);
        final payment2 = TestData.payment(amountCents: 12550);
        final payment3 = TestData.payment(amountCents: 500);

        expect(payment1.amountDollars, 100.0);
        expect(payment2.amountDollars, 125.50);
        expect(payment3.amountDollars, 5.0);
      });

      test('refundAmountDollars converts cents to dollars', () {
        final payment1 = TestData.payment(refundAmountCents: 5000);
        final payment2 = TestData.payment(refundAmountCents: null);

        expect(payment1.refundAmountDollars, 50.0);
        expect(payment2.refundAmountDollars, 0.0);
      });

      test('isCompleted returns true only for completed status', () {
        final completed = TestData.payment(status: PaymentStatus.completed);
        final pending = TestData.payment(status: PaymentStatus.pending);
        final failed = TestData.payment(status: PaymentStatus.failed);

        expect(completed.isCompleted, true);
        expect(pending.isCompleted, false);
        expect(failed.isCompleted, false);
      });

      test('isPending returns true only for pending status', () {
        final pending = TestData.payment(status: PaymentStatus.pending);
        final completed = TestData.payment(status: PaymentStatus.completed);

        expect(pending.isPending, true);
        expect(completed.isPending, false);
      });

      test('isFailed returns true only for failed status', () {
        final failed = TestData.payment(status: PaymentStatus.failed);
        final completed = TestData.payment(status: PaymentStatus.completed);

        expect(failed.isFailed, true);
        expect(completed.isFailed, false);
      });

      test('isRefunded returns true for refunded and partially refunded', () {
        final refunded = TestData.payment(status: PaymentStatus.refunded);
        final partiallyRefunded =
            TestData.payment(status: PaymentStatus.partiallyRefunded);
        final completed = TestData.payment(status: PaymentStatus.completed);

        expect(refunded.isRefunded, true);
        expect(partiallyRefunded.isRefunded, true);
        expect(completed.isRefunded, false);
      });

      test('isRefund returns true only for refund type', () {
        final refund = TestData.payment(type: PaymentType.refund);
        final full = TestData.payment(type: PaymentType.full);

        expect(refund.isRefund, true);
        expect(full.isRefund, false);
      });

      test('isFee returns true for reschedule and cancellation fees', () {
        final rescheduleFee =
            TestData.payment(type: PaymentType.rescheduleFee);
        final cancellationFee =
            TestData.payment(type: PaymentType.cancellationFee);
        final full = TestData.payment(type: PaymentType.full);

        expect(rescheduleFee.isFee, true);
        expect(cancellationFee.isFee, true);
        expect(full.isFee, false);
      });

      test('netAmountCents calculates correctly with no refund', () {
        final payment = TestData.payment(
          amountCents: 10000,
          refundAmountCents: null,
        );

        expect(payment.netAmountCents, 10000);
      });

      test('netAmountCents calculates correctly with partial refund', () {
        final payment = TestData.payment(
          amountCents: 10000,
          refundAmountCents: 3000,
        );

        expect(payment.netAmountCents, 7000);
      });

      test('netAmountCents calculates correctly with full refund', () {
        final payment = TestData.payment(
          amountCents: 10000,
          refundAmountCents: 10000,
        );

        expect(payment.netAmountCents, 0);
      });

      test('paymentMethodDisplay formats card correctly', () {
        final payment = TestData.payment(
          cardBrand: 'visa',
          cardLast4: '4242',
        );

        expect(payment.paymentMethodDisplay, 'Visa ****4242');
      });

      test('paymentMethodDisplay formats all card brands', () {
        final visa = Payment(
          id: 'p1',
          businessId: 'b1',
          appointmentId: 'a1',
          clientId: 'c1',
          amountCents: 1000,
          status: PaymentStatus.completed,
          type: PaymentType.full,
          cardBrand: 'visa',
          cardLast4: '4242',
          createdAt: DateTime.now(),
        );

        final mastercard = visa.copyWith(cardBrand: 'mastercard');
        final amex = visa.copyWith(cardBrand: 'amex');
        final discover = visa.copyWith(cardBrand: 'discover');

        expect(visa.paymentMethodDisplay, 'Visa ****4242');
        expect(mastercard.paymentMethodDisplay, 'Mastercard ****4242');
        expect(amex.paymentMethodDisplay, 'American Express ****4242');
        expect(discover.paymentMethodDisplay, 'Discover ****4242');
      });

      test('paymentMethodDisplay uses description if no card info', () {
        final payment = TestData.payment(
          paymentMethodDescription: 'PayPal',
        );

        expect(payment.paymentMethodDisplay, 'PayPal');
      });

      test('paymentMethodDisplay returns Unknown if no info', () {
        final payment = TestData.payment();

        expect(payment.paymentMethodDisplay, 'Unknown');
      });
    });

    group('Business Logic', () {
      test('supports multi-tenant isolation', () {
        final payment1 = TestData.payment(businessId: 'business-1');
        final payment2 = TestData.payment(businessId: 'business-2');

        expect(payment1.businessId, 'business-1');
        expect(payment2.businessId, 'business-2');
        expect(payment1.businessId, isNot(payment2.businessId));
      });

      test('tracks full payment lifecycle', () {
        final createdAt = DateTime(2025, 12, 1, 10, 0);
        final completedAt = DateTime(2025, 12, 1, 10, 1);
        final refundedAt = DateTime(2025, 12, 2, 14, 0);

        // Payment created
        var payment = Payment(
          id: 'payment-1',
          businessId: 'business-1',
          appointmentId: 'appointment-1',
          clientId: 'client-1',
          amountCents: 10000,
          status: PaymentStatus.pending,
          type: PaymentType.full,
          createdAt: createdAt,
        );

        expect(payment.isPending, true);
        expect(payment.isCompleted, false);

        // Payment completed
        payment = payment.copyWith(
          status: PaymentStatus.completed,
          completedAt: completedAt,
          stripePaymentIntentId: 'pi_123',
          stripeChargeId: 'ch_123',
        );

        expect(payment.isPending, false);
        expect(payment.isCompleted, true);
        expect(payment.completedAt, completedAt);

        // Payment refunded
        payment = payment.copyWith(
          status: PaymentStatus.partiallyRefunded,
          refundAmountCents: 5000,
          refundedAt: refundedAt,
          stripeRefundId: 're_123',
          reason: 'Customer request',
        );

        expect(payment.isRefunded, true);
        expect(payment.refundAmountCents, 5000);
        expect(payment.netAmountCents, 5000);
        expect(payment.refundedAt, refundedAt);
      });

      test('handles deposit payment', () {
        final deposit = TestData.payment(
          amountCents: 2500, // $25 deposit
          type: PaymentType.deposit,
        );

        expect(deposit.type, PaymentType.deposit);
        expect(deposit.amountDollars, 25.0);
        expect(deposit.isFee, false);
      });

      test('handles cancellation fee', () {
        final fee = TestData.payment(
          amountCents: 5000, // $50 fee
          type: PaymentType.cancellationFee,
        );

        expect(fee.type, PaymentType.cancellationFee);
        expect(fee.isFee, true);
        expect(fee.amountDollars, 50.0);
      });

      test('handles failed payment with error', () {
        final failed = Payment(
          id: 'payment-1',
          businessId: 'business-1',
          appointmentId: 'appointment-1',
          clientId: 'client-1',
          amountCents: 10000,
          status: PaymentStatus.failed,
          type: PaymentType.full,
          errorMessage: 'Card declined: Insufficient funds',
          createdAt: DateTime(2025, 12, 1),
        );

        expect(failed.isFailed, true);
        expect(failed.errorMessage, contains('Insufficient funds'));
      });
    });

    group('Test Data Factory', () {
      test('creates payment with defaults', () {
        final payment = TestData.payment();

        expect(payment.id, isNotEmpty);
        expect(payment.businessId, TestData.businessId);
        expect(payment.amountCents, greaterThan(0));
        expect(payment.status, isNotNull);
        expect(payment.type, isNotNull);
        expect(payment.currency, 'USD');
      });

      test('creates payment with custom values', () {
        final payment = TestData.payment(
          id: 'custom-payment',
          amountCents: 15000,
          status: PaymentStatus.refunded,
          type: PaymentType.deposit,
        );

        expect(payment.id, 'custom-payment');
        expect(payment.amountCents, 15000);
        expect(payment.status, PaymentStatus.refunded);
        expect(payment.type, PaymentType.deposit);
      });
    });
  });
}
