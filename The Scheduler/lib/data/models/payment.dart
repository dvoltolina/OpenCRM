import 'package:freezed_annotation/freezed_annotation.dart';

import '../converters/timestamp_converters.dart';

part 'payment.freezed.dart';
part 'payment.g.dart';

/// Payment status for appointments
enum PaymentStatus {
  @JsonValue('none')
  none, // No payment required

  @JsonValue('pending')
  pending, // Payment initiated but not completed

  @JsonValue('completed')
  completed, // Payment successful

  @JsonValue('failed')
  failed, // Payment failed

  @JsonValue('refunded')
  refunded, // Payment refunded

  @JsonValue('partially_refunded')
  partiallyRefunded, // Partial refund issued
}

/// Payment type
enum PaymentType {
  @JsonValue('deposit')
  deposit, // Partial payment (deposit)

  @JsonValue('full')
  full, // Full payment

  @JsonValue('subscription')
  subscription, // Recurring subscription payment

  @JsonValue('reschedule_fee')
  rescheduleFee, // Late reschedule fee

  @JsonValue('cancellation_fee')
  cancellationFee, // Late cancellation/no-show fee

  @JsonValue('refund')
  refund, // Negative payment returned to customer
}

/// Payment information for an appointment
@freezed
abstract class Payment with _$Payment {
  const factory Payment({
    /// Unique payment ID
    required String id,

    /// Business ID
    required String businessId,

    /// Appointment ID this payment is for
    required String appointmentId,

    /// Client ID who made the payment
    required String clientId,

    /// Payment amount in cents (USD)
    required int amountCents,

    /// Currency code (default USD)
    @Default('USD') String currency,

    /// Payment status
    required PaymentStatus status,

    /// Payment type
    required PaymentType type,

    /// Stripe Payment Intent ID
    String? stripePaymentIntentId,

    /// Stripe Charge ID
    String? stripeChargeId,

    /// Stripe Refund ID (when money is returned)
    String? stripeRefundId,

    /// Last 4 digits of card used (if card payment)
    String? cardLast4,

    /// Card brand (visa, mastercard, etc.)
    String? cardBrand,

    /// Payment method description
    String? paymentMethodDescription,

    /// Date payment was created
    @TimestampConverter() required DateTime createdAt,

    /// Date payment was completed
    @NullableTimestampConverter() DateTime? completedAt,

    /// Date payment was refunded
    @NullableTimestampConverter() DateTime? refundedAt,

    /// Refund amount in cents (if refunded)
    int? refundAmountCents,

    /// Parent payment ID for related fees or refunds
    String? parentPaymentId,

    /// Audit reason/context for this payment (refund reason, etc.)
    String? reason,

    /// Error message if payment failed
    String? errorMessage,

    /// Notes about the payment
    String? notes,
  }) = _Payment;

  factory Payment.fromJson(Map<String, dynamic> json) =>
      _$PaymentFromJson(json);

  const Payment._();

  /// Amount in dollars
  double get amountDollars => amountCents / 100.0;

  /// Refund amount in dollars
  double get refundAmountDollars => (refundAmountCents ?? 0) / 100.0;

  /// Whether payment is completed
  bool get isCompleted => status == PaymentStatus.completed;

  /// Whether payment is pending
  bool get isPending => status == PaymentStatus.pending;

  /// Whether payment failed
  bool get isFailed => status == PaymentStatus.failed;

  /// Whether payment was refunded (fully or partially)
  bool get isRefunded =>
      status == PaymentStatus.refunded ||
      status == PaymentStatus.partiallyRefunded;

  /// Whether this payment represents a refund transaction
  bool get isRefund => type == PaymentType.refund;

  /// Whether this payment represents an operational fee (late reschedule/cancel)
  bool get isFee =>
      type == PaymentType.rescheduleFee || type == PaymentType.cancellationFee;

  /// Net amount after refunds in cents
  int get netAmountCents {
    if (refundAmountCents == null) return amountCents;
    return amountCents - refundAmountCents!;
  }

  /// Display string for payment method
  String get paymentMethodDisplay {
    if (cardBrand != null && cardLast4 != null) {
      return '${_formatCardBrand(cardBrand!)} ****$cardLast4';
    }
    return paymentMethodDescription ?? 'Unknown';
  }

  /// Format card brand for display
  String _formatCardBrand(String brand) {
    switch (brand.toLowerCase()) {
      case 'visa':
        return 'Visa';
      case 'mastercard':
        return 'Mastercard';
      case 'amex':
        return 'American Express';
      case 'discover':
        return 'Discover';
      default:
        return brand;
    }
  }
}
