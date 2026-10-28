import 'package:flutter_test/flutter_test.dart';
import 'package:the_scheduler/data/models/retail_product.dart';

void main() {
  group('RetailProduct Model', () {
    group('JSON Serialization', () {
      test('serializes to JSON and back', () {
        final product = RetailProduct(
          id: 'prod-123',
          businessId: 'biz-456',
          name: 'Organic Face Cream',
          description: 'A premium organic face cream',
          sku: 'SKU-001',
          barcode: '123456789012',
          priceCents: 2499,
          costCents: 1200,
          category: ProductCategory.skincare,
          tags: ['organic', 'premium'],
          trackInventory: true,
          stockQuantity: 50,
          lowStockThreshold: 10,
          imageUrl: 'https://example.com/cream.jpg',
          additionalImages: ['https://example.com/cream2.jpg'],
          isActive: true,
          availableForSale: true,
          taxable: true,
          taxCategoryId: 'tax-1',
          sortOrder: 1,
          createdAt: DateTime(2025, 1, 15, 10, 0),
          updatedAt: DateTime(2025, 1, 20, 15, 30),
        );

        final json = product.toJson();
        final restored = RetailProduct.fromJson(json);

        expect(restored.id, product.id);
        expect(restored.businessId, product.businessId);
        expect(restored.name, product.name);
        expect(restored.description, product.description);
        expect(restored.sku, product.sku);
        expect(restored.barcode, product.barcode);
        expect(restored.priceCents, product.priceCents);
        expect(restored.costCents, product.costCents);
        expect(restored.category, product.category);
        expect(restored.tags, product.tags);
        expect(restored.trackInventory, product.trackInventory);
        expect(restored.stockQuantity, product.stockQuantity);
        expect(restored.lowStockThreshold, product.lowStockThreshold);
        expect(restored.imageUrl, product.imageUrl);
        expect(restored.additionalImages, product.additionalImages);
        expect(restored.isActive, product.isActive);
        expect(restored.availableForSale, product.availableForSale);
        expect(restored.taxable, product.taxable);
        expect(restored.taxCategoryId, product.taxCategoryId);
        expect(restored.sortOrder, product.sortOrder);
      });

      test('handles null optional fields', () {
        final product = RetailProduct(
          id: 'prod-123',
          businessId: 'biz-456',
          name: 'Simple Product',
          priceCents: 999,
          category: ProductCategory.other,
          createdAt: DateTime(2025, 1, 15),
        );

        final json = product.toJson();
        final restored = RetailProduct.fromJson(json);

        expect(restored.description, isNull);
        expect(restored.sku, isNull);
        expect(restored.barcode, isNull);
        expect(restored.costCents, isNull);
        expect(restored.stockQuantity, isNull);
        expect(restored.lowStockThreshold, isNull);
        expect(restored.imageUrl, isNull);
        expect(restored.taxCategoryId, isNull);
        expect(restored.updatedAt, isNull);
      });

      test('handles all category values', () {
        for (final category in ProductCategory.values) {
          final product = RetailProduct(
            id: 'prod-123',
            businessId: 'biz-456',
            name: 'Test Product',
            priceCents: 999,
            category: category,
            createdAt: DateTime(2025, 1, 15),
          );

          final json = product.toJson();
          final restored = RetailProduct.fromJson(json);

          expect(restored.category, category);
        }
      });
    });

    group('Helper Getters', () {
      test('priceDollars converts cents to dollars', () {
        final product = _createProduct(priceCents: 2499);
        expect(product.priceDollars, 24.99);
      });

      test('costDollars converts cents to dollars', () {
        final product = _createProduct(costCents: 1200);
        expect(product.costDollars, 12.0);
      });

      test('costDollars returns null when cost not tracked', () {
        final product = _createProduct();
        expect(product.costDollars, isNull);
      });

      test('profitMarginCents calculates correctly', () {
        final product = _createProduct(priceCents: 2500, costCents: 1000);
        expect(product.profitMarginCents, 1500);
      });

      test('profitMarginCents returns null when cost not tracked', () {
        final product = _createProduct(priceCents: 2500);
        expect(product.profitMarginCents, isNull);
      });

      test('profitMarginDollars converts correctly', () {
        final product = _createProduct(priceCents: 2500, costCents: 1000);
        expect(product.profitMarginDollars, 15.0);
      });

      test('profitMarginPercent calculates correctly', () {
        final product = _createProduct(priceCents: 10000, costCents: 6000);
        expect(product.profitMarginPercent, 40.0);
      });

      test('profitMarginPercent returns null when cost not tracked', () {
        final product = _createProduct();
        expect(product.profitMarginPercent, isNull);
      });
    });

    group('Stock Status', () {
      test('isLowStock returns true when below threshold', () {
        final product = _createProduct(
          trackInventory: true,
          stockQuantity: 5,
          lowStockThreshold: 10,
        );
        expect(product.isLowStock, isTrue);
      });

      test('isLowStock returns true when equal to threshold', () {
        final product = _createProduct(
          trackInventory: true,
          stockQuantity: 10,
          lowStockThreshold: 10,
        );
        expect(product.isLowStock, isTrue);
      });

      test('isLowStock returns false when above threshold', () {
        final product = _createProduct(
          trackInventory: true,
          stockQuantity: 50,
          lowStockThreshold: 10,
        );
        expect(product.isLowStock, isFalse);
      });

      test('isLowStock returns false when not tracking inventory', () {
        final product = _createProduct(
          trackInventory: false,
          stockQuantity: 5,
          lowStockThreshold: 10,
        );
        expect(product.isLowStock, isFalse);
      });

      test('isOutOfStock returns true when quantity is zero', () {
        final product = _createProduct(
          trackInventory: true,
          stockQuantity: 0,
        );
        expect(product.isOutOfStock, isTrue);
      });

      test('isOutOfStock returns true when quantity is negative', () {
        final product = _createProduct(
          trackInventory: true,
          stockQuantity: -1,
        );
        expect(product.isOutOfStock, isTrue);
      });

      test('isOutOfStock returns false when in stock', () {
        final product = _createProduct(
          trackInventory: true,
          stockQuantity: 10,
        );
        expect(product.isOutOfStock, isFalse);
      });

      test('isOutOfStock returns false when not tracking inventory', () {
        final product = _createProduct(
          trackInventory: false,
          stockQuantity: 0,
        );
        expect(product.isOutOfStock, isFalse);
      });
    });

    group('canBeSold', () {
      test('returns true for active, available, in-stock product', () {
        final product = _createProduct(
          isActive: true,
          availableForSale: true,
          trackInventory: true,
          stockQuantity: 10,
        );
        expect(product.canBeSold, isTrue);
      });

      test('returns true when not tracking inventory', () {
        final product = _createProduct(
          isActive: true,
          availableForSale: true,
          trackInventory: false,
        );
        expect(product.canBeSold, isTrue);
      });

      test('returns false when not active', () {
        final product = _createProduct(
          isActive: false,
          availableForSale: true,
        );
        expect(product.canBeSold, isFalse);
      });

      test('returns false when not available for sale', () {
        final product = _createProduct(
          isActive: true,
          availableForSale: false,
        );
        expect(product.canBeSold, isFalse);
      });

      test('returns false when out of stock', () {
        final product = _createProduct(
          isActive: true,
          availableForSale: true,
          trackInventory: true,
          stockQuantity: 0,
        );
        expect(product.canBeSold, isFalse);
      });
    });

    group('Display Helpers', () {
      test('categoryDisplay returns correct string', () {
        expect(ProductCategory.skincare.displayName, 'Skincare');
        expect(ProductCategory.haircare.displayName, 'Haircare');
        expect(ProductCategory.supplements.displayName, 'Supplements');
        expect(ProductCategory.equipment.displayName, 'Equipment');
        expect(ProductCategory.merchandise.displayName, 'Merchandise');
        expect(ProductCategory.consumables.displayName, 'Consumables');
        expect(ProductCategory.other.displayName, 'Other');
      });

      test('priceDisplay formats correctly', () {
        final product = _createProduct(priceCents: 2499);
        expect(product.priceDisplay, '\$24.99');
      });

      test('priceDisplay handles round dollars', () {
        final product = _createProduct(priceCents: 1000);
        expect(product.priceDisplay, '\$10.00');
      });

      test('stockStatusDisplay shows not tracked', () {
        final product = _createProduct(trackInventory: false);
        expect(product.stockStatusDisplay, 'Not tracked');
      });

      test('stockStatusDisplay shows out of stock', () {
        final product = _createProduct(
          trackInventory: true,
          stockQuantity: 0,
        );
        expect(product.stockStatusDisplay, 'Out of stock');
      });

      test('stockStatusDisplay shows low stock', () {
        final product = _createProduct(
          trackInventory: true,
          stockQuantity: 5,
          lowStockThreshold: 10,
        );
        expect(product.stockStatusDisplay, 'Low stock (5)');
      });

      test('stockStatusDisplay shows in stock', () {
        final product = _createProduct(
          trackInventory: true,
          stockQuantity: 50,
          lowStockThreshold: 10,
        );
        expect(product.stockStatusDisplay, 'In stock (50)');
      });
    });
  });
}

/// Helper function to create a test product with sensible defaults
RetailProduct _createProduct({
  String id = 'prod-123',
  String businessId = 'biz-456',
  String name = 'Test Product',
  int priceCents = 999,
  int? costCents,
  ProductCategory category = ProductCategory.other,
  bool trackInventory = false,
  int? stockQuantity,
  int? lowStockThreshold,
  bool isActive = true,
  bool availableForSale = true,
}) {
  return RetailProduct(
    id: id,
    businessId: businessId,
    name: name,
    priceCents: priceCents,
    costCents: costCents,
    category: category,
    trackInventory: trackInventory,
    stockQuantity: stockQuantity,
    lowStockThreshold: lowStockThreshold,
    isActive: isActive,
    availableForSale: availableForSale,
    createdAt: DateTime(2025, 1, 15),
  );
}
