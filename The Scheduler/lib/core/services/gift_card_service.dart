import 'dart:developer' as developer;
import 'dart:math' show min;

import '../config/app_config.dart';
import '../../data/models/audit_log.dart';
import '../../data/models/gift_card.dart';
import '../../data/models/gift_card_template.dart';
import '../../data/models/security_context.dart';
import '../../data/repositories/audit_log_repository.dart';
import '../../data/repositories/gift_card_repository.dart';
import '../../data/repositories/gift_card_template_repository.dart';
import 'email_service.dart';
import 'gift_card_service_types.dart';
import 'stripe_service.dart';

// Re-export types for convenience
export 'gift_card_service_types.dart';

// ============================================================
// Gift Card Service
// ============================================================

/// Service for managing gift card business logic and Stripe integration.
///
/// This service orchestrates:
/// - Purchase flow with Stripe payment intents
/// - Email delivery to purchasers and recipients
/// - Redemption flow for booking payments
/// - Admin operations (manual issuance, balance adjustments, etc.)
///
/// All operations enforce multi-tenant isolation via [SecurityContext].
class GiftCardService {
  GiftCardService({
    required GiftCardRepository repository,
    required GiftCardTemplateRepository templateRepository,
    required StripeService stripeService,
    required EmailService emailService,
    required AuditLogRepository auditLogRepository,
    required AppConfig appConfig,
  })  : _repository = repository,
        _templateRepository = templateRepository,
        _stripeService = stripeService,
        _emailService = emailService,
        _auditLogRepository = auditLogRepository,
        _appConfig = appConfig;

  final GiftCardRepository _repository;
  final GiftCardTemplateRepository _templateRepository;
  final StripeService _stripeService;
  final EmailService _emailService;
  final AuditLogRepository _auditLogRepository;
  final AppConfig _appConfig;

  // ============================================================
  // Purchase Flow
  // ============================================================

  /// Initiate a gift card purchase.
  ///
  /// Creates a pending gift card and a Stripe Payment Intent.
  /// Returns the client secret for presenting the payment sheet.
  ///
  /// After successful payment, call [confirmGiftCardPurchase] to activate.
  Future<GiftCardPurchaseResult> purchaseGiftCard({
    required SecurityContext context,
    required int amountCents,
    required String purchaserEmail,
    String? purchaserName,
    String? recipientEmail,
    String? recipientName,
    String? personalMessage,
    String? templateId,
  }) async {
    // Validate amount
    if (amountCents < 1000) {
      throw GiftCardException(
        'Minimum gift card amount is \$10.00',
        code: 'AMOUNT_TOO_LOW',
      );
    }

    if (amountCents > 100000) {
      throw GiftCardException(
        'Maximum gift card amount is \$1,000.00',
        code: 'AMOUNT_TOO_HIGH',
      );
    }

    // Validate template if provided
    if (templateId != null) {
      final template = await _templateRepository.getTemplate(context, templateId);
      if (template == null) {
        throw GiftCardException(
          'Invalid template selected',
          code: 'INVALID_TEMPLATE',
        );
      }
      if (!template.isAmountValid(amountCents)) {
        throw GiftCardException(
          'Amount not allowed for this template',
          code: 'INVALID_AMOUNT_FOR_TEMPLATE',
        );
      }
    }

    // Create pending gift card
    final giftCard = await _repository.createGiftCard(
      context: context,
      amountCents: amountCents,
      purchaserEmail: purchaserEmail.toLowerCase().trim(),
      purchaserName: purchaserName?.trim(),
      recipientEmail: recipientEmail?.toLowerCase().trim(),
      recipientName: recipientName?.trim(),
      personalMessage: personalMessage?.trim(),
      templateId: templateId,
    );

    // Create Stripe Payment Intent via Cloud Function
    final paymentResult = await _stripeService.createPaymentIntent(
      cloudFunctionUrl: _getGiftCardPaymentUrl(),
      amountCents: amountCents,
      currency: _appConfig.paymentConfig.currency,
      metadata: {
        'giftCardId': giftCard.id,
        'businessId': context.businessId,
        'type': 'gift_card_purchase',
      },
    );

    final clientSecret = paymentResult['clientSecret'] as String?;
    if (clientSecret == null || clientSecret.isEmpty) {
      throw GiftCardException(
        'Failed to create payment intent',
        code: 'PAYMENT_INTENT_FAILED',
      );
    }

    return GiftCardPurchaseResult(
      giftCard: giftCard,
      clientSecret: clientSecret,
    );
  }

  /// Confirm a gift card purchase after successful payment.
  ///
  /// This should be called after the client-side payment sheet completes.
  /// - Activates the gift card
  /// - Calculates expiration based on template
  /// - Triggers email delivery
  Future<GiftCard> confirmGiftCardPurchase({
    required SecurityContext context,
    required String giftCardId,
    required String paymentIntentId,
  }) async {
    // Get the pending gift card
    final giftCard = await _repository.getGiftCard(context, giftCardId);
    if (giftCard == null) {
      throw GiftCardException(
        'Gift card not found',
        code: 'NOT_FOUND',
      );
    }

    if (giftCard.status != GiftCardStatus.pending) {
      throw GiftCardException(
        'Gift card is not pending activation',
        code: 'INVALID_STATUS',
      );
    }

    // Calculate expiration based on template
    DateTime? expiresAt;
    if (giftCard.templateId != null) {
      final template = await _templateRepository.getTemplate(
        context,
        giftCard.templateId!,
      );
      if (template != null && template.validityDays != null) {
        expiresAt = DateTime.now().add(Duration(days: template.validityDays!));
      }
    }

    // Activate the gift card
    final activatedCard = await _repository.activateGiftCard(
      context: context,
      giftCardId: giftCardId,
      paymentId: paymentIntentId,
      expiresAt: expiresAt,
    );

    // Trigger email delivery (non-blocking)
    _sendGiftCardEmails(context, activatedCard).catchError((error) {
      developer.log(
        'Failed to send gift card emails: $error',
        name: 'GiftCardService',
      );
    });

    return activatedCard;
  }

  // ============================================================
  // Email Delivery
  // ============================================================

  /// Send gift card emails to purchaser and recipient.
  Future<void> _sendGiftCardEmails(
    SecurityContext context,
    GiftCard giftCard,
  ) async {
    // Send confirmation to purchaser
    try {
      await _emailService.sendPlainEmail(
        recipientEmail: giftCard.purchaserEmail,
        recipientName: giftCard.purchaserName ?? 'Customer',
        subject: 'Your Gift Card Purchase Confirmation',
        body: _buildPurchaserConfirmationEmail(giftCard),
      );
    } catch (e) {
      developer.log(
        'Failed to send purchaser confirmation: $e',
        name: 'GiftCardService',
      );
    }

    // Send to recipient if different from purchaser
    if (giftCard.recipientEmail != null &&
        giftCard.recipientEmail!.toLowerCase() !=
            giftCard.purchaserEmail.toLowerCase()) {
      try {
        await _emailService.sendPlainEmail(
          recipientEmail: giftCard.recipientEmail!,
          recipientName: giftCard.recipientName ?? 'Gift Recipient',
          subject: _buildRecipientSubject(giftCard),
          body: _buildRecipientDeliveryEmail(giftCard),
        );

        // Mark as delivered
        await _repository.markDelivered(context, giftCard.id);
      } catch (e) {
        developer.log(
          'Failed to send recipient delivery email: $e',
          name: 'GiftCardService',
        );
      }
    } else {
      // Self-purchase - mark as delivered immediately
      await _repository.markDelivered(context, giftCard.id);
    }
  }

  /// Resend gift card email to recipient (admin operation).
  Future<void> resendGiftCardEmail({
    required SecurityContext context,
    required String giftCardId,
  }) async {
    context.verifyPaymentAccess();

    final giftCard = await _repository.getGiftCard(context, giftCardId);
    if (giftCard == null) {
      throw GiftCardException('Gift card not found', code: 'NOT_FOUND');
    }

    if (giftCard.status != GiftCardStatus.active) {
      throw GiftCardException(
        'Gift card is not active',
        code: 'INVALID_STATUS',
      );
    }

    final recipientEmail = giftCard.recipientEmail ?? giftCard.purchaserEmail;
    final recipientName =
        giftCard.recipientName ?? giftCard.purchaserName ?? 'Gift Recipient';

    await _emailService.sendPlainEmail(
      recipientEmail: recipientEmail,
      recipientName: recipientName,
      subject: _buildRecipientSubject(giftCard),
      body: _buildRecipientDeliveryEmail(giftCard),
    );

    _auditLogRepository.logEvent(AuditLogEntry(
      businessId: context.businessId,
      userId: context.userId,
      actionType: AuditActionType.phiWrite,
      entityType: 'GiftCard',
      entityId: giftCardId,
      metadata: {'action': 'resendEmail'},
    ));
  }

  String _buildPurchaserConfirmationEmail(GiftCard giftCard) {
    final recipientInfo = giftCard.recipientEmail != null &&
            giftCard.recipientEmail != giftCard.purchaserEmail
        ? '\n\nThis gift card will be delivered to ${giftCard.recipientEmail}.'
        : '';

    return '''
Thank you for your gift card purchase!

Gift Card Code: ${giftCard.code}
Amount: \$${giftCard.originalAmountDollars.toStringAsFixed(2)}
${giftCard.expiresAt != null ? 'Expires: ${_formatDate(giftCard.expiresAt!)}' : 'Never expires'}
$recipientInfo

Keep this email for your records.
''';
  }

  String _buildRecipientSubject(GiftCard giftCard) {
    if (giftCard.purchaserName != null) {
      return '${giftCard.purchaserName} sent you a gift!';
    }
    return 'You received a gift card!';
  }

  String _buildRecipientDeliveryEmail(GiftCard giftCard) {
    final messageSection = giftCard.personalMessage != null
        ? '\n"${giftCard.personalMessage}"\n'
        : '';

    return '''
${giftCard.purchaserName ?? 'Someone'} sent you a gift!
$messageSection
Your Gift Card Code: ${giftCard.code}
Amount: \$${giftCard.originalAmountDollars.toStringAsFixed(2)}
${giftCard.expiresAt != null ? 'Expires: ${_formatDate(giftCard.expiresAt!)}' : 'Never expires'}

How to redeem:
1. Visit our booking page
2. Select your service and appointment time
3. Enter your gift card code at checkout
4. Any remaining balance can be used for future visits

Enjoy!
''';
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  // ============================================================
  // Redemption Flow
  // ============================================================

  /// Apply a gift card to a booking.
  ///
  /// Validates the gift card and calculates the amount to apply.
  /// Does NOT deduct balance - that happens in [completeGiftCardRedemption].
  Future<GiftCardRedemptionResult> applyGiftCardToBooking({
    required SecurityContext context,
    required String giftCardCode,
    required int appointmentTotalCents,
  }) async {
    // Validate the gift card
    final validation = await validateGiftCardCode(
      context: context,
      code: giftCardCode,
    );

    if (!validation.valid) {
      throw GiftCardException(
        validation.error ?? 'Invalid gift card',
        code: validation.errorCode,
      );
    }

    final giftCard = validation.giftCard!;

    // Calculate redemption amount
    final redeemAmount = min(giftCard.remainingBalanceCents, appointmentTotalCents);
    final remainingAfter = giftCard.remainingBalanceCents - redeemAmount;
    final coversFullAmount = redeemAmount >= appointmentTotalCents;

    return GiftCardRedemptionResult(
      code: giftCardCode.toUpperCase(),
      amountCents: redeemAmount,
      remainingBalanceCents: remainingAfter,
      coversFullAmount: coversFullAmount,
      expiresAt: giftCard.expiresAt,
    );
  }

  /// Complete a gift card redemption when booking is confirmed.
  ///
  /// Actually deducts the balance and records the redemption.
  Future<GiftCardRedemption> completeGiftCardRedemption({
    required SecurityContext context,
    required String giftCardCode,
    required String appointmentId,
    required int amountCents,
    required String clientId,
  }) async {
    return await _repository.redeemGiftCard(
      context: context,
      giftCardCode: giftCardCode,
      appointmentId: appointmentId,
      amountCents: amountCents,
      clientId: clientId,
    );
  }

  // ============================================================
  // Admin Operations (delegate to repository with additional logging)
  // ============================================================

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

    // Send email to recipient
    _sendGiftCardEmails(context, activatedCard).catchError((error) {
      developer.log(
        'Failed to send manual gift card emails: $error',
        name: 'GiftCardService',
      );
    });

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

  /// Update a gift card. Delegates to repository.
  Future<void> updateGiftCard({
    required SecurityContext context,
    required String giftCardId,
    required Map<String, dynamic> updates,
  }) async {
    await _repository.updateGiftCard(
      context: context,
      giftCardId: giftCardId,
      updates: updates,
    );
  }

  // ============================================================
  // Validation Helpers
  // ============================================================

  /// Validate a gift card code.
  ///
  /// Checks:
  /// - Format matches "GIFT-XXXX-XXXX"
  /// - Card exists
  /// - Status is active
  /// - Not expired
  Future<GiftCardValidationResult> validateGiftCardCode({
    required SecurityContext context,
    required String code,
  }) async {
    final normalizedCode = code.toUpperCase().trim();

    // Check format
    final formatRegex = RegExp(r'^GIFT-[A-HJ-NP-Z2-9]{4}-[A-HJ-NP-Z2-9]{4}$');
    if (!formatRegex.hasMatch(normalizedCode)) {
      return GiftCardValidationResult.failure(
        'Invalid gift card code format',
        errorCode: 'INVALID_FORMAT',
      );
    }

    // Check if card exists
    final giftCard = await _repository.getGiftCardByCode(context, normalizedCode);
    if (giftCard == null) {
      return GiftCardValidationResult.failure(
        'Gift card not found',
        errorCode: 'NOT_FOUND',
      );
    }

    // Check status
    if (giftCard.status != GiftCardStatus.active) {
      return GiftCardValidationResult.failure(
        'Gift card is ${giftCard.statusDisplay.toLowerCase()}',
        errorCode: 'INVALID_STATUS',
      );
    }

    // Check expiration
    if (giftCard.expiresAt != null &&
        giftCard.expiresAt!.isBefore(DateTime.now())) {
      return GiftCardValidationResult.failure(
        'Gift card has expired',
        errorCode: 'EXPIRED',
      );
    }

    // Check balance
    if (giftCard.remainingBalanceCents <= 0) {
      return GiftCardValidationResult.failure(
        'Gift card has no remaining balance',
        errorCode: 'NO_BALANCE',
      );
    }

    return GiftCardValidationResult.success(giftCard);
  }

  /// Get sanitized gift card details for client display.
  ///
  /// Hides internal IDs and sensitive data.
  Future<GiftCardDetails?> getGiftCardDetails({
    required SecurityContext context,
    required String code,
  }) async {
    final giftCard = await _repository.getGiftCardByCode(context, code.toUpperCase());
    if (giftCard == null) return null;

    String? templateImageUrl;
    if (giftCard.templateId != null) {
      final template = await _templateRepository.getTemplate(
        context,
        giftCard.templateId!,
      );
      templateImageUrl = template?.imageUrl;
    }

    return GiftCardDetails(
      code: giftCard.code,
      originalAmountCents: giftCard.originalAmountCents,
      remainingBalanceCents: giftCard.remainingBalanceCents,
      status: giftCard.status,
      isValid: giftCard.isValid,
      expiresAt: giftCard.expiresAt,
      purchaserName: giftCard.purchaserName,
      recipientName: giftCard.recipientName,
      personalMessage: giftCard.personalMessage,
      templateImageUrl: templateImageUrl ?? giftCard.customImageUrl,
    );
  }

  // ============================================================
  // Query Methods (Delegate to Repository)
  // ============================================================

  /// Stream gift cards for the business.
  Stream<List<GiftCard>> watchGiftCards(
    SecurityContext context, {
    GiftCardStatus? status,
    int limit = 50,
  }) {
    return _repository.watchGiftCards(context, status: status, limit: limit);
  }

  /// Get gift card statistics.
  Future<GiftCardStats> getGiftCardStats(SecurityContext context) {
    return _repository.getGiftCardStats(context);
  }

  /// Get gift cards purchased by a specific email.
  Future<List<GiftCard>> getGiftCardsByPurchaser({
    required SecurityContext context,
    required String purchaserEmail,
  }) {
    return _repository.getGiftCardsByPurchaser(
      context: context,
      purchaserEmail: purchaserEmail,
    );
  }

  /// Get templates for the business.
  Future<List<GiftCardTemplate>> getTemplates(
    SecurityContext context, {
    bool activeOnly = true,
  }) {
    return _templateRepository.getTemplates(context, activeOnly: activeOnly);
  }

  /// Stream templates for the business.
  Stream<List<GiftCardTemplate>> watchTemplates(
    SecurityContext context, {
    bool activeOnly = true,
  }) {
    return _templateRepository.watchTemplates(context, activeOnly: activeOnly);
  }

  // ============================================================
  // Private Helpers
  // ============================================================

  String _getGiftCardPaymentUrl() {
    // Use dedicated gift card endpoint if configured
    final giftCardUrl = _appConfig.paymentConfig.giftCardPaymentFunctionUrl;
    if (giftCardUrl != null && giftCardUrl.isNotEmpty) {
      return giftCardUrl;
    }

    // Fallback: derive from base payment intent URL
    final baseUrl = _appConfig.paymentConfig.paymentIntentFunctionUrl;
    final uri = Uri.parse(baseUrl);
    return uri
        .replace(
          path: uri.path.replaceFirst(
            'createPaymentIntent',
            'createGiftCardPayment',
          ),
        )
        .toString();
  }
}
