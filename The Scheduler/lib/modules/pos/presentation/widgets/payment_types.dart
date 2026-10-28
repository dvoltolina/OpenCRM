import '../../../../data/models/pos_transaction.dart';

/// Result of a payment dialog.
class PaymentDialogResult {
  const PaymentDialogResult({
    required this.success,
    this.transaction,
    this.receiptNumber,
    this.error,
  });

  final bool success;
  final PosTransaction? transaction;
  final String? receiptNumber;
  final String? error;
}

/// Helper to get payment method icon.
extension PaymentMethodIconExtension on PosPaymentMethod {
  /// Returns the icon for this payment method.
  String get iconName {
    switch (this) {
      case PosPaymentMethod.cash:
        return 'payments';
      case PosPaymentMethod.card:
        return 'credit_card';
      case PosPaymentMethod.giftCard:
        return 'card_giftcard';
      default:
        return 'payment';
    }
  }

  /// Returns the dialog title for this payment method.
  String get dialogTitle {
    switch (this) {
      case PosPaymentMethod.cash:
        return 'Cash Payment';
      case PosPaymentMethod.card:
        return 'Card Payment';
      case PosPaymentMethod.giftCard:
        return 'Gift Card Payment';
      default:
        return 'Payment';
    }
  }

  /// Returns the button label for this payment method.
  String get buttonLabel {
    switch (this) {
      case PosPaymentMethod.cash:
        return 'Complete Sale';
      case PosPaymentMethod.card:
        return 'Pay with Card';
      case PosPaymentMethod.giftCard:
        return 'Redeem Gift Card';
      default:
        return 'Pay';
    }
  }
}

/// Calculates quick cash amount suggestions based on total.
List<double> getQuickAmounts(double totalDollars) {
  final amounts = <double>[];

  // Round up to nearest $5
  final roundedUp5 = (totalDollars / 5).ceil() * 5.0;
  if (roundedUp5 > totalDollars) amounts.add(roundedUp5);

  // Round up to nearest $10
  final roundedUp10 = (totalDollars / 10).ceil() * 10.0;
  if (roundedUp10 > totalDollars && !amounts.contains(roundedUp10)) {
    amounts.add(roundedUp10);
  }

  // Round up to nearest $20
  final roundedUp20 = (totalDollars / 20).ceil() * 20.0;
  if (roundedUp20 > totalDollars && !amounts.contains(roundedUp20)) {
    amounts.add(roundedUp20);
  }

  // Add $50 and $100 if total is less
  if (totalDollars < 50) amounts.add(50);
  if (totalDollars < 100) amounts.add(100);

  return amounts.take(4).toList();
}
