import 'package:freezed_annotation/freezed_annotation.dart';

import '../converters/timestamp_converters.dart';

part 'retail_product.freezed.dart';
part 'retail_product.g.dart';

/// Product categories for retail items
enum ProductCategory {
  @JsonValue('skincare')
  skincare,

  @JsonValue('haircare')
  haircare,

  @JsonValue('supplements')
  supplements,

  @JsonValue('equipment')
  equipment,

  @JsonValue('merchandise')
  merchandise,

  @JsonValue('consumables')
  consumables,

  @JsonValue('other')
  other,
}

/// Extension for ProductCategory display
extension ProductCategoryExtension on ProductCategory {
  String get displayName {
    switch (this) {
      case ProductCategory.skincare:
        return 'Skincare';
      case ProductCategory.haircare:
        return 'Haircare';
      case ProductCategory.supplements:
        return 'Supplements';
      case ProductCategory.equipment:
        return 'Equipment';
      case ProductCategory.merchandise:
        return 'Merchandise';
      case ProductCategory.consumables:
        return 'Consumables';
      case ProductCategory.other:
        return 'Other';
    }
  }
}

/// Retail product model for POS system.
///
/// Products can be sold standalone via the POS system or as add-ons
/// during appointment checkout.
@freezed
abstract class RetailProduct with _$RetailProduct {
  const factory RetailProduct({
    /// Unique product ID
    required String id,

    /// Business ID this product belongs to
    required String businessId,

    /// Product name
    required String name,

    /// Product description
    String? description,

    /// Stock Keeping Unit (SKU) for inventory management
    String? sku,

    /// Barcode (UPC/EAN) for scanner integration
    String? barcode,

    /// Price in cents
    required int priceCents,

    /// Cost in cents (for profit tracking)
    int? costCents,

    /// Product category
    required ProductCategory category,

    /// Tags for filtering/searching
    @Default([]) List<String> tags,

    /// Whether to track inventory levels
    @Default(false) bool trackInventory,

    /// Current stock quantity (when trackInventory is true)
    int? stockQuantity,

    /// Low stock threshold for alerts
    int? lowStockThreshold,

    /// Primary product image URL
    String? imageUrl,

    /// Additional product images
    @Default([]) List<String> additionalImages,

    /// Whether product is active (visible in system)
    @Default(true) bool isActive,

    /// Whether product is available for sale
    @Default(true) bool availableForSale,

    /// Whether product is taxable
    @Default(true) bool taxable,

    /// Tax category ID (for tax rate lookup)
    String? taxCategoryId,

    /// Optional: link to service ID if sold as add-on
    String? linkedServiceId,

    /// Sort order for display
    @Default(0) int sortOrder,

    /// When the product was created
    @TimestampConverter() required DateTime createdAt,

    /// When the product was last updated
    @NullableTimestampConverter() DateTime? updatedAt,
  }) = _RetailProduct;

  factory RetailProduct.fromJson(Map<String, dynamic> json) =>
      _$RetailProductFromJson(json);

  const RetailProduct._();

  /// Price in dollars
  double get priceDollars => priceCents / 100.0;

  /// Cost in dollars (null if not tracked)
  double? get costDollars => costCents != null ? costCents! / 100.0 : null;

  /// Profit margin in cents (null if cost not tracked)
  int? get profitMarginCents =>
      costCents != null ? priceCents - costCents! : null;

  /// Profit margin in dollars (null if cost not tracked)
  double? get profitMarginDollars =>
      profitMarginCents != null ? profitMarginCents! / 100.0 : null;

  /// Profit margin percentage (null if cost not tracked)
  double? get profitMarginPercent {
    if (costCents == null || costCents == 0) return null;
    return ((priceCents - costCents!) / priceCents) * 100;
  }

  /// Whether stock is low (below threshold)
  bool get isLowStock {
    if (!trackInventory) return false;
    if (stockQuantity == null || lowStockThreshold == null) return false;
    return stockQuantity! <= lowStockThreshold!;
  }

  /// Whether product is out of stock
  bool get isOutOfStock {
    if (!trackInventory) return false;
    return (stockQuantity ?? 0) <= 0;
  }

  /// Whether product can be sold (active, available, and in stock)
  bool get canBeSold {
    if (!isActive || !availableForSale) return false;
    if (trackInventory && isOutOfStock) return false;
    return true;
  }

  /// Display string for category
  String get categoryDisplay => category.displayName;

  /// Formatted price display
  String get priceDisplay => '\$${priceDollars.toStringAsFixed(2)}';

  /// Stock status display
  String get stockStatusDisplay {
    if (!trackInventory) return 'Not tracked';
    if (isOutOfStock) return 'Out of stock';
    if (isLowStock) return 'Low stock ($stockQuantity)';
    return 'In stock ($stockQuantity)';
  }
}
