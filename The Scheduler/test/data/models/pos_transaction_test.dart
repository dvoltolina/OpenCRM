import 'package:flutter_test/flutter_test.dart';
import 'package:the_scheduler/data/models/pos_transaction.dart';
import 'package:the_scheduler/data/models/payment.dart';

void main() {
  group('PosLineItem Model', () {
    group('JSON Serialization', () {
      test('serializes to JSON and back', () {
        final lineItem = PosLineItem(
          productId: 'prod-123',
          productName: 'Face Cream',
          sku: 'SKU-001',
          quantity: 2,
          unitPriceCents: 2499,
          totalCents: 4498,
          discountCents: 500,
          discountReason: 'Loyalty discount',
          taxCents: 371,
          taxable: true,
        );

        final json = lineItem.toJson();
        final restored = PosLineItem.fromJson(json);

        expect(restored.productId, lineItem.productId);
        expect(restored.productName, lineItem.productName);
        expect(restored.sku, lineItem.sku);
        expect(restored.quantity, lineItem.quantity);
        expect(restored.unitPriceCents, lineItem.unitPriceCents);
        expect(restored.totalCents, lineItem.totalCents);
        expect(restored.discountCents, lineItem.discountCents);
        expect(restored.discountReason, lineItem.discountReason);
        expect(restored.taxCents, lineItem.taxCents);
        expect(restored.taxable, lineItem.taxable);
      });
    });

    group('Helper Getters', () {
      test('unitPriceDollars converts correctly', () {
        final lineItem = _createLineItem(unitPriceCents: 2499);
        expect(lineItem.unitPriceDollars, 24.99);
      });

      test('totalDollars converts correctly', () {
        final lineItem = _createLineItem(totalCents: 4998);
        expect(lineItem.totalDollars, 49.98);
      });

      test('discountDollars converts correctly', () {
        final lineItem = _createLineItem(discountCents: 500);
        expect(lineItem.discountDollars, 5.0);
      });

      test('taxDollars converts correctly', () {
        final lineItem = _createLineItem(taxCents: 412);
        expect(lineItem.taxDollars, 4.12);
      });

      test('subtotalCents calculates correctly', () {
        final lineItem = _createLineItem(unitPriceCents: 1000, quantity: 3);
        expect(lineItem.subtotalCents, 3000);
      });

      test('subtotalDollars converts correctly', () {
        final lineItem = _createLineItem(unitPriceCents: 1000, quantity: 3);
        expect(lineItem.subtotalDollars, 30.0);
      });

      test('hasDiscount returns true when discount applied', () {
        final lineItem = _createLineItem(discountCents: 500);
        expect(lineItem.hasDiscount, isTrue);
      });

      test('hasDiscount returns false when no discount', () {
        final lineItem = _createLineItem(discountCents: 0);
        expect(lineItem.hasDiscount, isFalse);
      });
    });
  });

  group('SplitPaymentDetail Model', () {
    group('JSON Serialization', () {
      test('serializes to JSON and back', () {
        final split = SplitPaymentDetail(
          method: PosPaymentMethod.card,
          amountCents: 5000,
          reference: '**** 4242',
          stripePaymentId: 'pi_123',
        );

        final json = split.toJson();
        final restored = SplitPaymentDetail.fromJson(json);

        expect(restored.method, split.method);
        expect(restored.amountCents, split.amountCents);
        expect(restored.reference, split.reference);
        expect(restored.stripePaymentId, split.stripePaymentId);
      });

      test('serializes gift card split', () {
        final split = SplitPaymentDetail(
          method: PosPaymentMethod.giftCard,
          amountCents: 2500,
          giftCardCode: 'GIFT-ABCD-1234',
        );

        final json = split.toJson();
        final restored = SplitPaymentDetail.fromJson(json);

        expect(restored.method, PosPaymentMethod.giftCard);
        expect(restored.giftCardCode, 'GIFT-ABCD-1234');
      });
    });

    test('amountDollars converts correctly', () {
      final split = SplitPaymentDetail(
        method: PosPaymentMethod.cash,
        amountCents: 2550,
      );
      expect(split.amountDollars, 25.5);
    });
  });

  group('PosTransaction Model', () {
    group('JSON Serialization', () {
      test('serializes to JSON and back', () {
        final transaction = PosTransaction(
          id: 'txn-123',
          businessId: 'biz-456',
          transactionDate: DateTime(2025, 1, 15, 14, 30),
          staffId: 'staff-789',
          staffName: 'Alice Staff',
          clientId: 'client-abc',
          clientName: 'Bob Client',
          appointmentId: 'appt-xyz',
          lineItems: [
            PosLineItem(
              productId: 'prod-1',
              productName: 'Product One',
              quantity: 2,
              unitPriceCents: 1000,
              totalCents: 2000,
            ),
          ],
          subtotalCents: 2000,
          taxCents: 165,
          taxRate: 0.0825,
          discountCents: 0,
          totalCents: 2165,
          paymentMethod: PosPaymentMethod.card,
          paymentStatus: PaymentStatus.completed,
          stripePaymentId: 'pi_test',
          receiptNumber: 'POS-20250115-0001',
          createdAt: DateTime(2025, 1, 15, 14, 30),
        );

        final json = transaction.toJson();
        final restored = PosTransaction.fromJson(json);

        expect(restored.id, transaction.id);
        expect(restored.businessId, transaction.businessId);
        expect(restored.staffId, transaction.staffId);
        expect(restored.staffName, transaction.staffName);
        expect(restored.clientId, transaction.clientId);
        expect(restored.clientName, transaction.clientName);
        expect(restored.appointmentId, transaction.appointmentId);
        expect(restored.lineItems.length, 1);
        expect(restored.subtotalCents, transaction.subtotalCents);
        expect(restored.taxCents, transaction.taxCents);
        expect(restored.taxRate, transaction.taxRate);
        expect(restored.totalCents, transaction.totalCents);
        expect(restored.paymentMethod, transaction.paymentMethod);
        expect(restored.paymentStatus, transaction.paymentStatus);
        expect(restored.stripePaymentId, transaction.stripePaymentId);
        expect(restored.receiptNumber, transaction.receiptNumber);
      });

      test('handles null optional fields', () {
        final transaction = _createTransaction();

        final json = transaction.toJson();
        final restored = PosTransaction.fromJson(json);

        expect(restored.staffName, isNull);
        expect(restored.clientId, isNull);
        expect(restored.clientName, isNull);
        expect(restored.appointmentId, isNull);
        expect(restored.stripePaymentId, isNull);
        expect(restored.giftCardCode, isNull);
        expect(restored.cashTenderedCents, isNull);
        expect(restored.changeCents, isNull);
        expect(restored.receiptNumber, isNull);
        expect(restored.receiptUrl, isNull);
        expect(restored.notes, isNull);
        expect(restored.voidReason, isNull);
        expect(restored.voidedAt, isNull);
        expect(restored.voidedBy, isNull);
      });

      test('serializes split payments', () {
        final transaction = _createTransaction(
          paymentMethod: PosPaymentMethod.split,
          splitPayments: [
            SplitPaymentDetail(
              method: PosPaymentMethod.giftCard,
              amountCents: 2000,
              giftCardCode: 'GIFT-1234',
            ),
            SplitPaymentDetail(
              method: PosPaymentMethod.card,
              amountCents: 3000,
              stripePaymentId: 'pi_test',
            ),
          ],
        );

        final json = transaction.toJson();
        final restored = PosTransaction.fromJson(json);

        expect(restored.splitPayments.length, 2);
        expect(restored.splitPayments[0].method, PosPaymentMethod.giftCard);
        expect(restored.splitPayments[0].amountCents, 2000);
        expect(restored.splitPayments[1].method, PosPaymentMethod.card);
        expect(restored.splitPayments[1].amountCents, 3000);
      });

      test('handles all payment method values', () {
        for (final method in PosPaymentMethod.values) {
          final transaction = _createTransaction(paymentMethod: method);

          final json = transaction.toJson();
          final restored = PosTransaction.fromJson(json);

          expect(restored.paymentMethod, method);
        }
      });

      test('handles all payment status values', () {
        for (final status in PaymentStatus.values) {
          final transaction = _createTransaction(paymentStatus: status);

          final json = transaction.toJson();
          final restored = PosTransaction.fromJson(json);

          expect(restored.paymentStatus, status);
        }
      });
    });

    group('Helper Getters', () {
      test('subtotalDollars converts correctly', () {
        final transaction = _createTransaction(subtotalCents: 2500);
        expect(transaction.subtotalDollars, 25.0);
      });

      test('taxDollars converts correctly', () {
        final transaction = _createTransaction(taxCents: 206);
        expect(transaction.taxDollars, 2.06);
      });

      test('discountDollars converts correctly', () {
        final transaction = _createTransaction(discountCents: 500);
        expect(transaction.discountDollars, 5.0);
      });

      test('totalDollars converts correctly', () {
        final transaction = _createTransaction(totalCents: 2706);
        expect(transaction.totalDollars, 27.06);
      });

      test('cashTenderedDollars converts correctly', () {
        final transaction = _createTransaction(
          paymentMethod: PosPaymentMethod.cash,
          cashTenderedCents: 3000,
        );
        expect(transaction.cashTenderedDollars, 30.0);
      });

      test('changeDollars converts correctly', () {
        final transaction = _createTransaction(
          paymentMethod: PosPaymentMethod.cash,
          changeCents: 294,
        );
        expect(transaction.changeDollars, 2.94);
      });

      test('totalItemCount sums quantities', () {
        final transaction = _createTransaction(
          lineItems: [
            _createLineItem(quantity: 2),
            _createLineItem(quantity: 3),
            _createLineItem(quantity: 1),
          ],
        );
        expect(transaction.totalItemCount, 6);
      });
    });

    group('Status Checks', () {
      test('isWalkIn returns true when no client', () {
        final transaction = _createTransaction(clientId: null);
        expect(transaction.isWalkIn, isTrue);
      });

      test('isWalkIn returns false when client attached', () {
        final transaction = _createTransaction(clientId: 'client-123');
        expect(transaction.isWalkIn, isFalse);
      });

      test('isAppointmentSale returns true when appointment linked', () {
        final transaction = _createTransaction(appointmentId: 'appt-123');
        expect(transaction.isAppointmentSale, isTrue);
      });

      test('isAppointmentSale returns false when no appointment', () {
        final transaction = _createTransaction(appointmentId: null);
        expect(transaction.isAppointmentSale, isFalse);
      });

      test('isCompleted returns true for completed status', () {
        final transaction = _createTransaction(
          paymentStatus: PaymentStatus.completed,
        );
        expect(transaction.isCompleted, isTrue);
      });

      test('isCompleted returns false for other statuses', () {
        final transaction = _createTransaction(
          paymentStatus: PaymentStatus.pending,
        );
        expect(transaction.isCompleted, isFalse);
      });

      test('isPending returns true for pending status', () {
        final transaction = _createTransaction(
          paymentStatus: PaymentStatus.pending,
        );
        expect(transaction.isPending, isTrue);
      });

      test('hasDiscount returns true when discount applied', () {
        final transaction = _createTransaction(discountCents: 500);
        expect(transaction.hasDiscount, isTrue);
      });

      test('hasDiscount returns false when no discount', () {
        final transaction = _createTransaction(discountCents: 0);
        expect(transaction.hasDiscount, isFalse);
      });

      test('isSplitPayment returns true for split method', () {
        final transaction = _createTransaction(
          paymentMethod: PosPaymentMethod.split,
        );
        expect(transaction.isSplitPayment, isTrue);
      });

      test('isSplitPayment returns false for other methods', () {
        final transaction = _createTransaction(
          paymentMethod: PosPaymentMethod.card,
        );
        expect(transaction.isSplitPayment, isFalse);
      });
    });

    group('Display Helpers', () {
      test('paymentMethodDisplay shows single method', () {
        final transaction = _createTransaction(
          paymentMethod: PosPaymentMethod.card,
        );
        expect(transaction.paymentMethodDisplay, 'Card');
      });

      test('paymentMethodDisplay shows combined methods for split', () {
        final transaction = _createTransaction(
          paymentMethod: PosPaymentMethod.split,
          splitPayments: [
            SplitPaymentDetail(
              method: PosPaymentMethod.giftCard,
              amountCents: 2000,
            ),
            SplitPaymentDetail(
              method: PosPaymentMethod.card,
              amountCents: 3000,
            ),
          ],
        );
        // Order may vary, so check for presence
        expect(
          transaction.paymentMethodDisplay.contains('Gift Card'),
          isTrue,
        );
        expect(
          transaction.paymentMethodDisplay.contains('Card'),
          isTrue,
        );
      });

      test('paymentStatusDisplay returns correct strings', () {
        expect(
          _createTransaction(paymentStatus: PaymentStatus.none)
              .paymentStatusDisplay,
          'None',
        );
        expect(
          _createTransaction(paymentStatus: PaymentStatus.pending)
              .paymentStatusDisplay,
          'Pending',
        );
        expect(
          _createTransaction(paymentStatus: PaymentStatus.completed)
              .paymentStatusDisplay,
          'Completed',
        );
        expect(
          _createTransaction(paymentStatus: PaymentStatus.failed)
              .paymentStatusDisplay,
          'Failed',
        );
        expect(
          _createTransaction(paymentStatus: PaymentStatus.refunded)
              .paymentStatusDisplay,
          'Refunded',
        );
        expect(
          _createTransaction(paymentStatus: PaymentStatus.partiallyRefunded)
              .paymentStatusDisplay,
          'Partially Refunded',
        );
      });

      test('totalDisplay formats correctly', () {
        final transaction = _createTransaction(totalCents: 2706);
        expect(transaction.totalDisplay, '\$27.06');
      });

      test('receiptDisplay shows receipt number when available', () {
        final transaction = _createTransaction(
          receiptNumber: 'POS-20250115-0001',
        );
        expect(transaction.receiptDisplay, 'POS-20250115-0001');
      });

      test('receiptDisplay falls back to ID prefix when no receipt number',
          () {
        final transaction = _createTransaction(
          id: 'abcd1234efgh5678',
          receiptNumber: null,
        );
        expect(transaction.receiptDisplay, 'ABCD1234');
      });
    });

    group('PosPaymentMethod Extension', () {
      test('displayName returns correct strings', () {
        expect(PosPaymentMethod.card.displayName, 'Card');
        expect(PosPaymentMethod.cash.displayName, 'Cash');
        expect(PosPaymentMethod.giftCard.displayName, 'Gift Card');
        expect(PosPaymentMethod.split.displayName, 'Split Payment');
        expect(PosPaymentMethod.account.displayName, 'Account');
      });

      test('icon returns correct icon names', () {
        expect(PosPaymentMethod.card.icon, 'credit_card');
        expect(PosPaymentMethod.cash.icon, 'payments');
        expect(PosPaymentMethod.giftCard.icon, 'card_giftcard');
        expect(PosPaymentMethod.split.icon, 'call_split');
        expect(PosPaymentMethod.account.icon, 'account_balance_wallet');
      });
    });
  });

  group('CartItem Model', () {
    group('JSON Serialization', () {
      test('serializes to JSON and back', () {
        final cartItem = CartItem(
          productId: 'prod-123',
          productName: 'Test Product',
          sku: 'SKU-001',
          unitPriceCents: 2499,
          quantity: 3,
          taxable: true,
          discountCents: 500,
          discountReason: 'Promo',
        );

        final json = cartItem.toJson();
        final restored = CartItem.fromJson(json);

        expect(restored.productId, cartItem.productId);
        expect(restored.productName, cartItem.productName);
        expect(restored.sku, cartItem.sku);
        expect(restored.unitPriceCents, cartItem.unitPriceCents);
        expect(restored.quantity, cartItem.quantity);
        expect(restored.taxable, cartItem.taxable);
        expect(restored.discountCents, cartItem.discountCents);
        expect(restored.discountReason, cartItem.discountReason);
      });
    });

    group('Helper Getters', () {
      test('totalCents calculates correctly without discount', () {
        final cartItem = CartItem(
          productId: 'prod-123',
          productName: 'Test',
          unitPriceCents: 1000,
          quantity: 3,
        );
        expect(cartItem.totalCents, 3000);
      });

      test('totalCents calculates correctly with discount', () {
        final cartItem = CartItem(
          productId: 'prod-123',
          productName: 'Test',
          unitPriceCents: 1000,
          quantity: 3,
          discountCents: 500,
        );
        expect(cartItem.totalCents, 2500);
      });

      test('totalDollars converts correctly', () {
        final cartItem = CartItem(
          productId: 'prod-123',
          productName: 'Test',
          unitPriceCents: 1000,
          quantity: 3,
        );
        expect(cartItem.totalDollars, 30.0);
      });

      test('unitPriceDollars converts correctly', () {
        final cartItem = CartItem(
          productId: 'prod-123',
          productName: 'Test',
          unitPriceCents: 2499,
          quantity: 1,
        );
        expect(cartItem.unitPriceDollars, 24.99);
      });
    });

    group('toLineItem', () {
      test('converts cart item to line item', () {
        final cartItem = CartItem(
          productId: 'prod-123',
          productName: 'Test Product',
          sku: 'SKU-001',
          unitPriceCents: 1000,
          quantity: 2,
          taxable: true,
          discountCents: 200,
          discountReason: 'Promo',
        );

        final lineItem = cartItem.toLineItem(taxCents: 148);

        expect(lineItem.productId, 'prod-123');
        expect(lineItem.productName, 'Test Product');
        expect(lineItem.sku, 'SKU-001');
        expect(lineItem.unitPriceCents, 1000);
        expect(lineItem.quantity, 2);
        expect(lineItem.totalCents, 1800); // (1000 * 2) - 200
        expect(lineItem.discountCents, 200);
        expect(lineItem.discountReason, 'Promo');
        expect(lineItem.taxCents, 148);
        expect(lineItem.taxable, true);
      });

      test('defaults taxCents to 0', () {
        final cartItem = CartItem(
          productId: 'prod-123',
          productName: 'Test',
          unitPriceCents: 1000,
          quantity: 1,
        );

        final lineItem = cartItem.toLineItem();

        expect(lineItem.taxCents, 0);
      });
    });
  });
}

/// Helper function to create a test line item with sensible defaults
PosLineItem _createLineItem({
  String productId = 'prod-123',
  String productName = 'Test Product',
  int quantity = 1,
  int unitPriceCents = 1000,
  int totalCents = 1000,
  int discountCents = 0,
  int taxCents = 0,
}) {
  return PosLineItem(
    productId: productId,
    productName: productName,
    quantity: quantity,
    unitPriceCents: unitPriceCents,
    totalCents: totalCents,
    discountCents: discountCents,
    taxCents: taxCents,
  );
}

/// Helper function to create a test transaction with sensible defaults
PosTransaction _createTransaction({
  String id = 'txn-123',
  String businessId = 'biz-456',
  String staffId = 'staff-789',
  String? clientId,
  String? appointmentId,
  List<PosLineItem>? lineItems,
  int subtotalCents = 2000,
  int taxCents = 165,
  int discountCents = 0,
  int totalCents = 2165,
  PosPaymentMethod paymentMethod = PosPaymentMethod.card,
  PaymentStatus paymentStatus = PaymentStatus.completed,
  List<SplitPaymentDetail>? splitPayments,
  int? cashTenderedCents,
  int? changeCents,
  String? receiptNumber,
}) {
  return PosTransaction(
    id: id,
    businessId: businessId,
    transactionDate: DateTime(2025, 1, 15, 14, 30),
    staffId: staffId,
    clientId: clientId,
    appointmentId: appointmentId,
    lineItems: lineItems ?? [_createLineItem()],
    subtotalCents: subtotalCents,
    taxCents: taxCents,
    discountCents: discountCents,
    totalCents: totalCents,
    paymentMethod: paymentMethod,
    paymentStatus: paymentStatus,
    splitPayments: splitPayments ?? [],
    cashTenderedCents: cashTenderedCents,
    changeCents: changeCents,
    receiptNumber: receiptNumber,
    createdAt: DateTime(2025, 1, 15, 14, 30),
  );
}
