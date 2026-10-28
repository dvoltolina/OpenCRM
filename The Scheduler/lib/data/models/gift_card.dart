import 'package:freezed_annotation/freezed_annotation.dart';

import '../converters/timestamp_converters.dart';

part 'gift_card.freezed.dart';
part 'gift_card.g.dart';

/// Gift card status
enum GiftCardStatus {
  @JsonValue('pending')
  pending, // Created but not paid

  @JsonValue('active')
  active, // Paid and redeemable

  @JsonValue('depleted')
  depleted, // Balance = 0

  @JsonValue('expired')
  expired, // Past expiration date

  @JsonValue('voided')
  voided, // Cancelled by admin
}

/// A record of a gift card redemption
@freezed
abstract class GiftCardRedemption with _$GiftCardRedemption {
  const factory GiftCardRedemption({
    /// Unique redemption ID
    required String id,

    /// Gift card ID this redemption belongs to
    required String giftCardId,

    /// Appointment ID this redemption was applied to
    required String appointmentId,

    /// Amount redeemed in cents
    required int amountCents,

    /// When the redemption occurred
    @TimestampConverter() required DateTime redeemedAt,

    /// Client ID who redeemed the gift card
    required String redeemedByClientId,
  }) = _GiftCardRedemption;

  factory GiftCardRedemption.fromJson(Map<String, dynamic> json) =>
      _$GiftCardRedemptionFromJson(json);

  const GiftCardRedemption._();

  /// Amount in dollars
  double get amountDollars => amountCents / 100.0;
}

/// Gift card model for digital gift cards
@freezed
abstract class GiftCard with _$GiftCard {
  const factory GiftCard({
    /// Unique gift card ID
    required String id,

    /// Business ID this gift card belongs to
    required String businessId,

    /// Unique redemption code (e.g., "GIFT-ABCD-1234")
    required String code,

    /// Original amount in cents
    required int originalAmountCents,

    /// Remaining balance in cents
    required int remainingBalanceCents,

    /// Currency code (default USD)
    @Default('usd') String currency,

    /// Gift card status
    required GiftCardStatus status,

    /// When the gift card was activated (payment completed)
    @NullableTimestampConverter() DateTime? activatedAt,

    /// When the gift card expires (null = never expires)
    @NullableTimestampConverter() DateTime? expiresAt,

    /// Purchaser email address
    required String purchaserEmail,

    /// Purchaser name (optional)
    String? purchaserName,

    /// When the gift card was purchased
    @TimestampConverter() required DateTime purchasedAt,

    /// Stripe payment ID
    String? paymentId,

    /// Recipient email address (for emailed cards)
    String? recipientEmail,

    /// Recipient name
    String? recipientName,

    /// Personal message from purchaser to recipient
    String? personalMessage,

    /// Whether the gift card email was delivered successfully
    @Default(false) bool delivered,

    /// When the gift card was created
    @TimestampConverter() required DateTime createdAt,

    /// When the gift card was last redeemed
    @NullableTimestampConverter() DateTime? lastRedeemedAt,

    /// List of redemptions against this gift card
    @Default([]) List<GiftCardRedemption> redemptions,

    /// Selected design template ID
    String? templateId,

    /// Custom image URL (overrides template)
    String? customImageUrl,
  }) = _GiftCard;

  factory GiftCard.fromJson(Map<String, dynamic> json) =>
      _$GiftCardFromJson(json);

  const GiftCard._();

  /// Whether the gift card is valid for redemption
  bool get isValid {
    if (status != GiftCardStatus.active) return false;
    if (expiresAt != null && expiresAt!.isBefore(DateTime.now())) return false;
    return true;
  }

  /// Whether the gift card has remaining balance
  bool get hasBalance => remainingBalanceCents > 0;

  /// Original amount in dollars
  double get originalAmountDollars => originalAmountCents / 100.0;

  /// Remaining balance in dollars
  double get remainingBalanceDollars => remainingBalanceCents / 100.0;

  /// Total amount redeemed in cents
  int get totalRedeemedCents => originalAmountCents - remainingBalanceCents;

  /// Total amount redeemed in dollars
  double get totalRedeemedDollars => totalRedeemedCents / 100.0;

  /// Whether the gift card is expired
  bool get isExpired {
    if (status == GiftCardStatus.expired) return true;
    if (expiresAt != null && expiresAt!.isBefore(DateTime.now())) return true;
    return false;
  }

  /// Whether the gift card is active and has balance
  bool get isRedeemable => isValid && hasBalance;

  /// Display string for status
  String get statusDisplay {
    switch (status) {
      case GiftCardStatus.pending:
        return 'Pending';
      case GiftCardStatus.active:
        return 'Active';
      case GiftCardStatus.depleted:
        return 'Depleted';
      case GiftCardStatus.expired:
        return 'Expired';
      case GiftCardStatus.voided:
        return 'Voided';
    }
  }
}
