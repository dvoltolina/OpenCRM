import 'package:freezed_annotation/freezed_annotation.dart';

import '../converters/timestamp_converters.dart';

part 'gift_card_template.freezed.dart';
part 'gift_card_template.g.dart';

/// Gift card template for custom designs and configurations
@freezed
abstract class GiftCardTemplate with _$GiftCardTemplate {
  const factory GiftCardTemplate({
    /// Unique template ID
    required String id,

    /// Business ID this template belongs to
    required String businessId,

    /// Template display name
    required String name,

    /// Template description
    required String description,

    /// Template image URL
    required String imageUrl,

    /// Background color (hex string, e.g., "#FF5733")
    required String backgroundColor,

    /// Text color (hex string, e.g., "#FFFFFF")
    required String textColor,

    /// Preset amounts in cents (null = custom amounts allowed)
    List<int>? presetAmountsCents,

    /// Minimum allowed amount in cents
    int? minAmountCents,

    /// Maximum allowed amount in cents
    int? maxAmountCents,

    /// Number of days the gift card is valid (null = never expires)
    int? validityDays,

    /// Whether the template is active and available for selection
    @Default(true) bool isActive,

    /// When the template was created
    @TimestampConverter() required DateTime createdAt,
  }) = _GiftCardTemplate;

  factory GiftCardTemplate.fromJson(Map<String, dynamic> json) =>
      _$GiftCardTemplateFromJson(json);

  const GiftCardTemplate._();

  /// Preset amounts converted to dollars
  List<double> get presetAmountsDollars {
    if (presetAmountsCents == null) return [];
    return presetAmountsCents!.map((cents) => cents / 100.0).toList();
  }

  /// Minimum amount in dollars (null if no minimum)
  double? get minAmountDollars {
    if (minAmountCents == null) return null;
    return minAmountCents! / 100.0;
  }

  /// Maximum amount in dollars (null if no maximum)
  double? get maxAmountDollars {
    if (maxAmountCents == null) return null;
    return maxAmountCents! / 100.0;
  }

  /// Whether this template allows custom amounts
  bool get allowsCustomAmount {
    // If no preset amounts or min/max are set, custom is allowed
    return presetAmountsCents == null ||
        presetAmountsCents!.isEmpty ||
        minAmountCents != null ||
        maxAmountCents != null;
  }

  /// Whether the gift card never expires
  bool get neverExpires => validityDays == null;

  /// Calculate expiration date from a given purchase date
  DateTime? calculateExpirationDate(DateTime purchaseDate) {
    if (validityDays == null) return null;
    return purchaseDate.add(Duration(days: validityDays!));
  }

  /// Validate if an amount is within the allowed range
  bool isAmountValid(int amountCents) {
    if (minAmountCents != null && amountCents < minAmountCents!) {
      return false;
    }
    if (maxAmountCents != null && amountCents > maxAmountCents!) {
      return false;
    }
    return true;
  }
}
