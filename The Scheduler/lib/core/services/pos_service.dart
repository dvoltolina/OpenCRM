import 'dart:developer' as developer;

import '../config/app_config.dart';
import '../../data/models/audit_log.dart';
import '../../data/models/payment.dart';
import '../../data/models/pos_transaction.dart';
import '../../data/models/retail_product.dart';
import '../../data/models/security_context.dart';
import '../../data/repositories/audit_log_repository.dart';
import '../../data/repositories/gift_card_repository.dart';
import '../../data/repositories/pos_repository.dart';
import '../../data/repositories/product_repository.dart';
import 'stripe_service.dart';

// ============================================================
// POS Service Types
// ============================================================

/// Exception thrown by PosService operations.
class PosServiceException implements Exception {
  PosServiceException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() =>
      'PosServiceException: $message${code != null ? ' ($code)' : ''}';
}

/// Result of processing a card payment.
class CardPaymentResult {
  CardPaymentResult({
    required this.clientSecret,
    required this.transactionId,
    this.paymentIntentId,
  });

  final String clientSecret;
  final String transactionId;
  final String? paymentIntentId;
}

/// Result of completing a POS sale.
class SaleCompletionResult {
  SaleCompletionResult({
    required this.transaction,
    required this.success,
    this.error,
    this.receiptUrl,
  });

  final PosTransaction transaction;
  final bool success;
  final String? error;
  final String? receiptUrl;
}

/// Summary of cart for checkout.
class CartSummary {
  CartSummary({
    required this.items,
    required this.subtotalCents,
    required this.taxCents,
    required this.discountCents,
    required this.totalCents,
    required this.taxRate,
    required this.itemCount,
  });

  final List<CartItem> items;
  final int subtotalCents;
  final int taxCents;
  final int discountCents;
  final int totalCents;
  final double taxRate;
  final int itemCount;

  double get subtotalDollars => subtotalCents / 100.0;
  double get taxDollars => taxCents / 100.0;
  double get discountDollars => discountCents / 100.0;
  double get totalDollars => totalCents / 100.0;
}

// ============================================================
// POS Service
// ============================================================

/// Service for managing Point of Sale transactions.
///
/// This service orchestrates:
/// - Cart management and pricing calculations
/// - Payment processing (card, cash, gift card, split)
/// - Inventory management
/// - Receipt generation
/// - Sales analytics
///
/// All operations enforce multi-tenant isolation via [SecurityContext].
class PosService {
  PosService({
    required PosRepository posRepository,
    required ProductRepository productRepository,
    required GiftCardRepository giftCardRepository,
    required StripeService stripeService,
    required AuditLogRepository auditLogRepository,
    required AppConfig appConfig,
  })  : _posRepository = posRepository,
        _productRepository = productRepository,
        _giftCardRepository = giftCardRepository,
        _stripeService = stripeService,
        _auditLogRepository = auditLogRepository,
        _appConfig = appConfig;

  final PosRepository _posRepository;
  final ProductRepository _productRepository;
  final GiftCardRepository _giftCardRepository;
  final StripeService _stripeService;
  final AuditLogRepository _auditLogRepository;
  final AppConfig _appConfig;

  /// Gets the default tax rate from config.
  double get _defaultTaxRate => _appConfig.paymentConfig.defaultTaxRate;

  // ============================================================
  // Cart Operations
  // ============================================================

  /// Calculate cart summary with tax.
  CartSummary calculateCartSummary({
    required List<CartItem> items,
    double? taxRate,
    int discountCents = 0,
  }) {
    final effectiveTaxRate = taxRate ?? _defaultTaxRate;

    int subtotalCents = 0;
    int taxableSubtotal = 0;

    for (final item in items) {
      final itemTotal = item.totalCents;
      subtotalCents += itemTotal;
      if (item.taxable) {
        taxableSubtotal += itemTotal;
      }
    }

    // Apply discount to subtotal
    final discountedSubtotal = subtotalCents - discountCents;

    // Calculate tax on discounted taxable amount
    final taxableAfterDiscount = (taxableSubtotal - discountCents).clamp(0, taxableSubtotal);
    final taxCents = (taxableAfterDiscount * effectiveTaxRate).round();

    final totalCents = discountedSubtotal + taxCents;

    return CartSummary(
      items: items,
      subtotalCents: subtotalCents,
      taxCents: taxCents,
      discountCents: discountCents,
      totalCents: totalCents.clamp(0, totalCents),
      taxRate: effectiveTaxRate,
      itemCount: items.fold(0, (sum, item) => sum + item.quantity),
    );
  }

  /// Validate cart items against inventory.
  Future<List<String>> validateCartInventory({
    required SecurityContext context,
    required List<CartItem> items,
  }) async {
    final errors = <String>[];

    for (final item in items) {
      final product = await _productRepository.getProduct(context, item.productId);

      if (product == null) {
        errors.add('Product "${item.productName}" not found');
        continue;
      }

      if (!product.isActive) {
        errors.add('Product "${item.productName}" is no longer available');
        continue;
      }

      if (!product.availableForSale) {
        errors.add('Product "${item.productName}" is not available for sale');
        continue;
      }

      if (product.trackInventory) {
        final available = product.stockQuantity ?? 0;
        if (available < item.quantity) {
          errors.add(
            'Insufficient stock for "${item.productName}": '
            '$available available, ${item.quantity} requested',
          );
        }
      }
    }

    return errors;
  }

  // ============================================================
  // Transaction Creation
  // ============================================================

  /// Create a POS transaction (without processing payment).
  ///
  /// Use this to create a pending transaction, then call one of
  /// the payment processing methods to complete it.
  Future<PosTransaction> createTransaction({
    required SecurityContext context,
    required List<CartItem> items,
    required PosPaymentMethod paymentMethod,
    String? clientId,
    String? clientName,
    String? appointmentId,
    int discountCents = 0,
    String? discountReason,
    double? taxRate,
    String? notes,
  }) async {
    // Validate inventory
    final inventoryErrors = await validateCartInventory(
      context: context,
      items: items,
    );

    if (inventoryErrors.isNotEmpty) {
      throw PosServiceException(
        inventoryErrors.join('; '),
        code: 'INVENTORY_ERROR',
      );
    }

    // Calculate totals
    final summary = calculateCartSummary(
      items: items,
      taxRate: taxRate,
      discountCents: discountCents,
    );

    // Convert cart items to line items
    final lineItems = items.map((item) {
      final taxForItem = item.taxable
          ? ((item.totalCents * (taxRate ?? _defaultTaxRate)).round())
          : 0;
      return item.toLineItem(taxCents: taxForItem);
    }).toList();

    // Create the transaction
    final transaction = await _posRepository.createTransaction(
      context: context,
      lineItems: lineItems,
      subtotalCents: summary.subtotalCents,
      taxCents: summary.taxCents,
      totalCents: summary.totalCents,
      paymentMethod: paymentMethod,
      taxRate: summary.taxRate,
      clientId: clientId,
      clientName: clientName,
      appointmentId: appointmentId,
      discountCents: discountCents,
      discountReason: discountReason,
      notes: notes,
    );

    return transaction;
  }

  // ============================================================
  // Payment Processing
  // ============================================================

  /// Process a card payment for a transaction.
  ///
  /// Returns client secret for presenting Stripe payment sheet.
  Future<CardPaymentResult> processCardPayment({
    required SecurityContext context,
    required String transactionId,
  }) async {
    final transaction = await _posRepository.getTransaction(
      context,
      transactionId,
    );

    if (transaction == null) {
      throw PosServiceException('Transaction not found', code: 'NOT_FOUND');
    }

    if (transaction.paymentStatus != PaymentStatus.pending) {
      throw PosServiceException(
        'Transaction is not pending payment',
        code: 'INVALID_STATUS',
      );
    }

    // Create Stripe Payment Intent
    final paymentResult = await _stripeService.createPaymentIntent(
      cloudFunctionUrl: _getPosPaymentUrl(),
      amountCents: transaction.totalCents,
      currency: _appConfig.paymentConfig.currency,
      metadata: {
        'transactionId': transactionId,
        'businessId': context.businessId,
        'type': 'pos_sale',
        if (transaction.clientId != null) 'clientId': transaction.clientId,
      },
    );

    final clientSecret = paymentResult['clientSecret'] as String?;
    if (clientSecret == null || clientSecret.isEmpty) {
      throw PosServiceException(
        'Failed to create payment intent',
        code: 'PAYMENT_INTENT_FAILED',
      );
    }

    return CardPaymentResult(
      clientSecret: clientSecret,
      transactionId: transactionId,
      paymentIntentId: paymentResult['paymentIntentId'] as String?,
    );
  }

  /// Complete a card payment after Stripe confirmation.
  Future<SaleCompletionResult> completeCardPayment({
    required SecurityContext context,
    required String transactionId,
    required String paymentIntentId,
  }) async {
    try {
      // Update transaction with payment details
      final transaction = await _posRepository.updatePaymentStatus(
        context: context,
        transactionId: transactionId,
        status: PaymentStatus.completed,
        stripePaymentId: paymentIntentId,
      );

      // Deduct inventory
      await _deductInventory(context, transaction);

      await _auditLogRepository.logEvent(AuditLogEntry(
        businessId: context.businessId,
        userId: context.userId,
        actionType: AuditActionType.phiWrite,
        entityType: 'PosTransaction',
        entityId: transactionId,
        metadata: {
          'action': 'completeCardPayment',
          'totalCents': transaction.totalCents,
        },
      ));

      return SaleCompletionResult(
        transaction: transaction,
        success: true,
      );
    } catch (e) {
      developer.log(
        'Failed to complete card payment',
        name: 'PosService',
      );
      return SaleCompletionResult(
        transaction: (await _posRepository.getTransaction(context, transactionId))!,
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Process a cash payment for a transaction.
  Future<SaleCompletionResult> processCashPayment({
    required SecurityContext context,
    required String transactionId,
    required int cashTenderedCents,
  }) async {
    final transaction = await _posRepository.getTransaction(
      context,
      transactionId,
    );

    if (transaction == null) {
      throw PosServiceException('Transaction not found', code: 'NOT_FOUND');
    }

    if (cashTenderedCents < transaction.totalCents) {
      throw PosServiceException(
        'Insufficient cash tendered',
        code: 'INSUFFICIENT_PAYMENT',
      );
    }

    final changeCents = cashTenderedCents - transaction.totalCents;

    final updatedTransaction = await _posRepository.updatePaymentStatus(
      context: context,
      transactionId: transactionId,
      status: PaymentStatus.completed,
      cashTenderedCents: cashTenderedCents,
      changeCents: changeCents,
    );

    // Deduct inventory
    await _deductInventory(context, updatedTransaction);

    await _auditLogRepository.logEvent(AuditLogEntry(
      businessId: context.businessId,
      userId: context.userId,
      actionType: AuditActionType.phiWrite,
      entityType: 'PosTransaction',
      entityId: transactionId,
      metadata: {
        'action': 'processCashPayment',
        'totalCents': updatedTransaction.totalCents,
      },
    ));

    return SaleCompletionResult(
      transaction: updatedTransaction,
      success: true,
    );
  }

  /// Process a gift card payment for a transaction.
  Future<SaleCompletionResult> processGiftCardPayment({
    required SecurityContext context,
    required String transactionId,
    required String giftCardCode,
  }) async {
    final transaction = await _posRepository.getTransaction(
      context,
      transactionId,
    );

    if (transaction == null) {
      throw PosServiceException('Transaction not found', code: 'NOT_FOUND');
    }

    // Validate and redeem gift card
    final balance = await _giftCardRepository.checkBalance(
      businessId: context.businessId,
      code: giftCardCode,
    );

    if (!balance.valid) {
      throw PosServiceException(
        'Invalid or expired gift card',
        code: 'INVALID_GIFT_CARD',
      );
    }

    if (balance.balanceCents < transaction.totalCents) {
      throw PosServiceException(
        'Insufficient gift card balance: '
        '\$${balance.balanceCents / 100} available, '
        '\$${transaction.totalCents / 100} required',
        code: 'INSUFFICIENT_BALANCE',
      );
    }

    // Redeem the gift card
    await _giftCardRepository.redeemGiftCard(
      context: context,
      giftCardCode: giftCardCode,
      appointmentId: transaction.id, // Use transaction ID as reference
      amountCents: transaction.totalCents,
      clientId: transaction.clientId ?? 'walk-in',
    );

    // Update transaction
    final updatedTransaction = await _posRepository.updatePaymentStatus(
      context: context,
      transactionId: transactionId,
      status: PaymentStatus.completed,
      giftCardCode: giftCardCode,
    );

    // Deduct inventory
    await _deductInventory(context, updatedTransaction);

    await _auditLogRepository.logEvent(AuditLogEntry(
      businessId: context.businessId,
      userId: context.userId,
      actionType: AuditActionType.phiWrite,
      entityType: 'PosTransaction',
      entityId: transactionId,
      metadata: {
        'action': 'processGiftCardPayment',
        'giftCardCodeSuffix': _maskGiftCardCode(giftCardCode),
        'totalCents': updatedTransaction.totalCents,
      },
    ));

    return SaleCompletionResult(
      transaction: updatedTransaction,
      success: true,
    );
  }

  /// Process a split payment (multiple payment methods).
  Future<SaleCompletionResult> processSplitPayment({
    required SecurityContext context,
    required String transactionId,
    required List<SplitPaymentDetail> splitPayments,
  }) async {
    final transaction = await _posRepository.getTransaction(
      context,
      transactionId,
    );

    if (transaction == null) {
      throw PosServiceException('Transaction not found', code: 'NOT_FOUND');
    }

    // Verify split payments cover the total
    final totalSplit = splitPayments.fold<int>(
      0,
      (sum, split) => sum + split.amountCents,
    );

    if (totalSplit != transaction.totalCents) {
      throw PosServiceException(
        'Split payments (\$${totalSplit / 100}) do not equal '
        'total (\$${transaction.totalCents / 100})',
        code: 'SPLIT_MISMATCH',
      );
    }

    // Process each split payment
    for (final split in splitPayments) {
      if (split.method == PosPaymentMethod.giftCard && split.giftCardCode != null) {
        // Validate and redeem gift card portion
        final balance = await _giftCardRepository.checkBalance(
          businessId: context.businessId,
          code: split.giftCardCode!,
        );

        if (!balance.valid || balance.balanceCents < split.amountCents) {
          throw PosServiceException(
            'Gift card has insufficient balance for split payment',
            code: 'INSUFFICIENT_GIFT_CARD_BALANCE',
          );
        }

        await _giftCardRepository.redeemGiftCard(
          context: context,
          giftCardCode: split.giftCardCode!,
          appointmentId: transaction.id,
          amountCents: split.amountCents,
          clientId: transaction.clientId ?? 'walk-in',
        );
      }
      // Note: Card splits require client-side handling via Stripe
    }

    // Update transaction with split payment details
    final updatedTransaction = await _posRepository.updatePaymentStatus(
      context: context,
      transactionId: transactionId,
      status: PaymentStatus.completed,
      splitPayments: splitPayments,
    );

    // Deduct inventory
    await _deductInventory(context, updatedTransaction);

    await _auditLogRepository.logEvent(AuditLogEntry(
      businessId: context.businessId,
      userId: context.userId,
      actionType: AuditActionType.phiWrite,
      entityType: 'PosTransaction',
      entityId: transactionId,
      metadata: {
        'action': 'processSplitPayment',
        'splitCount': splitPayments.length,
        'totalCents': updatedTransaction.totalCents,
      },
    ));

    return SaleCompletionResult(
      transaction: updatedTransaction,
      success: true,
    );
  }

  // ============================================================
  // Quick Sale (All-in-one)
  // ============================================================

  /// Process a complete sale in one call (create transaction + process payment).
  ///
  /// For card payments, returns [CardPaymentResult] with client secret to present payment sheet.
  /// For cash/gift card, returns [SaleCompletionResult] with completed transaction.
  Future<Object> processQuickSale({
    required SecurityContext context,
    required List<CartItem> items,
    required PosPaymentMethod paymentMethod,
    String? clientId,
    String? clientName,
    String? appointmentId,
    int discountCents = 0,
    String? discountReason,
    double? taxRate,
    String? notes,
    // For cash payments
    int? cashTenderedCents,
    // For gift card payments
    String? giftCardCode,
  }) async {
    // Create the transaction
    final transaction = await createTransaction(
      context: context,
      items: items,
      paymentMethod: paymentMethod,
      clientId: clientId,
      clientName: clientName,
      appointmentId: appointmentId,
      discountCents: discountCents,
      discountReason: discountReason,
      taxRate: taxRate,
      notes: notes,
    );

    // Process payment based on method
    switch (paymentMethod) {
      case PosPaymentMethod.card:
        // Return client secret for client-side payment
        return processCardPayment(
          context: context,
          transactionId: transaction.id,
        );

      case PosPaymentMethod.cash:
        if (cashTenderedCents == null) {
          throw PosServiceException(
            'Cash tendered amount is required',
            code: 'CASH_REQUIRED',
          );
        }
        return processCashPayment(
          context: context,
          transactionId: transaction.id,
          cashTenderedCents: cashTenderedCents,
        );

      case PosPaymentMethod.giftCard:
        if (giftCardCode == null) {
          throw PosServiceException(
            'Gift card code is required',
            code: 'GIFT_CARD_REQUIRED',
          );
        }
        return processGiftCardPayment(
          context: context,
          transactionId: transaction.id,
          giftCardCode: giftCardCode,
        );

      case PosPaymentMethod.split:
        throw PosServiceException(
          'Split payments require separate handling',
          code: 'SPLIT_NOT_SUPPORTED',
        );

      case PosPaymentMethod.account:
        // Charge to client account (future feature)
        throw PosServiceException(
          'Account payments not yet implemented',
          code: 'NOT_IMPLEMENTED',
        );
    }
  }

  // ============================================================
  // Transaction Management
  // ============================================================

  /// Void a completed transaction.
  ///
  /// For card payments, this will automatically process a refund via Stripe.
  /// For gift card payments, the balance is restored to the gift card.
  Future<PosTransaction> voidTransaction({
    required SecurityContext context,
    required String transactionId,
    required String reason,
  }) async {
    final transaction = await _posRepository.getTransaction(
      context,
      transactionId,
    );

    if (transaction == null) {
      throw PosServiceException('Transaction not found', code: 'NOT_FOUND');
    }

    if (transaction.isVoided) {
      throw PosServiceException(
        'Transaction is already voided',
        code: 'ALREADY_VOIDED',
      );
    }

    // Restore inventory if transaction was completed
    if (transaction.isCompleted) {
      await _restoreInventory(context, transaction);
    }

    // Handle refund based on payment method
    if (transaction.stripePaymentId != null) {
      // Process Stripe refund
      await _processStripeRefund(
        context: context,
        transaction: transaction,
        reason: reason,
      );
    }

    // Restore gift card balance if paid with gift card
    if (transaction.giftCardCode != null) {
      await _restoreGiftCardBalance(
        context: context,
        transaction: transaction,
      );
    }

    // Handle split payment refunds
    if (transaction.isSplitPayment && transaction.splitPayments.isNotEmpty) {
      for (final split in transaction.splitPayments) {
        if (split.stripePaymentId != null) {
          await _stripeService.createRefund(
            cloudFunctionUrl: _getRefundUrl(),
            paymentIntentId: split.stripePaymentId!,
            reason: reason,
            metadata: {
              'transactionId': transactionId,
              'businessId': context.businessId,
              'voidReason': reason,
              'splitPayment': true,
            },
          );
        }
        if (split.giftCardCode != null) {
          // Restore partial gift card balance
          // Note: This requires tracking partial redemption amounts
          developer.log(
            'Gift card balance restoration for split payment: ${split.giftCardCode}',
            name: 'PosService',
          );
        }
      }
    }

    // Void the transaction
    final voidedTransaction = await _posRepository.voidTransaction(
      context: context,
      transactionId: transactionId,
      reason: reason,
    );

    await _auditLogRepository.logEvent(AuditLogEntry(
      businessId: context.businessId,
      userId: context.userId,
      actionType: AuditActionType.phiWrite,
      entityType: 'PosTransaction',
      entityId: transactionId,
      metadata: {
        'action': 'void',
        'reason': reason.length > 100 ? reason.substring(0, 100) : reason,
        'totalCents': transaction.totalCents,
        'hadStripePayment': transaction.stripePaymentId != null,
        'hadGiftCardPayment': transaction.giftCardCode != null,
      },
    ));

    return voidedTransaction;
  }

  /// Process a Stripe refund for a voided transaction.
  Future<void> _processStripeRefund({
    required SecurityContext context,
    required PosTransaction transaction,
    required String reason,
  }) async {
    if (transaction.stripePaymentId == null) return;

    try {
      await _stripeService.createRefund(
        cloudFunctionUrl: _getRefundUrl(),
        paymentIntentId: transaction.stripePaymentId!,
        reason: reason,
        metadata: {
          'transactionId': transaction.id,
          'businessId': context.businessId,
          'receiptNumber': transaction.receiptNumber,
          'voidReason': reason,
        },
      );

      developer.log(
        'Stripe refund processed',
        name: 'PosService',
      );
    } catch (e) {
      developer.log(
        'Failed to process Stripe refund',
        name: 'PosService',
        error: e,
      );
      // Don't throw - we still want to void the transaction
      // The refund failure should be handled by support/admin
        await _auditLogRepository.logEvent(AuditLogEntry(
          businessId: context.businessId,
          userId: context.userId,
          actionType: AuditActionType.securityEvent,
          entityType: 'StripeRefund',
          entityId: transaction.stripePaymentId!,
          metadata: {
            'action': 'refundFailed',
            'error': 'refundFailed',
            'transactionId': transaction.id,
            'requiresManualRefund': true,
          },
        ));
      }
  }

  /// Restore gift card balance for a voided transaction.
  Future<void> _restoreGiftCardBalance({
    required SecurityContext context,
    required PosTransaction transaction,
  }) async {
    if (transaction.giftCardCode == null) return;

    try {
      // Get the gift card and add back the redeemed amount
      final giftCard = await _giftCardRepository.getGiftCardByCode(
        context,
        transaction.giftCardCode!,
      );

      if (giftCard != null) {
        // Calculate the amount to restore (total paid by gift card)
        final restoreAmount = transaction.totalCents;

        await _giftCardRepository.updateGiftCard(
          context: context,
          giftCardId: giftCard.id,
          updates: {
            'remainingBalanceCents': giftCard.remainingBalanceCents + restoreAmount,
            'status': 'active', // Reactivate if it was depleted
          },
        );

        developer.log(
          'Gift card balance restored',
          name: 'PosService',
        );
      }
    } catch (e) {
      developer.log(
        'Failed to restore gift card balance',
        name: 'PosService',
        error: e,
      );
    }
  }

  String _getRefundUrl() {
    final refundUrl = _appConfig.paymentConfig.refundFunctionUrl;
    if (refundUrl != null && refundUrl.isNotEmpty) {
      return refundUrl;
    }

    // Fallback: derive from base payment intent URL
    final baseUrl = _appConfig.paymentConfig.paymentIntentFunctionUrl;
    final uri = Uri.parse(baseUrl);
    return uri
        .replace(
          path: uri.path.replaceFirst(
            'createPaymentIntent',
            'createRefund',
          ),
        )
        .toString();
  }

  /// Get transaction by ID.
  Future<PosTransaction?> getTransaction(
    SecurityContext context,
    String transactionId,
  ) {
    return _posRepository.getTransaction(context, transactionId);
  }

  /// Get transaction by receipt number.
  Future<PosTransaction?> getTransactionByReceipt(
    SecurityContext context,
    String receiptNumber,
  ) {
    return _posRepository.getTransactionByReceipt(context, receiptNumber);
  }

  // ============================================================
  // Query Operations
  // ============================================================

  /// Stream transactions for the business.
  Stream<List<PosTransaction>> watchTransactions(
    SecurityContext context, {
    DateTime? startDate,
    DateTime? endDate,
    String? staffId,
    PaymentStatus? status,
    int limit = 50,
  }) {
    return _posRepository.watchTransactions(
      context,
      startDate: startDate,
      endDate: endDate,
      staffId: staffId,
      status: status,
      limit: limit,
    );
  }

  /// Get transactions for a date range.
  Future<List<PosTransaction>> getTransactions(
    SecurityContext context, {
    DateTime? startDate,
    DateTime? endDate,
    String? staffId,
    String? clientId,
    PaymentStatus? status,
    bool excludeVoided = true,
    int limit = 50,
  }) {
    return _posRepository.getTransactions(
      context,
      startDate: startDate,
      endDate: endDate,
      staffId: staffId,
      clientId: clientId,
      status: status,
      excludeVoided: excludeVoided,
      limit: limit,
    );
  }

  /// Get transactions for a specific client.
  Future<List<PosTransaction>> getTransactionsForClient(
    SecurityContext context,
    String clientId, {
    int limit = 50,
  }) {
    return _posRepository.getTransactionsForClient(context, clientId, limit: limit);
  }

  /// Get transactions for a specific appointment.
  Future<List<PosTransaction>> getTransactionsForAppointment(
    SecurityContext context,
    String appointmentId,
  ) {
    return _posRepository.getTransactionsForAppointment(context, appointmentId);
  }

  // ============================================================
  // Analytics
  // ============================================================

  /// Get sales statistics for a date range.
  Future<PosSalesStats> getSalesStats(
    SecurityContext context, {
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return _posRepository.getSalesStats(
      context,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Get top selling products.
  Future<List<ProductSalesData>> getTopSellingProducts(
    SecurityContext context, {
    required DateTime startDate,
    required DateTime endDate,
    int limit = 10,
  }) {
    return _posRepository.getTopSellingProducts(
      context,
      startDate: startDate,
      endDate: endDate,
      limit: limit,
    );
  }

  // ============================================================
  // Product Operations (Delegate to Repository)
  // ============================================================

  /// Get all active products.
  Future<List<RetailProduct>> getProducts(
    SecurityContext context, {
    ProductCategory? category,
    bool? availableForSale,
    int limit = 100,
  }) {
    return _productRepository.getProducts(
      context,
      category: category,
      availableForSale: availableForSale,
      limit: limit,
    );
  }

  /// Stream active products.
  Stream<List<RetailProduct>> watchProducts(
    SecurityContext context, {
    ProductCategory? category,
    bool? availableForSale,
    int limit = 100,
  }) {
    return _productRepository.watchProducts(
      context,
      category: category,
      availableForSale: availableForSale,
      limit: limit,
    );
  }

  /// Search products by name, SKU, or barcode.
  Future<List<RetailProduct>> searchProducts({
    required SecurityContext context,
    required String query,
    int limit = 20,
  }) {
    return _productRepository.searchProducts(
      context: context,
      query: query,
      limit: limit,
    );
  }

  /// Get product by barcode (for scanner).
  Future<RetailProduct?> getProductByBarcode(
    SecurityContext context,
    String barcode,
  ) {
    return _productRepository.getProductByBarcode(context, barcode);
  }

  /// Get products with low stock.
  Future<List<RetailProduct>> getLowStockProducts(SecurityContext context) {
    return _productRepository.getLowStockProducts(context);
  }

  // ============================================================
  // Private Helpers
  // ============================================================

  /// Mask a gift card code for safe logging.
  /// Shows only the last 4 characters: GIFT-XXXX-XXXX -> ****-****-XXXX
  String _maskGiftCardCode(String code) {
    if (code.length <= 4) return '****';
    return '****-****-${code.substring(code.length - 4)}';
  }

  /// Deduct inventory for completed transaction.
  Future<void> _deductInventory(
    SecurityContext context,
    PosTransaction transaction,
  ) async {
    for (final item in transaction.lineItems) {
      try {
        await _productRepository.decrementStock(
          context: context,
          productId: item.productId,
          quantity: item.quantity,
        );
      } catch (e) {
        developer.log(
          'Failed to deduct inventory for product ${item.productId}: $e',
          name: 'PosService',
        );
        // Continue with other items - inventory issues shouldn't block sale
      }
    }
  }

  /// Restore inventory for voided transaction.
  Future<void> _restoreInventory(
    SecurityContext context,
    PosTransaction transaction,
  ) async {
    for (final item in transaction.lineItems) {
      try {
        await _productRepository.incrementStock(
          context: context,
          productId: item.productId,
          quantity: item.quantity,
          reason: 'Void of transaction ${transaction.receiptNumber}',
        );
      } catch (e) {
        developer.log(
          'Failed to restore inventory for product ${item.productId}: $e',
          name: 'PosService',
        );
      }
    }
  }

  String _getPosPaymentUrl() {
    // Use dedicated POS payment endpoint if configured
    final posUrl = _appConfig.paymentConfig.posPaymentFunctionUrl;
    if (posUrl != null && posUrl.isNotEmpty) {
      return posUrl;
    }

    // Fallback: derive from base payment intent URL
    final baseUrl = _appConfig.paymentConfig.paymentIntentFunctionUrl;
    final uri = Uri.parse(baseUrl);
    return uri
        .replace(
          path: uri.path.replaceFirst(
            'createPaymentIntent',
            'createPosPayment',
          ),
        )
        .toString();
  }
}
