import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../core/services/demo_guard_service.dart';
import '../models/audit_log.dart';
import '../models/gift_card.dart';
import '../models/security_context.dart';
import 'audit_log_repository.dart';
import 'gift_card_types.dart';

export 'gift_card_types.dart';

/// Simple in-memory rate limiter for balance checks.
///
/// Prevents brute-force attacks on gift card codes by limiting
/// the number of balance check attempts per business within a time window.
class _BalanceCheckRateLimiter {
  _BalanceCheckRateLimiter();

  static const int maxAttempts = 10;
  static const Duration windowDuration = Duration(minutes: 1);

  // Map of businessId -> list of attempt timestamps
  final Map<String, List<DateTime>> _attempts = {};

  /// Check if a balance check is allowed for the given business.
  /// Returns true if allowed, false if rate limited.
  bool isAllowed(String businessId) {
    final now = DateTime.now();
    final windowStart = now.subtract(windowDuration);

    // Clean up old attempts
    _attempts[businessId] = (_attempts[businessId] ?? [])
        .where((t) => t.isAfter(windowStart))
        .toList();

    // Check if under limit
    if ((_attempts[businessId]?.length ?? 0) >= maxAttempts) {
      return false;
    }

    // Record this attempt
    _attempts[businessId] = [...(_attempts[businessId] ?? []), now];
    return true;
  }

  /// Record a failed attempt (for potential future exponential backoff).
  void recordFailure(String businessId) {
    // Could be extended to implement exponential backoff
  }
}

/// Repository for managing gift cards per business.
///
/// All operations enforce multi-tenant isolation via [SecurityContext].
/// Operations are logged via [AuditLogRepository] for compliance.
///
/// For template operations, see [GiftCardTemplateRepository].
class GiftCardRepository {
  GiftCardRepository({
    FirebaseFirestore? firestore,
    AuditLogRepository? auditLogRepository,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auditLogRepository = auditLogRepository ?? AuditLogRepository();

  final FirebaseFirestore _firestore;
  final AuditLogRepository _auditLogRepository;
  final _uuid = const Uuid();

  /// Rate limiter for balance check operations.
  static final _balanceCheckLimiter = _BalanceCheckRateLimiter();

  // Characters for code generation (no ambiguous I, O, 0, 1)
  static const _codeChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  /// Default limit for list queries
  static const int defaultLimit = 50;

  CollectionReference<Map<String, dynamic>> _giftCardsCollection(
    String businessId,
  ) {
    return _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('giftCards');
  }

  // ============================================================
  // Gift Card CRUD Operations
  // ============================================================

  /// Create a new gift card with pending status.
  ///
  /// The card remains pending until payment is confirmed via [activateGiftCard].
  Future<GiftCard> createGiftCard({
    required SecurityContext context,
    required int amountCents,
    required String purchaserEmail,
    String? purchaserName,
    String? recipientEmail,
    String? recipientName,
    String? personalMessage,
    String? templateId,
  }) async {
    DemoGuardService.assertReadOnly('create gift card');
    context.verifyBusinessAccess();

    final code = await _generateUniqueCode(context.businessId);
    final now = DateTime.now();
    final docRef = _giftCardsCollection(context.businessId).doc();

    final giftCard = GiftCard(
      id: docRef.id,
      businessId: context.businessId,
      code: code,
      originalAmountCents: amountCents,
      remainingBalanceCents: amountCents,
      currency: 'usd',
      status: GiftCardStatus.pending,
      purchaserEmail: purchaserEmail,
      purchaserName: purchaserName,
      purchasedAt: now,
      recipientEmail: recipientEmail,
      recipientName: recipientName,
      personalMessage: personalMessage,
      templateId: templateId,
      createdAt: now,
    );

    await docRef.set(giftCard.toJson());

    _auditLogRepository.logEvent(
      AuditLogEntry(
        businessId: context.businessId,
        userId: context.userId,
        actionType: AuditActionType.phiWrite,
        entityType: 'GiftCard',
        entityId: giftCard.id,
        metadata: {
          'action': 'create',
          'amountCents': amountCents,
          'code': code,
        },
      ),
    );

    return giftCard;
  }

  /// Activate a gift card after successful payment.
  Future<GiftCard> activateGiftCard({
    required SecurityContext context,
    required String giftCardId,
    required String paymentId,
    DateTime? expiresAt,
  }) async {
    DemoGuardService.assertReadOnly('activate gift card');
    context.verifyBusinessAccess();

    final docRef = _giftCardsCollection(context.businessId).doc(giftCardId);

    await docRef.update({
      'status': GiftCardStatus.active.name,
      'activatedAt': FieldValue.serverTimestamp(),
      'paymentId': paymentId,
      if (expiresAt != null) 'expiresAt': expiresAt.toIso8601String(),
    });

    final doc = await docRef.get();
    if (!doc.exists) {
      throw GiftCardException('Gift card not found after activation');
    }

    _auditLogRepository.logEvent(
      AuditLogEntry(
        businessId: context.businessId,
        userId: context.userId,
        actionType: AuditActionType.phiWrite,
        entityType: 'GiftCard',
        entityId: giftCardId,
        metadata: {'action': 'activate', 'paymentId': paymentId},
      ),
    );

    return GiftCard.fromJson(_decodeGiftCardDoc(doc));
  }

  /// Get a gift card by ID.
  Future<GiftCard?> getGiftCard(
    SecurityContext context,
    String giftCardId,
  ) async {
    context.verifyBusinessAccess();

    final doc = await _giftCardsCollection(
      context.businessId,
    ).doc(giftCardId).get();

    if (!doc.exists) return null;

    _auditLogRepository.logEvent(
      AuditLogEntry(
        businessId: context.businessId,
        userId: context.userId,
        actionType: AuditActionType.phiRead,
        entityType: 'GiftCard',
        entityId: giftCardId,
        metadata: {'source': 'getGiftCard'},
      ),
    );

    return GiftCard.fromJson(_decodeGiftCardDoc(doc));
  }

  /// Get a gift card by its redemption code.
  Future<GiftCard?> getGiftCardByCode(
    SecurityContext context,
    String code,
  ) async {
    context.verifyBusinessAccess();

    final snapshot = await _giftCardsCollection(
      context.businessId,
    ).where('code', isEqualTo: code.toUpperCase()).limit(1).get();

    if (snapshot.docs.isEmpty) return null;

    _auditLogRepository.logEvent(
      AuditLogEntry(
        businessId: context.businessId,
        userId: context.userId,
        actionType: AuditActionType.phiRead,
        entityType: 'GiftCard',
        entityId: snapshot.docs.first.id,
        metadata: {'source': 'getGiftCardByCode'},
      ),
    );

    return GiftCard.fromJson(_decodeGiftCardDoc(snapshot.docs.first));
  }

  /// Update a gift card.
  Future<void> updateGiftCard({
    required SecurityContext context,
    required String giftCardId,
    required Map<String, dynamic> updates,
  }) async {
    DemoGuardService.assertReadOnly('update gift card');
    context.verifyBusinessAccess();
    context.verifyPaymentAccess();

    updates['updatedAt'] = FieldValue.serverTimestamp();

    await _giftCardsCollection(
      context.businessId,
    ).doc(giftCardId).update(updates);

    _auditLogRepository.logEvent(
      AuditLogEntry(
        businessId: context.businessId,
        userId: context.userId,
        actionType: AuditActionType.phiWrite,
        entityType: 'GiftCard',
        entityId: giftCardId,
        metadata: {'action': 'update', 'fieldsUpdated': updates.keys.length},
      ),
    );
  }

  /// Void a gift card (admin operation).
  Future<void> voidGiftCard({
    required SecurityContext context,
    required String giftCardId,
    required String reason,
  }) async {
    DemoGuardService.assertReadOnly('void gift card');
    context.verifyBusinessAccess();
    context.verifyPaymentAccess();

    await _giftCardsCollection(context.businessId).doc(giftCardId).update({
      'status': GiftCardStatus.voided.name,
      'voidedAt': FieldValue.serverTimestamp(),
      'voidReason': reason,
    });

    _auditLogRepository.logEvent(
      AuditLogEntry(
        businessId: context.businessId,
        userId: context.userId,
        actionType: AuditActionType.phiWrite,
        entityType: 'GiftCard',
        entityId: giftCardId,
        metadata: {
          'action': 'void',
          'reason': reason.length > 50 ? reason.substring(0, 50) : reason,
        },
      ),
    );
  }

  // ============================================================
  // Redemption Operations
  // ============================================================

  /// Redeem a gift card against an appointment.
  Future<GiftCardRedemption> redeemGiftCard({
    required SecurityContext context,
    required String giftCardCode,
    required String appointmentId,
    required int amountCents,
    required String clientId,
  }) async {
    DemoGuardService.assertReadOnly('redeem gift card');
    context.verifyBusinessAccess();

    final snapshot = await _giftCardsCollection(
      context.businessId,
    ).where('code', isEqualTo: giftCardCode.toUpperCase()).limit(1).get();

    if (snapshot.docs.isEmpty) {
      throw GiftCardException('Invalid gift card code', code: 'INVALID_CODE');
    }

    final doc = snapshot.docs.first;
    final giftCard = GiftCard.fromJson(_decodeGiftCardDoc(doc));

    if (giftCard.status != GiftCardStatus.active) {
      throw GiftCardException(
        'Gift card is not active (status: ${giftCard.status.name})',
        code: 'INACTIVE',
      );
    }

    if (giftCard.expiresAt != null &&
        giftCard.expiresAt!.isBefore(DateTime.now())) {
      throw GiftCardException('Gift card has expired', code: 'EXPIRED');
    }

    if (giftCard.remainingBalanceCents < amountCents) {
      throw GiftCardException(
        'Insufficient balance: ${giftCard.remainingBalanceDollars} available, '
        '${amountCents / 100.0} requested',
        code: 'INSUFFICIENT_BALANCE',
      );
    }

    final redemption = GiftCardRedemption(
      id: _uuid.v4(),
      giftCardId: giftCard.id,
      appointmentId: appointmentId,
      amountCents: amountCents,
      redeemedAt: DateTime.now(),
      redeemedByClientId: clientId,
    );

    final newBalance = giftCard.remainingBalanceCents - amountCents;
    final newStatus = newBalance == 0
        ? GiftCardStatus.depleted
        : GiftCardStatus.active;

    await doc.reference.update({
      'remainingBalanceCents': newBalance,
      'status': newStatus.name,
      'lastRedeemedAt': FieldValue.serverTimestamp(),
      'redemptions': FieldValue.arrayUnion([redemption.toJson()]),
    });

    _auditLogRepository.logEvent(
      AuditLogEntry(
        businessId: context.businessId,
        userId: context.userId,
        actionType: AuditActionType.phiWrite,
        entityType: 'GiftCard',
        entityId: giftCard.id,
        metadata: {
          'action': 'redeem',
          'amountCents': amountCents,
          'appointmentId': appointmentId,
          'newBalance': newBalance,
        },
      ),
    );

    return redemption;
  }

  /// Check gift card balance by code. Does not throw if not found.
  ///
  /// This operation is rate-limited to prevent brute-force attacks.
  /// Returns invalid balance if rate limit is exceeded.
  Future<GiftCardBalance> checkBalance({
    required String businessId,
    required String code,
  }) async {
    // Apply rate limiting to prevent brute-force attacks
    if (!_balanceCheckLimiter.isAllowed(businessId)) {
      // Return invalid without revealing rate limiting to potential attacker
      // Log the rate limit event for monitoring
      _auditLogRepository.logEvent(
        AuditLogEntry(
          businessId: businessId,
          userId: 'system',
          actionType: AuditActionType.securityEvent,
          entityType: 'GiftCard',
          entityId: 'rate_limit',
          metadata: {
            'action': 'balanceCheckRateLimited',
            'codeSuffix': code.length > 4
                ? code.substring(code.length - 4)
                : '****',
          },
        ),
      );
      return GiftCardBalance(valid: false, balanceCents: 0, code: code);
    }

    final snapshot = await _giftCardsCollection(
      businessId,
    ).where('code', isEqualTo: code.toUpperCase()).limit(1).get();

    if (snapshot.docs.isEmpty) {
      _balanceCheckLimiter.recordFailure(businessId);
      return GiftCardBalance(valid: false, balanceCents: 0, code: code);
    }

    final giftCard = GiftCard.fromJson(_decodeGiftCardDoc(snapshot.docs.first));
    final isExpired =
        giftCard.expiresAt != null &&
        giftCard.expiresAt!.isBefore(DateTime.now());
    final isValid = giftCard.status == GiftCardStatus.active && !isExpired;

    return GiftCardBalance(
      valid: isValid,
      balanceCents: isValid ? giftCard.remainingBalanceCents : 0,
      expiresAt: giftCard.expiresAt,
      code: code,
    );
  }

  // ============================================================
  // Query Operations
  // ============================================================

  /// Stream gift cards for a business.
  Stream<List<GiftCard>> watchGiftCards(
    SecurityContext context, {
    GiftCardStatus? status,
    int limit = defaultLimit,
  }) {
    context.verifyBusinessAccess();
    context.verifyPaymentAccess();

    Query<Map<String, dynamic>> query = _giftCardsCollection(
      context.businessId,
    ).orderBy('createdAt', descending: true);

    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }

    query = query.limit(limit);

    _auditLogRepository.logEvent(
      AuditLogEntry(
        businessId: context.businessId,
        userId: context.userId,
        actionType: AuditActionType.phiReadList,
        entityType: 'GiftCard',
        entityId: status?.name ?? 'all',
        metadata: {
          'source': 'watchGiftCards',
          'mode': 'stream',
          'limit': limit,
          if (status != null) 'filterStatus': status.name,
        },
      ),
    );

    return query.snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => GiftCard.fromJson(_decodeGiftCardDoc(doc)))
          .toList(),
    );
  }

  /// Get aggregated gift card statistics for a business.
  Future<GiftCardStats> getGiftCardStats(SecurityContext context) async {
    context.verifyBusinessAccess();
    context.verifyPaymentAccess();

    final snapshot = await _giftCardsCollection(context.businessId)
        .where(
          'status',
          whereIn: [GiftCardStatus.active.name, GiftCardStatus.depleted.name],
        )
        .get();

    int totalSoldCents = 0;
    int totalSoldCount = 0;
    int outstandingBalanceCents = 0;
    int totalRedeemedCents = 0;
    int redemptionCount = 0;

    for (final doc in snapshot.docs) {
      final giftCard = GiftCard.fromJson(_decodeGiftCardDoc(doc));
      totalSoldCents += giftCard.originalAmountCents;
      totalSoldCount++;
      if (giftCard.status == GiftCardStatus.active) {
        outstandingBalanceCents += giftCard.remainingBalanceCents;
      }
      totalRedeemedCents += giftCard.totalRedeemedCents;
      redemptionCount += giftCard.redemptions.length;
    }

    _auditLogRepository.logEvent(
      AuditLogEntry(
        businessId: context.businessId,
        userId: context.userId,
        actionType: AuditActionType.phiReadList,
        entityType: 'GiftCard',
        entityId: 'stats',
        metadata: {'source': 'getGiftCardStats', 'cardCount': totalSoldCount},
      ),
    );

    return GiftCardStats(
      totalSoldCents: totalSoldCents,
      totalSoldCount: totalSoldCount,
      outstandingBalanceCents: outstandingBalanceCents,
      totalRedeemedCents: totalRedeemedCents,
      redemptionCount: redemptionCount,
    );
  }

  /// Get gift cards by purchaser email.
  Future<List<GiftCard>> getGiftCardsByPurchaser({
    required SecurityContext context,
    required String purchaserEmail,
  }) async {
    context.verifyBusinessAccess();

    final snapshot = await _giftCardsCollection(context.businessId)
        .where('purchaserEmail', isEqualTo: purchaserEmail.toLowerCase())
        .orderBy('createdAt', descending: true)
        .get();

    _auditLogRepository.logEvent(
      AuditLogEntry(
        businessId: context.businessId,
        userId: context.userId,
        actionType: AuditActionType.phiReadList,
        entityType: 'GiftCard',
        entityId: 'purchaser',
        metadata: {
          'source': 'getGiftCardsByPurchaser',
          'resultCount': snapshot.docs.length,
        },
      ),
    );

    return snapshot.docs
        .map((doc) => GiftCard.fromJson(_decodeGiftCardDoc(doc)))
        .toList();
  }

  /// Mark a gift card as delivered (email sent successfully).
  Future<void> markDelivered(SecurityContext context, String giftCardId) async {
    DemoGuardService.assertReadOnly(
      'mark gift card delivered',
      showMessage: false,
    );
    context.verifyBusinessAccess();

    await _giftCardsCollection(context.businessId).doc(giftCardId).update({
      'delivered': true,
      'deliveredAt': FieldValue.serverTimestamp(),
    });

    _auditLogRepository.logEvent(
      AuditLogEntry(
        businessId: context.businessId,
        userId: context.userId,
        actionType: AuditActionType.phiWrite,
        entityType: 'GiftCard',
        entityId: giftCardId,
        metadata: {'action': 'markDelivered'},
      ),
    );
  }

  // ============================================================
  // Helper Methods
  // ============================================================

  Future<String> _generateUniqueCode(String businessId) async {
    final random = Random.secure();

    for (var attempt = 0; attempt < 10; attempt++) {
      final segment1 = List.generate(
        4,
        (_) => _codeChars[random.nextInt(_codeChars.length)],
      ).join();
      final segment2 = List.generate(
        4,
        (_) => _codeChars[random.nextInt(_codeChars.length)],
      ).join();
      final code = 'GIFT-$segment1-$segment2';

      final existing = await _giftCardsCollection(
        businessId,
      ).where('code', isEqualTo: code).limit(1).get();

      if (existing.docs.isEmpty) return code;
    }

    return 'GIFT-${_uuid.v4().substring(0, 4).toUpperCase()}-'
        '${_uuid.v4().substring(0, 4).toUpperCase()}';
  }

  Map<String, dynamic> _decodeGiftCardDoc(
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

    normalizeField('activatedAt');
    normalizeField('expiresAt');
    normalizeField('purchasedAt');
    normalizeField('createdAt');
    normalizeField('lastRedeemedAt');
    normalizeField('deliveredAt');
    normalizeField('voidedAt');

    if (normalized['redemptions'] is List) {
      normalized['redemptions'] = (normalized['redemptions'] as List).map((r) {
        if (r is Map<String, dynamic>) {
          final redemption = Map<String, dynamic>.from(r);
          if (redemption['redeemedAt'] is Timestamp) {
            redemption['redeemedAt'] = (redemption['redeemedAt'] as Timestamp)
                .toDate()
                .toIso8601String();
          }
          return redemption;
        }
        return r;
      }).toList();
    }

    return {'id': doc.id, ...normalized};
  }
}
