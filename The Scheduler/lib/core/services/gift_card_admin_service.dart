// Admin operations for gift cards.
// Extracted from GiftCardService to maintain file size limits.

import 'dart:developer' as developer;

import '../../data/models/audit_log.dart';
import '../../data/models/gift_card.dart';
import '../../data/models/security_context.dart';
import '../../data/repositories/audit_log_repository.dart';
import '../../data/repositories/gift_card_repository.dart';

/// Service for gift card admin operations.
///
/// Provides methods for:
/// - Manual gift card issuance (promotional, goodwill)
/// - Balance adjustments
/// - Expiration extensions
/// - Voiding cards
///
/// All operations require payment access and are audit logged.
class GiftCardAdminService {
  GiftCardAdminService({
    required GiftCardRepository repository,
    required AuditLogRepository auditLogRepository,
    this.onGiftCardActivated,
  })  : _repository = repository,
        _auditLogRepository = auditLogRepository;

  final GiftCardRepository _repository;
  final AuditLogRepository _auditLogRepository;

  /// Callback for when a gift card is activated (to send emails).
  final Future<void> Function(SecurityContext, GiftCard)? onGiftCardActivated;

  /// Issue a manual gift card without payment (promotional, goodwill, etc.)
  Future<GiftCard> issueManualGiftCard({
    required SecurityContext context,
    required int amountCents,
    required String recipientEmail,
    required String reason,
    String? recipientName,
    DateTime? expiresAt,
  }) async {
    context.verifyPaymentAccess();

    // Create the gift card
    final giftCard = await _repository.createGiftCard(
      context: context,
      amountCents: amountCents,
      purchaserEmail: context.userId, // Admin issuing
      purchaserName: 'Manual Issue',
      recipientEmail: recipientEmail.toLowerCase().trim(),
      recipientName: recipientName?.trim(),
    );

    // Activate immediately (no payment required)
    final activatedCard = await _repository.activateGiftCard(
      context: context,
      giftCardId: giftCard.id,
      paymentId: 'MANUAL-${DateTime.now().millisecondsSinceEpoch}',
      expiresAt: expiresAt,
    );

    // Log the manual issuance
    _auditLogRepository.logEvent(AuditLogEntry(
      businessId: context.businessId,
      userId: context.userId,
      actionType: AuditActionType.phiWrite,
      entityType: 'GiftCard',
      entityId: giftCard.id,
      metadata: {
        'action': 'manualIssue',
        'amountCents': amountCents,
        'reason': reason,
        'recipientEmail': recipientEmail,
      },
    ));

    // Trigger email callback if provided
    if (onGiftCardActivated != null) {
      onGiftCardActivated!(context, activatedCard).catchError((error) {
        developer.log(
          'Failed to send manual gift card emails: $error',
          name: 'GiftCardAdminService',
        );
      });
    }

    return activatedCard;
  }

  /// Adjust a gift card's balance (admin operation).
  Future<GiftCard> adjustGiftCardBalance({
    required SecurityContext context,
    required String giftCardId,
    required int adjustmentCents,
    required String reason,
  }) async {
    context.verifyPaymentAccess();

    final giftCard = await _repository.getGiftCard(context, giftCardId);
    if (giftCard == null) {
      throw GiftCardException('Gift card not found', code: 'NOT_FOUND');
    }

    final newBalance = giftCard.remainingBalanceCents + adjustmentCents;
    if (newBalance < 0) {
      throw GiftCardException(
        'Cannot reduce balance below zero',
        code: 'INVALID_ADJUSTMENT',
      );
    }

    // Determine new status
    GiftCardStatus newStatus = giftCard.status;
    if (newBalance == 0 && giftCard.status == GiftCardStatus.active) {
      newStatus = GiftCardStatus.depleted;
    } else if (newBalance > 0 && giftCard.status == GiftCardStatus.depleted) {
      newStatus = GiftCardStatus.active;
    }

    await _repository.updateGiftCard(
      context: context,
      giftCardId: giftCardId,
      updates: {
        'remainingBalanceCents': newBalance,
        'status': newStatus.name,
      },
    );

    _auditLogRepository.logEvent(AuditLogEntry(
      businessId: context.businessId,
      userId: context.userId,
      actionType: AuditActionType.phiWrite,
      entityType: 'GiftCard',
      entityId: giftCardId,
      metadata: {
        'action': 'adjustBalance',
        'adjustmentCents': adjustmentCents,
        'newBalance': newBalance,
        'reason': reason,
      },
    ));

    return giftCard.copyWith(
      remainingBalanceCents: newBalance,
      status: newStatus,
    );
  }

  /// Extend or set a gift card's expiration date.
  Future<GiftCard> extendExpiration({
    required SecurityContext context,
    required String giftCardId,
    required DateTime newExpiresAt,
    required String reason,
  }) async {
    context.verifyPaymentAccess();

    final giftCard = await _repository.getGiftCard(context, giftCardId);
    if (giftCard == null) {
      throw GiftCardException('Gift card not found', code: 'NOT_FOUND');
    }

    // Determine new status (reactivate if expired)
    GiftCardStatus newStatus = giftCard.status;
    if (giftCard.status == GiftCardStatus.expired &&
        newExpiresAt.isAfter(DateTime.now()) &&
        giftCard.remainingBalanceCents > 0) {
      newStatus = GiftCardStatus.active;
    }

    await _repository.updateGiftCard(
      context: context,
      giftCardId: giftCardId,
      updates: {
        'expiresAt': newExpiresAt.toIso8601String(),
        'status': newStatus.name,
      },
    );

    _auditLogRepository.logEvent(AuditLogEntry(
      businessId: context.businessId,
      userId: context.userId,
      actionType: AuditActionType.phiWrite,
      entityType: 'GiftCard',
      entityId: giftCardId,
      metadata: {
        'action': 'extendExpiration',
        'newExpiresAt': newExpiresAt.toIso8601String(),
        'reason': reason,
      },
    ));

    return giftCard.copyWith(
      expiresAt: newExpiresAt,
      status: newStatus,
    );
  }

  /// Void a gift card. Delegates to repository.
  Future<void> voidGiftCard({
    required SecurityContext context,
    required String giftCardId,
    required String reason,
  }) async {
    await _repository.voidGiftCard(
      context: context,
      giftCardId: giftCardId,
      reason: reason,
    );
  }
}
