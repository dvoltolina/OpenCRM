import 'package:freezed_annotation/freezed_annotation.dart';

import 'payment.dart';
import '../converters/timestamp_converters.dart';

part 'pos_transaction.freezed.dart';
part 'pos_transaction.g.dart';

/// Payment method for POS transactions
enum PosPaymentMethod {
  @JsonValue('card')
  card, // Credit/debit card via Stripe

  @JsonValue('cash')
  cash, // Cash payment

  @JsonValue('gift_card')
  giftCard, // Gift card redemption

  @JsonValue('split')
  split, // Multiple payment methods

  @JsonValue('account')
  account, // Charge to client account
}

/// Extension for PosPaymentMethod display
extension PosPaymentMethodExtension on PosPaymentMethod {
  String get displayName {
    switch (this) {
      case PosPaymentMethod.card:
        return 'Card';
      case PosPaymentMethod.cash:
        return 'Cash';
      case PosPaymentMethod.giftCard:
        return 'Gift Card';
      case PosPaymentMethod.split:
        return 'Split Payment';
      case PosPaymentMethod.account:
        return 'Account';
    }
  }

  String get icon {
    switch (this) {
      case PosPaymentMethod.card:
        return 'credit_card';
      case PosPaymentMethod.cash:
        return 'payments';
      case PosPaymentMethod.giftCard:
        return 'card_giftcard';
      case PosPaymentMethod.split:
        return 'call_split';
      case PosPaymentMethod.account:
        return 'account_balance_wallet';
    }
  }
}

/// A single line item in a POS transaction
@freezed
abstract class PosLineItem with _$PosLineItem {
  const factory PosLineItem({
    /// Product ID
    required String productId,

    /// Product name (denormalized for receipt)
    required String productName,

    /// SKU (denormalized for receipt)
    String? sku,

    /// Quantity purchased
    required int quantity,

    /// Unit price in cents at time of sale
    required int unitPriceCents,

    /// Total for this line item in cents (quantity * unitPrice - discount)
    required int totalCents,

    /// Discount applied to this line item in cents
    @Default(0) int discountCents,

    /// Reason for discount if applied
    String? discountReason,

    /// Tax amount for this line item in cents
    @Default(0) int taxCents,

    /// Whether this item is taxable
    @Default(true) bool taxable,
  }) = _PosLineItem;

  factory PosLineItem.fromJson(Map<String, dynamic> json) =>
      _$PosLineItemFromJson(json);

  const PosLineItem._();

  /// Unit price in dollars
  double get unitPriceDollars => unitPriceCents / 100.0;

  /// Total in dollars
  double get totalDollars => totalCents / 100.0;

  /// Discount in dollars
  double get discountDollars => discountCents / 100.0;

  /// Tax in dollars
  double get taxDollars => taxCents / 100.0;

  /// Subtotal before discount in cents
  int get subtotalCents => unitPriceCents * quantity;

  /// Subtotal before discount in dollars
  double get subtotalDollars => subtotalCents / 100.0;

  /// Whether a discount was applied
  bool get hasDiscount => discountCents > 0;
}

/// Split payment detail for multi-method transactions
@freezed
abstract class SplitPaymentDetail with _$SplitPaymentDetail {
  const factory SplitPaymentDetail({
    /// Payment method for this split
    required PosPaymentMethod method,

    /// Amount in cents for this split
    required int amountCents,

    /// Reference (card last 4, gift card code, etc.)
    String? reference,

    /// Stripe payment ID if card
    String? stripePaymentId,

    /// Gift card code if gift card
    String? giftCardCode,
  }) = _SplitPaymentDetail;

  factory SplitPaymentDetail.fromJson(Map<String, dynamic> json) =>
      _$SplitPaymentDetailFromJson(json);

  const SplitPaymentDetail._();

  /// Amount in dollars
  double get amountDollars => amountCents / 100.0;
}

/// POS transaction model for retail sales.
///
/// Transactions can be standalone retail sales or linked to appointments
/// (for add-on products sold during service).
@Freezed(toJson: true, fromJson: true)
abstract class PosTransaction with _$PosTransaction {
  const factory PosTransaction({
    /// Unique transaction ID
    required String id,

    /// Business ID
    required String businessId,

    /// Transaction date and time
    @TimestampConverter() required DateTime transactionDate,

    /// Staff ID who processed the sale
    required String staffId,

    /// Staff name (denormalized for display)
    String? staffName,

    /// Optional client ID (null for walk-in)
    String? clientId,

    /// Client name (denormalized for receipt)
    String? clientName,

    /// Optional linked appointment ID (if sold during appointment)
    String? appointmentId,

    /// Line items in this transaction
    required List<PosLineItem> lineItems,

    /// Subtotal in cents (sum of line item totals before tax)
    required int subtotalCents,

    /// Tax amount in cents
    required int taxCents,

    /// Tax rate applied (e.g., 0.0825 for 8.25%)
    @Default(0.0) double taxRate,

    /// Discount on entire transaction in cents
    @Default(0) int discountCents,

    /// Discount reason if applied
    String? discountReason,

    /// Total in cents (subtotal + tax - discount)
    required int totalCents,

    /// Primary payment method
    required PosPaymentMethod paymentMethod,

    /// Payment status
    required PaymentStatus paymentStatus,

    /// Stripe Payment Intent ID (if card payment)
    String? stripePaymentId,

    /// Gift card code (if gift card payment)
    String? giftCardCode,

    /// Split payment details (if split payment)
    @Default([]) List<SplitPaymentDetail> splitPayments,

    /// Cash tendered (for cash payments)
    int? cashTenderedCents,

    /// Change given (for cash payments)
    int? changeCents,

    /// Receipt number for customer reference
    String? receiptNumber,

    /// Receipt URL (PDF or email link)
    String? receiptUrl,

    /// Whether receipt was emailed to customer
    @Default(false) bool receiptEmailed,

    /// Internal notes about the transaction
    String? notes,

    /// Whether transaction was voided
    @Default(false) bool isVoided,

    /// Void reason if voided
    String? voidReason,

    /// When transaction was voided
    @NullableTimestampConverter() DateTime? voidedAt,

    /// Who voided the transaction
    String? voidedBy,

    /// When the transaction was created
    @TimestampConverter() required DateTime createdAt,

    /// When the transaction was last updated
    @NullableTimestampConverter() DateTime? updatedAt,
  }) = _PosTransaction;

  factory PosTransaction.fromJson(Map<String, dynamic> json) =>
      _$PosTransactionFromJson(json);

  const PosTransaction._();

  /// Subtotal in dollars
  double get subtotalDollars => subtotalCents / 100.0;

  /// Tax in dollars
  double get taxDollars => taxCents / 100.0;

  /// Discount in dollars
  double get discountDollars => discountCents / 100.0;

  /// Total in dollars
  double get totalDollars => totalCents / 100.0;

  /// Cash tendered in dollars
  double? get cashTenderedDollars =>
      cashTenderedCents != null ? cashTenderedCents! / 100.0 : null;

  /// Change in dollars
  double? get changeDollars =>
      changeCents != null ? changeCents! / 100.0 : null;

  /// Total number of items in transaction
  int get totalItemCount =>
      lineItems.fold(0, (sum, item) => sum + item.quantity);

  /// Whether this is a walk-in sale (no client)
  bool get isWalkIn => clientId == null;

  /// Whether this sale is linked to an appointment
  bool get isAppointmentSale => appointmentId != null;

  /// Whether payment is completed
  bool get isCompleted => paymentStatus == PaymentStatus.completed;

  /// Whether payment is pending
  bool get isPending => paymentStatus == PaymentStatus.pending;

  /// Whether transaction has a discount
  bool get hasDiscount => discountCents > 0;

  /// Whether transaction is a split payment
  bool get isSplitPayment => paymentMethod == PosPaymentMethod.split;

  /// Display string for payment method
  String get paymentMethodDisplay {
    if (isSplitPayment && splitPayments.isNotEmpty) {
      final methods = splitPayments.map((s) => s.method.displayName).toSet();
      return methods.join(' + ');
    }
    return paymentMethod.displayName;
  }

  /// Display string for payment status
  String get paymentStatusDisplay {
    switch (paymentStatus) {
      case PaymentStatus.none:
        return 'None';
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.completed:
        return 'Completed';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.refunded:
        return 'Refunded';
      case PaymentStatus.partiallyRefunded:
        return 'Partially Refunded';
    }
  }

  /// Formatted total display
  String get totalDisplay => '\$${totalDollars.toStringAsFixed(2)}';

  /// Formatted receipt number
  String get receiptDisplay => receiptNumber ?? id.substring(0, 8).toUpperCase();
}

/// Cart item for building a transaction
@freezed
abstract class CartItem with _$CartItem {
  const factory CartItem({
    /// Product ID
    required String productId,

    /// Product name
    required String productName,

    /// SKU
    String? sku,

    /// Unit price in cents
    required int unitPriceCents,

    /// Quantity in cart
    required int quantity,

    /// Whether item is taxable
    @Default(true) bool taxable,

    /// Optional discount in cents
    @Default(0) int discountCents,

    /// Discount reason
    String? discountReason,
  }) = _CartItem;

  factory CartItem.fromJson(Map<String, dynamic> json) =>
      _$CartItemFromJson(json);

  const CartItem._();

  /// Total for this cart item in cents
  int get totalCents => (unitPriceCents * quantity) - discountCents;

  /// Total in dollars
  double get totalDollars => totalCents / 100.0;

  /// Unit price in dollars
  double get unitPriceDollars => unitPriceCents / 100.0;

  /// Convert to line item (with tax calculation)
  PosLineItem toLineItem({int taxCents = 0}) {
    return PosLineItem(
      productId: productId,
      productName: productName,
      sku: sku,
      quantity: quantity,
      unitPriceCents: unitPriceCents,
      totalCents: totalCents,
      discountCents: discountCents,
      discountReason: discountReason,
      taxCents: taxCents,
      taxable: taxable,
    );
  }
}
