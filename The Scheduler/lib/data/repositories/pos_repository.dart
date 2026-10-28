import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../core/config/demo_config.dart';
import '../../core/services/demo_guard_service.dart';
import '../models/audit_log.dart';
import '../models/payment.dart';
import '../models/pos_transaction.dart';
import '../models/security_context.dart';
import 'audit_log_repository.dart';

/// Exception thrown by PosRepository operations
class PosException implements Exception {
  PosException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => 'PosException: $message${code != null ? ' ($code)' : ''}';
}

/// Repository for managing POS transactions per business.
///
/// All operations enforce multi-tenant isolation via [SecurityContext].
/// Operations are logged via [AuditLogRepository] for compliance.
class PosRepository {
  PosRepository({
    FirebaseFirestore? firestore,
    AuditLogRepository? auditLogRepository,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auditLogRepository = auditLogRepository ?? AuditLogRepository();

  final FirebaseFirestore _firestore;
  final AuditLogRepository _auditLogRepository;
  final _uuid = const Uuid();

  /// Default limit for list queries
  static const int defaultLimit = 50;

  CollectionReference<Map<String, dynamic>> _transactionsCollection(
    String businessId,
  ) {
    return _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('posTransactions');
  }

  // ============================================================
  // Transaction CRUD Operations
  // ============================================================

  /// Create a new POS transaction.
  Future<PosTransaction> createTransaction({
    required SecurityContext context,
    required List<PosLineItem> lineItems,
    required int subtotalCents,
    required int taxCents,
    required int totalCents,
    required PosPaymentMethod paymentMethod,
    double taxRate = 0.0,
    String? clientId,
    String? clientName,
    String? appointmentId,
    int discountCents = 0,
    String? discountReason,
    String? notes,
  }) async {
    if (DemoConfig.isDemoMode) {
      DemoGuardService.blockWrite('create POS transaction');
    }
    context.verifyBusinessAccess();

    final now = DateTime.now();
    final docRef = _transactionsCollection(context.businessId).doc();
    final receiptNumber = _generateReceiptNumber(now);

    final transaction = PosTransaction(
      id: docRef.id,
      businessId: context.businessId,
      transactionDate: now,
      staffId: context.userId,
      staffName: context.userFullName,
      clientId: clientId,
      clientName: clientName,
      appointmentId: appointmentId,
      lineItems: lineItems,
      subtotalCents: subtotalCents,
      taxCents: taxCents,
      taxRate: taxRate,
      discountCents: discountCents,
      discountReason: discountReason,
      totalCents: totalCents,
      paymentMethod: paymentMethod,
      paymentStatus: PaymentStatus.pending,
      receiptNumber: receiptNumber,
      notes: notes,
      createdAt: now,
    );

    await docRef.set(_encodeTransaction(transaction));

    _auditLogRepository.logEvent(AuditLogEntry(
      businessId: context.businessId,
      userId: context.userId,
      actionType: AuditActionType.phiWrite,
      entityType: 'PosTransaction',
      entityId: transaction.id,
      metadata: {
        'action': 'create',
        'totalCents': totalCents,
        'itemCount': lineItems.length,
        'paymentMethod': paymentMethod.name,
        if (clientId != null) 'clientId': clientId,
        if (appointmentId != null) 'appointmentId': appointmentId,
      },
    ));

    return transaction;
  }

  /// Get a transaction by ID.
  Future<PosTransaction?> getTransaction(
    SecurityContext context,
    String transactionId,
  ) async {
    context.verifyBusinessAccess();

    final doc = await _transactionsCollection(context.businessId)
        .doc(transactionId)
        .get();

    if (!doc.exists) return null;

    _auditLogRepository.logEvent(AuditLogEntry(
      businessId: context.businessId,
      userId: context.userId,
      actionType: AuditActionType.phiRead,
      entityType: 'PosTransaction',
      entityId: transactionId,
      metadata: {'source': 'getTransaction'},
    ));

    return PosTransaction.fromJson(_decodeTransactionDoc(doc));
  }

  /// Get a transaction by receipt number.
  Future<PosTransaction?> getTransactionByReceipt(
    SecurityContext context,
    String receiptNumber,
  ) async {
    context.verifyBusinessAccess();

    final snapshot = await _transactionsCollection(context.businessId)
        .where('receiptNumber', isEqualTo: receiptNumber)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    _auditLogRepository.logEvent(AuditLogEntry(
      businessId: context.businessId,
      userId: context.userId,
      actionType: AuditActionType.phiRead,
      entityType: 'PosTransaction',
      entityId: snapshot.docs.first.id,
      metadata: {'source': 'getTransactionByReceipt'},
    ));

    return PosTransaction.fromJson(_decodeTransactionDoc(snapshot.docs.first));
  }

  /// Update payment status for a transaction.
  Future<PosTransaction> updatePaymentStatus({
    required SecurityContext context,
    required String transactionId,
    required PaymentStatus status,
    String? stripePaymentId,
    String? giftCardCode,
    List<SplitPaymentDetail>? splitPayments,
    int? cashTenderedCents,
    int? changeCents,
  }) async {
    if (DemoConfig.isDemoMode) {
      DemoGuardService.blockWrite('update POS payment');
    }
    context.verifyBusinessAccess();

    final docRef =
        _transactionsCollection(context.businessId).doc(transactionId);

    final updates = <String, dynamic>{
      'paymentStatus': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (stripePaymentId != null) updates['stripePaymentId'] = stripePaymentId;
    if (giftCardCode != null) updates['giftCardCode'] = giftCardCode;
    if (splitPayments != null) {
      updates['splitPayments'] = splitPayments.map((s) => s.toJson()).toList();
    }
    if (cashTenderedCents != null) {
      updates['cashTenderedCents'] = cashTenderedCents;
    }
    if (changeCents != null) updates['changeCents'] = changeCents;

    await docRef.update(updates);

    _auditLogRepository.logEvent(AuditLogEntry(
      businessId: context.businessId,
      userId: context.userId,
      actionType: AuditActionType.phiWrite,
      entityType: 'PosTransaction',
      entityId: transactionId,
      metadata: {
        'action': 'updatePaymentStatus',
        'newStatus': status.name,
        if (stripePaymentId != null) 'stripePaymentId': stripePaymentId,
      },
    ));

    final updatedDoc = await docRef.get();
    return PosTransaction.fromJson(_decodeTransactionDoc(updatedDoc));
  }

  /// Void a transaction (admin operation).
  Future<PosTransaction> voidTransaction({
    required SecurityContext context,
    required String transactionId,
    required String reason,
  }) async {
    if (DemoConfig.isDemoMode) {
      DemoGuardService.blockWrite('void POS transaction');
    }
    context.verifyBusinessAccess();
    context.verifyPaymentAccess();

    final docRef =
        _transactionsCollection(context.businessId).doc(transactionId);
    final now = DateTime.now();

    await docRef.update({
      'isVoided': true,
      'voidReason': reason,
      'voidedAt': Timestamp.fromDate(now),
      'voidedBy': context.userId,
      'paymentStatus': PaymentStatus.refunded.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    _auditLogRepository.logEvent(AuditLogEntry(
      businessId: context.businessId,
      userId: context.userId,
      actionType: AuditActionType.phiWrite,
      entityType: 'PosTransaction',
      entityId: transactionId,
      metadata: {
        'action': 'void',
        'reason': reason.length > 50 ? reason.substring(0, 50) : reason,
      },
    ));

    final updatedDoc = await docRef.get();
    return PosTransaction.fromJson(_decodeTransactionDoc(updatedDoc));
  }

  /// Update receipt URL after generation.
  Future<void> updateReceiptUrl({
    required SecurityContext context,
    required String transactionId,
    required String receiptUrl,
  }) async {
    if (DemoConfig.isDemoMode) {
      DemoGuardService.blockWrite('update receipt', showMessage: false);
    }
    context.verifyBusinessAccess();

    await _transactionsCollection(context.businessId)
        .doc(transactionId)
        .update({
      'receiptUrl': receiptUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Mark receipt as emailed.
  Future<void> markReceiptEmailed({
    required SecurityContext context,
    required String transactionId,
  }) async {
    if (DemoConfig.isDemoMode) {
      DemoGuardService.blockWrite('mark receipt emailed', showMessage: false);
    }
    context.verifyBusinessAccess();

    await _transactionsCollection(context.businessId)
        .doc(transactionId)
        .update({
      'receiptEmailed': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // Query Operations
  // ============================================================

  /// Stream transactions for a business.
  Stream<List<PosTransaction>> watchTransactions(
    SecurityContext context, {
    DateTime? startDate,
    DateTime? endDate,
    String? staffId,
    PaymentStatus? status,
    int limit = defaultLimit,
  }) {
    context.verifyBusinessAccess();
    context.verifyPaymentAccess();

    Query<Map<String, dynamic>> query =
        _transactionsCollection(context.businessId)
            .orderBy('transactionDate', descending: true);

    if (startDate != null) {
      query = query.where(
        'transactionDate',
        isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
      );
    }

    if (endDate != null) {
      query = query.where(
        'transactionDate',
        isLessThanOrEqualTo: Timestamp.fromDate(endDate),
      );
    }

    if (staffId != null) {
      query = query.where('staffId', isEqualTo: staffId);
    }

    if (status != null) {
      query = query.where('paymentStatus', isEqualTo: status.name);
    }

    query = query.limit(limit);

    return query.snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => PosTransaction.fromJson(_decodeTransactionDoc(doc)))
              .toList(),
        );
  }

  /// Get transactions for a date range (one-time fetch).
  Future<List<PosTransaction>> getTransactions(
    SecurityContext context, {
    DateTime? startDate,
    DateTime? endDate,
    String? staffId,
    String? clientId,
    PaymentStatus? status,
    bool excludeVoided = true,
    int limit = defaultLimit,
  }) async {
    context.verifyBusinessAccess();
    context.verifyPaymentAccess();

    Query<Map<String, dynamic>> query =
        _transactionsCollection(context.businessId)
            .orderBy('transactionDate', descending: true);

    if (startDate != null) {
      query = query.where(
        'transactionDate',
        isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
      );
    }

    if (endDate != null) {
      query = query.where(
        'transactionDate',
        isLessThanOrEqualTo: Timestamp.fromDate(endDate),
      );
    }

    if (staffId != null) {
      query = query.where('staffId', isEqualTo: staffId);
    }

    if (clientId != null) {
      query = query.where('clientId', isEqualTo: clientId);
    }

    if (status != null) {
      query = query.where('paymentStatus', isEqualTo: status.name);
    }

    if (excludeVoided) {
      query = query.where('isVoided', isEqualTo: false);
    }

    query = query.limit(limit);

    final snapshot = await query.get();

    _auditLogRepository.logEvent(AuditLogEntry(
      businessId: context.businessId,
      userId: context.userId,
      actionType: AuditActionType.phiReadList,
      entityType: 'PosTransaction',
      entityId: 'query',
      metadata: {
        'source': 'getTransactions',
        'resultCount': snapshot.docs.length,
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
      },
    ));

    return snapshot.docs
        .map((doc) => PosTransaction.fromJson(_decodeTransactionDoc(doc)))
        .toList();
  }

  /// Get transactions for a specific client.
  Future<List<PosTransaction>> getTransactionsForClient(
    SecurityContext context,
    String clientId, {
    int limit = defaultLimit,
  }) async {
    context.verifyBusinessAccess();

    final snapshot = await _transactionsCollection(context.businessId)
        .where('clientId', isEqualTo: clientId)
        .where('isVoided', isEqualTo: false)
        .orderBy('transactionDate', descending: true)
        .limit(limit)
        .get();

    _auditLogRepository.logEvent(AuditLogEntry(
      businessId: context.businessId,
      userId: context.userId,
      actionType: AuditActionType.phiReadList,
      entityType: 'PosTransaction',
      entityId: clientId,
      metadata: {
        'source': 'getTransactionsForClient',
        'resultCount': snapshot.docs.length,
      },
    ));

    return snapshot.docs
        .map((doc) => PosTransaction.fromJson(_decodeTransactionDoc(doc)))
        .toList();
  }

  /// Get transactions for a specific appointment.
  Future<List<PosTransaction>> getTransactionsForAppointment(
    SecurityContext context,
    String appointmentId,
  ) async {
    context.verifyBusinessAccess();

    final snapshot = await _transactionsCollection(context.businessId)
        .where('appointmentId', isEqualTo: appointmentId)
        .where('isVoided', isEqualTo: false)
        .orderBy('transactionDate', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => PosTransaction.fromJson(_decodeTransactionDoc(doc)))
        .toList();
  }

  // ============================================================
  // Analytics Operations
  // ============================================================

  /// Get sales statistics for a date range.
  Future<PosSalesStats> getSalesStats(
    SecurityContext context, {
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    context.verifyBusinessAccess();
    context.verifyPaymentAccess();

    final snapshot = await _transactionsCollection(context.businessId)
        .where('transactionDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('transactionDate',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .where('paymentStatus', isEqualTo: PaymentStatus.completed.name)
        .where('isVoided', isEqualTo: false)
        .get();

    int totalSalesCents = 0;
    int totalTaxCents = 0;
    int totalDiscountCents = 0;
    int transactionCount = 0;
    int itemCount = 0;
    final paymentMethodCounts = <PosPaymentMethod, int>{};
    final hourlySales = <int, int>{};

    for (final doc in snapshot.docs) {
      final transaction =
          PosTransaction.fromJson(_decodeTransactionDoc(doc));

      totalSalesCents += transaction.totalCents;
      totalTaxCents += transaction.taxCents;
      totalDiscountCents += transaction.discountCents;
      transactionCount++;
      itemCount += transaction.totalItemCount;

      paymentMethodCounts[transaction.paymentMethod] =
          (paymentMethodCounts[transaction.paymentMethod] ?? 0) + 1;

      final hour = transaction.transactionDate.hour;
      hourlySales[hour] = (hourlySales[hour] ?? 0) + transaction.totalCents;
    }

    _auditLogRepository.logEvent(AuditLogEntry(
      businessId: context.businessId,
      userId: context.userId,
      actionType: AuditActionType.phiReadList,
      entityType: 'PosTransaction',
      entityId: 'salesStats',
      metadata: {
        'source': 'getSalesStats',
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'transactionCount': transactionCount,
      },
    ));

    return PosSalesStats(
      totalSalesCents: totalSalesCents,
      totalTaxCents: totalTaxCents,
      totalDiscountCents: totalDiscountCents,
      transactionCount: transactionCount,
      itemCount: itemCount,
      averageTransactionCents:
          transactionCount > 0 ? totalSalesCents ~/ transactionCount : 0,
      paymentMethodCounts: paymentMethodCounts,
      hourlySales: hourlySales,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Get top selling products for a date range.
  Future<List<ProductSalesData>> getTopSellingProducts(
    SecurityContext context, {
    required DateTime startDate,
    required DateTime endDate,
    int limit = 10,
  }) async {
    context.verifyBusinessAccess();
    context.verifyPaymentAccess();

    final snapshot = await _transactionsCollection(context.businessId)
        .where('transactionDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('transactionDate',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .where('paymentStatus', isEqualTo: PaymentStatus.completed.name)
        .where('isVoided', isEqualTo: false)
        .get();

    final productSales = <String, ProductSalesData>{};

    for (final doc in snapshot.docs) {
      final transaction =
          PosTransaction.fromJson(_decodeTransactionDoc(doc));

      for (final item in transaction.lineItems) {
        final existing = productSales[item.productId];
        if (existing != null) {
          productSales[item.productId] = ProductSalesData(
            productId: item.productId,
            productName: item.productName,
            quantitySold: existing.quantitySold + item.quantity,
            totalRevenueCents: existing.totalRevenueCents + item.totalCents,
          );
        } else {
          productSales[item.productId] = ProductSalesData(
            productId: item.productId,
            productName: item.productName,
            quantitySold: item.quantity,
            totalRevenueCents: item.totalCents,
          );
        }
      }
    }

    final sorted = productSales.values.toList()
      ..sort((a, b) => b.totalRevenueCents.compareTo(a.totalRevenueCents));

    return sorted.take(limit).toList();
  }

  // ============================================================
  // Helper Methods
  // ============================================================

  String _generateReceiptNumber(DateTime date) {
    final datePrefix =
        '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
    final randomSuffix = _uuid.v4().substring(0, 4).toUpperCase();
    return 'POS-$datePrefix-$randomSuffix';
  }

  Map<String, dynamic> _encodeTransaction(PosTransaction transaction) {
    final json = transaction.toJson();

    // Convert DateTime fields to Timestamp for Firestore
    if (json['transactionDate'] != null) {
      json['transactionDate'] = Timestamp.fromDate(transaction.transactionDate);
    }
    if (json['createdAt'] != null) {
      json['createdAt'] = Timestamp.fromDate(transaction.createdAt);
    }
    if (transaction.updatedAt != null) {
      json['updatedAt'] = Timestamp.fromDate(transaction.updatedAt!);
    }
    if (transaction.voidedAt != null) {
      json['voidedAt'] = Timestamp.fromDate(transaction.voidedAt!);
    }

    return json;
  }

  Map<String, dynamic> _decodeTransactionDoc(
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

    normalizeField('transactionDate');
    normalizeField('createdAt');
    normalizeField('updatedAt');
    normalizeField('voidedAt');

    // Handle lineItems list
    if (normalized['lineItems'] is List) {
      normalized['lineItems'] = (normalized['lineItems'] as List)
          .map((item) {
            if (item is Map<String, dynamic>) {
              return Map<String, dynamic>.from(item);
            }
            return item;
          })
          .toList();
    }

    // Handle splitPayments list
    if (normalized['splitPayments'] is List) {
      normalized['splitPayments'] = (normalized['splitPayments'] as List)
          .map((item) {
            if (item is Map<String, dynamic>) {
              return Map<String, dynamic>.from(item);
            }
            return item;
          })
          .toList();
    }

    return {'id': doc.id, ...normalized};
  }
}

/// Sales statistics for POS transactions.
class PosSalesStats {
  PosSalesStats({
    required this.totalSalesCents,
    required this.totalTaxCents,
    required this.totalDiscountCents,
    required this.transactionCount,
    required this.itemCount,
    required this.averageTransactionCents,
    required this.paymentMethodCounts,
    required this.hourlySales,
    required this.startDate,
    required this.endDate,
  });

  final int totalSalesCents;
  final int totalTaxCents;
  final int totalDiscountCents;
  final int transactionCount;
  final int itemCount;
  final int averageTransactionCents;
  final Map<PosPaymentMethod, int> paymentMethodCounts;
  final Map<int, int> hourlySales;
  final DateTime startDate;
  final DateTime endDate;

  double get totalSalesDollars => totalSalesCents / 100.0;
  double get totalTaxDollars => totalTaxCents / 100.0;
  double get totalDiscountDollars => totalDiscountCents / 100.0;
  double get averageTransactionDollars => averageTransactionCents / 100.0;
}

/// Sales data for a single product.
class ProductSalesData {
  ProductSalesData({
    required this.productId,
    required this.productName,
    required this.quantitySold,
    required this.totalRevenueCents,
  });

  final String productId;
  final String productName;
  final int quantitySold;
  final int totalRevenueCents;

  double get totalRevenueDollars => totalRevenueCents / 100.0;
}
