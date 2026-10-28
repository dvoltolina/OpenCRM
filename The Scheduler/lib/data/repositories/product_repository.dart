import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/config/demo_config.dart';
import '../../core/services/demo_guard_service.dart';
import '../models/audit_log.dart';
import '../models/retail_product.dart';
import '../models/security_context.dart';
import 'audit_log_repository.dart';

/// Exception thrown by ProductRepository operations
class ProductException implements Exception {
  ProductException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => 'ProductException: $message${code != null ? ' ($code)' : ''}';
}

/// Repository for managing retail products per business.
///
/// All operations enforce multi-tenant isolation via [SecurityContext].
/// Operations are logged via [AuditLogRepository] for compliance.
class ProductRepository {
  ProductRepository({
    FirebaseFirestore? firestore,
    AuditLogRepository? auditLogRepository,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auditLogRepository = auditLogRepository ?? AuditLogRepository();

  final FirebaseFirestore _firestore;
  final AuditLogRepository _auditLogRepository;

  /// Default limit for list queries
  static const int defaultLimit = 100;

  CollectionReference<Map<String, dynamic>> _productsCollection(
    String businessId,
  ) {
    return _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('products');
  }

  // ============================================================
  // Product CRUD Operations
  // ============================================================

  /// Create a new product.
  Future<RetailProduct> createProduct({
    required SecurityContext context,
    required String name,
    required int priceCents,
    required ProductCategory category,
    String? description,
    String? sku,
    String? barcode,
    int? costCents,
    List<String>? tags,
    bool trackInventory = false,
    int? stockQuantity,
    int? lowStockThreshold,
    String? imageUrl,
    List<String>? additionalImages,
    bool taxable = true,
    String? taxCategoryId,
    String? linkedServiceId,
    int sortOrder = 0,
  }) async {
    if (DemoConfig.isDemoMode) {
      DemoGuardService.blockWrite('create product');
    }
    context.verifyBusinessAccess();
    context.verifyPaymentAccess();

    // Validate SKU uniqueness if provided
    if (sku != null && sku.isNotEmpty) {
      final existing = await _productsCollection(context.businessId)
          .where('sku', isEqualTo: sku)
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) {
        throw ProductException('SKU "$sku" already exists', code: 'DUPLICATE_SKU');
      }
    }

    // Validate barcode uniqueness if provided
    if (barcode != null && barcode.isNotEmpty) {
      final existing = await _productsCollection(context.businessId)
          .where('barcode', isEqualTo: barcode)
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) {
        throw ProductException(
          'Barcode "$barcode" already exists',
          code: 'DUPLICATE_BARCODE',
        );
      }
    }

    final now = DateTime.now();
    final docRef = _productsCollection(context.businessId).doc();

    final product = RetailProduct(
      id: docRef.id,
      businessId: context.businessId,
      name: name,
      description: description,
      sku: sku,
      barcode: barcode,
      priceCents: priceCents,
      costCents: costCents,
      category: category,
      tags: tags ?? [],
      trackInventory: trackInventory,
      stockQuantity: trackInventory ? (stockQuantity ?? 0) : null,
      lowStockThreshold: trackInventory ? lowStockThreshold : null,
      imageUrl: imageUrl,
      additionalImages: additionalImages ?? [],
      taxable: taxable,
      taxCategoryId: taxCategoryId,
      linkedServiceId: linkedServiceId,
      sortOrder: sortOrder,
      createdAt: now,
    );

    await docRef.set(product.toJson());

    _auditLogRepository.logEvent(AuditLogEntry(
      businessId: context.businessId,
      userId: context.userId,
      actionType: AuditActionType.phiWrite,
      entityType: 'RetailProduct',
      entityId: product.id,
      metadata: {
        'action': 'create',
        'name': name,
        'priceCents': priceCents,
        'category': category.name,
      },
    ));

    return product;
  }

  /// Get a product by ID.
  Future<RetailProduct?> getProduct(
    SecurityContext context,
    String productId,
  ) async {
    context.verifyBusinessAccess();

    final doc =
        await _productsCollection(context.businessId).doc(productId).get();

    if (!doc.exists) return null;

    return RetailProduct.fromJson(_decodeProductDoc(doc));
  }

  /// Get a product by SKU.
  Future<RetailProduct?> getProductBySku(
    SecurityContext context,
    String sku,
  ) async {
    context.verifyBusinessAccess();

    final snapshot = await _productsCollection(context.businessId)
        .where('sku', isEqualTo: sku)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    return RetailProduct.fromJson(_decodeProductDoc(snapshot.docs.first));
  }

  /// Get a product by barcode.
  Future<RetailProduct?> getProductByBarcode(
    SecurityContext context,
    String barcode,
  ) async {
    context.verifyBusinessAccess();

    final snapshot = await _productsCollection(context.businessId)
        .where('barcode', isEqualTo: barcode)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    return RetailProduct.fromJson(_decodeProductDoc(snapshot.docs.first));
  }

  /// Update a product.
  Future<RetailProduct> updateProduct({
    required SecurityContext context,
    required String productId,
    String? name,
    String? description,
    String? sku,
    String? barcode,
    int? priceCents,
    int? costCents,
    ProductCategory? category,
    List<String>? tags,
    bool? trackInventory,
    int? stockQuantity,
    int? lowStockThreshold,
    String? imageUrl,
    List<String>? additionalImages,
    bool? isActive,
    bool? availableForSale,
    bool? taxable,
    String? taxCategoryId,
    String? linkedServiceId,
    int? sortOrder,
  }) async {
    if (DemoConfig.isDemoMode) {
      DemoGuardService.blockWrite('update product');
    }
    context.verifyBusinessAccess();
    context.verifyPaymentAccess();

    final docRef = _productsCollection(context.businessId).doc(productId);
    final currentDoc = await docRef.get();

    if (!currentDoc.exists) {
      throw ProductException('Product not found', code: 'NOT_FOUND');
    }

    final currentProduct = RetailProduct.fromJson(_decodeProductDoc(currentDoc));

    // Validate SKU uniqueness if changing
    if (sku != null && sku != currentProduct.sku && sku.isNotEmpty) {
      final existing = await _productsCollection(context.businessId)
          .where('sku', isEqualTo: sku)
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) {
        throw ProductException('SKU "$sku" already exists', code: 'DUPLICATE_SKU');
      }
    }

    // Validate barcode uniqueness if changing
    if (barcode != null && barcode != currentProduct.barcode && barcode.isNotEmpty) {
      final existing = await _productsCollection(context.businessId)
          .where('barcode', isEqualTo: barcode)
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) {
        throw ProductException(
          'Barcode "$barcode" already exists',
          code: 'DUPLICATE_BARCODE',
        );
      }
    }

    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (name != null) updates['name'] = name;
    if (description != null) updates['description'] = description;
    if (sku != null) updates['sku'] = sku;
    if (barcode != null) updates['barcode'] = barcode;
    if (priceCents != null) updates['priceCents'] = priceCents;
    if (costCents != null) updates['costCents'] = costCents;
    if (category != null) updates['category'] = category.name;
    if (tags != null) updates['tags'] = tags;
    if (trackInventory != null) updates['trackInventory'] = trackInventory;
    if (stockQuantity != null) updates['stockQuantity'] = stockQuantity;
    if (lowStockThreshold != null) updates['lowStockThreshold'] = lowStockThreshold;
    if (imageUrl != null) updates['imageUrl'] = imageUrl;
    if (additionalImages != null) updates['additionalImages'] = additionalImages;
    if (isActive != null) updates['isActive'] = isActive;
    if (availableForSale != null) updates['availableForSale'] = availableForSale;
    if (taxable != null) updates['taxable'] = taxable;
    if (taxCategoryId != null) updates['taxCategoryId'] = taxCategoryId;
    if (linkedServiceId != null) updates['linkedServiceId'] = linkedServiceId;
    if (sortOrder != null) updates['sortOrder'] = sortOrder;

    await docRef.update(updates);

    _auditLogRepository.logEvent(AuditLogEntry(
      businessId: context.businessId,
      userId: context.userId,
      actionType: AuditActionType.phiWrite,
      entityType: 'RetailProduct',
      entityId: productId,
      metadata: {
        'action': 'update',
        'fieldsUpdated': updates.keys.where((k) => k != 'updatedAt').length,
      },
    ));

    final updatedDoc = await docRef.get();
    return RetailProduct.fromJson(_decodeProductDoc(updatedDoc));
  }

  /// Delete a product (soft delete by setting isActive = false).
  Future<void> deleteProduct({
    required SecurityContext context,
    required String productId,
  }) async {
    if (DemoConfig.isDemoMode) {
      DemoGuardService.blockWrite('delete product');
    }
    context.verifyBusinessAccess();
    context.verifyPaymentAccess();

    await _productsCollection(context.businessId).doc(productId).update({
      'isActive': false,
      'availableForSale': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    _auditLogRepository.logEvent(AuditLogEntry(
      businessId: context.businessId,
      userId: context.userId,
      actionType: AuditActionType.phiWrite,
      entityType: 'RetailProduct',
      entityId: productId,
      metadata: {'action': 'delete'},
    ));
  }

  // ============================================================
  // Inventory Operations
  // ============================================================

  /// Decrement stock quantity after a sale.
  Future<void> decrementStock({
    required SecurityContext context,
    required String productId,
    required int quantity,
  }) async {
    if (DemoConfig.isDemoMode) {
      DemoGuardService.blockWrite('decrement stock');
    }
    context.verifyBusinessAccess();

    final docRef = _productsCollection(context.businessId).doc(productId);

    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(docRef);
      if (!doc.exists) {
        throw ProductException('Product not found', code: 'NOT_FOUND');
      }

      final product = RetailProduct.fromJson(_decodeProductDoc(doc));
      if (!product.trackInventory) return;

      final currentStock = product.stockQuantity ?? 0;
      final newStock = currentStock - quantity;

      if (newStock < 0) {
        throw ProductException(
          'Insufficient stock: $currentStock available, $quantity requested',
          code: 'INSUFFICIENT_STOCK',
        );
      }

      transaction.update(docRef, {
        'stockQuantity': newStock,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    _auditLogRepository.logEvent(AuditLogEntry(
      businessId: context.businessId,
      userId: context.userId,
      actionType: AuditActionType.phiWrite,
      entityType: 'RetailProduct',
      entityId: productId,
      metadata: {'action': 'decrementStock', 'quantity': quantity},
    ));
  }

  /// Increment stock quantity (for restocking or returns).
  Future<void> incrementStock({
    required SecurityContext context,
    required String productId,
    required int quantity,
    String? reason,
  }) async {
    if (DemoConfig.isDemoMode) {
      DemoGuardService.blockWrite('increment stock');
    }
    context.verifyBusinessAccess();
    context.verifyPaymentAccess();

    final docRef = _productsCollection(context.businessId).doc(productId);

    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(docRef);
      if (!doc.exists) {
        throw ProductException('Product not found', code: 'NOT_FOUND');
      }

      final product = RetailProduct.fromJson(_decodeProductDoc(doc));
      if (!product.trackInventory) return;

      final currentStock = product.stockQuantity ?? 0;
      final newStock = currentStock + quantity;

      transaction.update(docRef, {
        'stockQuantity': newStock,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    _auditLogRepository.logEvent(AuditLogEntry(
      businessId: context.businessId,
      userId: context.userId,
      actionType: AuditActionType.phiWrite,
      entityType: 'RetailProduct',
      entityId: productId,
      metadata: {
        'action': 'incrementStock',
        'quantity': quantity,
        if (reason != null) 'reason': reason.length > 50 ? reason.substring(0, 50) : reason,
      },
    ));
  }

  /// Set stock quantity to a specific value (for inventory count).
  Future<void> setStockQuantity({
    required SecurityContext context,
    required String productId,
    required int quantity,
    String? reason,
  }) async {
    if (DemoConfig.isDemoMode) {
      DemoGuardService.blockWrite('set stock quantity');
    }
    context.verifyBusinessAccess();
    context.verifyPaymentAccess();

    await _productsCollection(context.businessId).doc(productId).update({
      'stockQuantity': quantity,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    _auditLogRepository.logEvent(AuditLogEntry(
      businessId: context.businessId,
      userId: context.userId,
      actionType: AuditActionType.phiWrite,
      entityType: 'RetailProduct',
      entityId: productId,
      metadata: {
        'action': 'setStock',
        'quantity': quantity,
        if (reason != null) 'reason': reason.length > 50 ? reason.substring(0, 50) : reason,
      },
    ));
  }

  // ============================================================
  // Query Operations
  // ============================================================

  /// Stream all active products for a business.
  Stream<List<RetailProduct>> watchProducts(
    SecurityContext context, {
    ProductCategory? category,
    bool? availableForSale,
    int limit = defaultLimit,
  }) {
    context.verifyBusinessAccess();

    Query<Map<String, dynamic>> query = _productsCollection(context.businessId)
        .where('isActive', isEqualTo: true)
        .orderBy('sortOrder')
        .orderBy('name');

    if (category != null) {
      query = query.where('category', isEqualTo: category.name);
    }

    if (availableForSale != null) {
      query = query.where('availableForSale', isEqualTo: availableForSale);
    }

    query = query.limit(limit);

    return query.snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => RetailProduct.fromJson(_decodeProductDoc(doc)))
              .toList(),
        );
  }

  /// Get all active products (one-time fetch).
  Future<List<RetailProduct>> getProducts(
    SecurityContext context, {
    ProductCategory? category,
    bool? availableForSale,
    int limit = defaultLimit,
  }) async {
    context.verifyBusinessAccess();

    Query<Map<String, dynamic>> query = _productsCollection(context.businessId)
        .where('isActive', isEqualTo: true)
        .orderBy('sortOrder')
        .orderBy('name');

    if (category != null) {
      query = query.where('category', isEqualTo: category.name);
    }

    if (availableForSale != null) {
      query = query.where('availableForSale', isEqualTo: availableForSale);
    }

    query = query.limit(limit);

    final snapshot = await query.get();

    _auditLogRepository.logEvent(AuditLogEntry(
      businessId: context.businessId,
      userId: context.userId,
      actionType: AuditActionType.phiReadList,
      entityType: 'RetailProduct',
      entityId: category?.name ?? 'all',
      metadata: {
        'source': 'getProducts',
        'resultCount': snapshot.docs.length,
        if (category != null) 'category': category.name,
      },
    ));

    return snapshot.docs
        .map((doc) => RetailProduct.fromJson(_decodeProductDoc(doc)))
        .toList();
  }

  /// Get products with low stock.
  Future<List<RetailProduct>> getLowStockProducts(
    SecurityContext context,
  ) async {
    context.verifyBusinessAccess();
    context.verifyPaymentAccess();

    final snapshot = await _productsCollection(context.businessId)
        .where('isActive', isEqualTo: true)
        .where('trackInventory', isEqualTo: true)
        .get();

    final products = snapshot.docs
        .map((doc) => RetailProduct.fromJson(_decodeProductDoc(doc)))
        .where((p) => p.isLowStock)
        .toList();

    _auditLogRepository.logEvent(AuditLogEntry(
      businessId: context.businessId,
      userId: context.userId,
      actionType: AuditActionType.phiReadList,
      entityType: 'RetailProduct',
      entityId: 'lowStock',
      metadata: {
        'source': 'getLowStockProducts',
        'resultCount': products.length,
      },
    ));

    return products;
  }

  /// Search products by name, SKU, or barcode.
  Future<List<RetailProduct>> searchProducts({
    required SecurityContext context,
    required String query,
    int limit = 20,
  }) async {
    context.verifyBusinessAccess();

    final normalizedQuery = query.toLowerCase().trim();
    if (normalizedQuery.isEmpty) return [];

    // First try exact SKU/barcode match
    final skuMatch = await getProductBySku(context, query);
    if (skuMatch != null) return [skuMatch];

    final barcodeMatch = await getProductByBarcode(context, query);
    if (barcodeMatch != null) return [barcodeMatch];

    // Fallback to name search (basic prefix match)
    // Note: For production, consider Algolia or similar for full-text search
    final snapshot = await _productsCollection(context.businessId)
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .startAt([normalizedQuery])
        .endAt(['$normalizedQuery\uf8ff'])
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => RetailProduct.fromJson(_decodeProductDoc(doc)))
        .toList();
  }

  /// Get product categories with counts.
  Future<Map<ProductCategory, int>> getCategoryCounts(
    SecurityContext context,
  ) async {
    context.verifyBusinessAccess();

    final snapshot = await _productsCollection(context.businessId)
        .where('isActive', isEqualTo: true)
        .get();

    final counts = <ProductCategory, int>{};
    for (final category in ProductCategory.values) {
      counts[category] = 0;
    }

    for (final doc in snapshot.docs) {
      final product = RetailProduct.fromJson(_decodeProductDoc(doc));
      counts[product.category] = (counts[product.category] ?? 0) + 1;
    }

    return counts;
  }

  // ============================================================
  // Helper Methods
  // ============================================================

  Map<String, dynamic> _decodeProductDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    if (data == null) return {'id': doc.id};

    final normalized = Map<String, dynamic>.from(data);

    void normalizeField(String key) {
      final value = normalized[key];
      if (value is Timestamp) {
        normalized[key] = value.toDate().toIso8601String();
      } else if (value is DateTime) {
        normalized[key] = value.toIso8601String();
      }
    }

    normalizeField('createdAt');
    normalizeField('updatedAt');

    return {'id': doc.id, ...normalized};
  }
}
