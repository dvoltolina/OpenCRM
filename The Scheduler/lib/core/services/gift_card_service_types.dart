// Helper types and result classes for GiftCardService.
// Extracted to maintain file size limits.

import '../../data/models/gift_card.dart';

/// Result of initiating a gift card purchase.
///
/// Contains the pending gift card and the Stripe client secret
/// needed to present the payment sheet.
class GiftCardPurchaseResult {
  const GiftCardPurchaseResult({
    required this.giftCard,
    required this.clientSecret,
  });

  /// The pending gift card (status = pending until payment completes)
  final GiftCard giftCard;

  /// Stripe Payment Intent client secret for presenting payment sheet
  final String clientSecret;
}

/// Result of validating a gift card code for redemption.
///
/// Used in the booking flow to calculate how much can be applied.
class GiftCardRedemptionResult {
  const GiftCardRedemptionResult({
    required this.code,
    required this.amountCents,
    required this.remainingBalanceCents,
    required this.coversFullAmount,
    this.expiresAt,
  });

  /// The validated gift card code
  final String code;

  /// Amount in cents to be applied to the booking
  final int amountCents;

  /// Gift card balance remaining after this redemption
  final int remainingBalanceCents;

  /// Whether this covers the full booking amount
  final bool coversFullAmount;

  /// When the gift card expires (null = never)
  final DateTime? expiresAt;

  /// Amount in dollars
  double get amountDollars => amountCents / 100.0;

  /// Remaining balance in dollars
  double get remainingBalanceDollars => remainingBalanceCents / 100.0;
}

/// Result of a gift card validation check.
class GiftCardValidationResult {
  const GiftCardValidationResult({
    required this.valid,
    this.giftCard,
    this.error,
    this.errorCode,
  });

  factory GiftCardValidationResult.success(GiftCard giftCard) {
    return GiftCardValidationResult(
      valid: true,
      giftCard: giftCard,
    );
  }

  factory GiftCardValidationResult.failure(String error, {String? errorCode}) {
    return GiftCardValidationResult(
      valid: false,
      error: error,
      errorCode: errorCode,
    );
  }

  final bool valid;
  final GiftCard? giftCard;
  final String? error;
  final String? errorCode;
}

/// Sanitized gift card details for client display.
///
/// Hides internal IDs and sensitive data.
class GiftCardDetails {
  const GiftCardDetails({
    required this.code,
    required this.originalAmountCents,
    required this.remainingBalanceCents,
    required this.status,
    required this.isValid,
    this.expiresAt,
    this.purchaserName,
    this.recipientName,
    this.personalMessage,
    this.templateImageUrl,
  });

  final String code;
  final int originalAmountCents;
  final int remainingBalanceCents;
  final GiftCardStatus status;
  final bool isValid;
  final DateTime? expiresAt;
  final String? purchaserName;
  final String? recipientName;
  final String? personalMessage;
  final String? templateImageUrl;

  double get originalAmountDollars => originalAmountCents / 100.0;
  double get remainingBalanceDollars => remainingBalanceCents / 100.0;
}

/// Exception for gift card-specific errors from the service layer.
class GiftCardServiceException implements Exception {
  const GiftCardServiceException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() =>
      'GiftCardServiceException: $message${code != null ? ' ($code)' : ''}';
}
