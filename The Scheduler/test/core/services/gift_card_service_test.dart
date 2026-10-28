import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_scheduler/core/config/communication_config.dart';
import 'package:the_scheduler/core/services/email_service.dart';
import 'package:the_scheduler/core/services/gift_card_service.dart';
import 'package:the_scheduler/core/services/stripe_service.dart';
import 'package:the_scheduler/data/models/gift_card.dart';
import 'package:the_scheduler/data/models/security_context.dart';
import 'package:the_scheduler/data/repositories/gift_card_repository.dart';
import 'package:the_scheduler/data/repositories/gift_card_template_repository.dart';

import '../../helpers/mock_repositories.dart';
import '../../helpers/test_data_factories.dart';

void main() {
  group('GiftCardService', () {
    late GiftCardService service;
    late GiftCardRepository repository;
    late GiftCardTemplateRepository templateRepository;
    late MockStripeService mockStripe;
    late MockEmailService mockEmail;
    late MockAuditLogRepository mockAuditLog;
    late FakeFirebaseFirestore fakeFirestore;
    late SecurityContext adminContext;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      mockAuditLog = MockAuditLogRepository();
      mockStripe = MockStripeService();
      mockEmail = MockEmailService();

      repository = GiftCardRepository(
        firestore: fakeFirestore,
        auditLogRepository: mockAuditLog,
      );

      templateRepository = GiftCardTemplateRepository(
        firestore: fakeFirestore,
        auditLogRepository: mockAuditLog,
      );

      service = GiftCardService(
        repository: repository,
        templateRepository: templateRepository,
        stripeService: mockStripe,
        emailService: mockEmail,
        auditLogRepository: mockAuditLog,
        appConfig: TestData.createTestConfig(enablePayments: true),
      );

      adminContext = TestData.securityContext(
        role: UserRole.admin,
        businessId: 'test-business',
      );
    });

    group('Purchase Flow', () {
      test('creates pending gift card and returns client secret', () async {
        mockStripe.clientSecret = 'pi_test_secret';

        final result = await service.purchaseGiftCard(
          context: adminContext,
          amountCents: 5000,
          purchaserEmail: 'buyer@example.com',
          purchaserName: 'John Buyer',
        );

        expect(result.giftCard.status, GiftCardStatus.pending);
        expect(result.giftCard.originalAmountCents, 5000);
        expect(result.giftCard.purchaserEmail, 'buyer@example.com');
        expect(result.clientSecret, 'pi_test_secret');
      });

      test('validates minimum amount', () async {
        expect(
          () => service.purchaseGiftCard(
            context: adminContext,
            amountCents: 500, // Less than $10
            purchaserEmail: 'buyer@example.com',
          ),
          throwsA(isA<GiftCardException>().having(
            (e) => e.code,
            'code',
            'AMOUNT_TOO_LOW',
          )),
        );
      });

      test('validates maximum amount', () async {
        expect(
          () => service.purchaseGiftCard(
            context: adminContext,
            amountCents: 150000, // More than $1000
            purchaserEmail: 'buyer@example.com',
          ),
          throwsA(isA<GiftCardException>().having(
            (e) => e.code,
            'code',
            'AMOUNT_TOO_HIGH',
          )),
        );
      });

      test('includes recipient information', () async {
        mockStripe.clientSecret = 'pi_test_secret';

        final result = await service.purchaseGiftCard(
          context: adminContext,
          amountCents: 10000,
          purchaserEmail: 'buyer@example.com',
          recipientEmail: 'recipient@example.com',
          recipientName: 'Jane Recipient',
          personalMessage: 'Happy Birthday!',
        );

        expect(result.giftCard.recipientEmail, 'recipient@example.com');
        expect(result.giftCard.recipientName, 'Jane Recipient');
        expect(result.giftCard.personalMessage, 'Happy Birthday!');
      });

      test('validates template amount limits', () async {
        // Create a template with amount limits
        await templateRepository.createTemplate(
          context: adminContext,
          name: 'Limited Template',
          description: 'Test',
          imageUrl: '',
          backgroundColor: '#FFFFFF',
          textColor: '#000000',
          minAmountCents: 2500, // $25 min
          maxAmountCents: 10000, // $100 max
        );

        final templates = await templateRepository.getTemplates(adminContext);
        final templateId = templates.first.id;

        // Should fail - below minimum
        expect(
          () => service.purchaseGiftCard(
            context: adminContext,
            amountCents: 1500, // Below $25 template min
            purchaserEmail: 'buyer@example.com',
            templateId: templateId,
          ),
          throwsA(isA<GiftCardException>().having(
            (e) => e.code,
            'code',
            'INVALID_AMOUNT_FOR_TEMPLATE',
          )),
        );
      });
    });

    group('Confirmation Flow', () {
      test('activates pending gift card', () async {
        mockStripe.clientSecret = 'pi_test_secret';

        final purchase = await service.purchaseGiftCard(
          context: adminContext,
          amountCents: 5000,
          purchaserEmail: 'buyer@example.com',
        );

        final confirmed = await service.confirmGiftCardPurchase(
          context: adminContext,
          giftCardId: purchase.giftCard.id,
          paymentIntentId: 'pi_completed_123',
        );

        expect(confirmed.status, GiftCardStatus.active);
        expect(confirmed.paymentId, 'pi_completed_123');
        expect(confirmed.activatedAt, isNotNull);
      });

      test('calculates expiration from template', () async {
        // Create template with validity days
        await templateRepository.createTemplate(
          context: adminContext,
          name: 'Expiring Template',
          description: 'Test',
          imageUrl: '',
          backgroundColor: '#FFFFFF',
          textColor: '#000000',
          validityDays: 365,
        );

        final templates = await templateRepository.getTemplates(adminContext);
        final templateId = templates.first.id;

        mockStripe.clientSecret = 'pi_test_secret';

        final purchase = await service.purchaseGiftCard(
          context: adminContext,
          amountCents: 5000,
          purchaserEmail: 'buyer@example.com',
          templateId: templateId,
        );

        final confirmed = await service.confirmGiftCardPurchase(
          context: adminContext,
          giftCardId: purchase.giftCard.id,
          paymentIntentId: 'pi_completed_123',
        );

        expect(confirmed.expiresAt, isNotNull);
        expect(
          confirmed.expiresAt!.difference(DateTime.now()).inDays,
          greaterThanOrEqualTo(364),
        );
      });

      test('throws error for non-pending card', () async {
        mockStripe.clientSecret = 'pi_test_secret';

        final purchase = await service.purchaseGiftCard(
          context: adminContext,
          amountCents: 5000,
          purchaserEmail: 'buyer@example.com',
        );

        // Activate once
        await service.confirmGiftCardPurchase(
          context: adminContext,
          giftCardId: purchase.giftCard.id,
          paymentIntentId: 'pi_completed_123',
        );

        // Try to activate again
        expect(
          () => service.confirmGiftCardPurchase(
            context: adminContext,
            giftCardId: purchase.giftCard.id,
            paymentIntentId: 'pi_another_123',
          ),
          throwsA(isA<GiftCardException>().having(
            (e) => e.code,
            'code',
            'INVALID_STATUS',
          )),
        );
      });
    });

    group('Redemption Flow', () {
      late GiftCard activeCard;

      setUp(() async {
        mockStripe.clientSecret = 'pi_test_secret';

        final purchase = await service.purchaseGiftCard(
          context: adminContext,
          amountCents: 10000, // $100
          purchaserEmail: 'buyer@example.com',
        );

        activeCard = await service.confirmGiftCardPurchase(
          context: adminContext,
          giftCardId: purchase.giftCard.id,
          paymentIntentId: 'pi_completed_123',
        );
      });

      test('calculates correct redemption amount', () async {
        final result = await service.applyGiftCardToBooking(
          context: adminContext,
          giftCardCode: activeCard.code,
          appointmentTotalCents: 7500, // $75 appointment
        );

        expect(result.amountCents, 7500); // Use $75
        expect(result.remainingBalanceCents, 2500); // $25 remaining
        expect(result.coversFullAmount, true);
      });

      test('limits redemption to available balance', () async {
        final result = await service.applyGiftCardToBooking(
          context: adminContext,
          giftCardCode: activeCard.code,
          appointmentTotalCents: 15000, // $150 appointment (more than balance)
        );

        expect(result.amountCents, 10000); // Only $100 available
        expect(result.remainingBalanceCents, 0);
        expect(result.coversFullAmount, false);
      });

      test('completes redemption successfully', () async {
        final redemption = await service.completeGiftCardRedemption(
          context: adminContext,
          giftCardCode: activeCard.code,
          appointmentId: 'appt-123',
          amountCents: 5000, // $50
          clientId: 'client-1',
        );

        expect(redemption.amountCents, 5000);
        expect(redemption.appointmentId, 'appt-123');
      });

      test('throws error for invalid code', () async {
        expect(
          () => service.applyGiftCardToBooking(
            context: adminContext,
            giftCardCode: 'INVALID-CODE',
            appointmentTotalCents: 5000,
          ),
          throwsA(isA<GiftCardException>()),
        );
      });
    });

    group('Code Validation', () {
      late GiftCard activeCard;

      setUp(() async {
        mockStripe.clientSecret = 'pi_test_secret';

        final purchase = await service.purchaseGiftCard(
          context: adminContext,
          amountCents: 5000,
          purchaserEmail: 'buyer@example.com',
        );

        activeCard = await service.confirmGiftCardPurchase(
          context: adminContext,
          giftCardId: purchase.giftCard.id,
          paymentIntentId: 'pi_completed_123',
        );
      });

      test('validates active card successfully', () async {
        final result = await service.validateGiftCardCode(
          context: adminContext,
          code: activeCard.code,
        );

        expect(result.valid, true);
        expect(result.giftCard, isNotNull);
        expect(result.giftCard!.code, activeCard.code);
      });

      test('rejects invalid format', () async {
        final result = await service.validateGiftCardCode(
          context: adminContext,
          code: 'INVALID',
        );

        expect(result.valid, false);
        expect(result.errorCode, 'INVALID_FORMAT');
      });

      test('rejects non-existent code', () async {
        final result = await service.validateGiftCardCode(
          context: adminContext,
          code: 'GIFT-ZZZZ-ZZZZ',
        );

        expect(result.valid, false);
        expect(result.errorCode, 'NOT_FOUND');
      });

      test('rejects voided card', () async {
        await service.voidGiftCard(
          context: adminContext,
          giftCardId: activeCard.id,
          reason: 'Test void',
        );

        final result = await service.validateGiftCardCode(
          context: adminContext,
          code: activeCard.code,
        );

        expect(result.valid, false);
        expect(result.errorCode, 'INVALID_STATUS');
      });
    });

    group('Admin Operations', () {
      group('Manual Issuance', () {
        test('creates and activates gift card without payment', () async {
          final giftCard = await service.issueManualGiftCard(
            context: adminContext,
            amountCents: 5000,
            recipientEmail: 'recipient@example.com',
            reason: 'Customer appreciation',
          );

          expect(giftCard.status, GiftCardStatus.active);
          expect(giftCard.originalAmountCents, 5000);
          expect(giftCard.paymentId, startsWith('MANUAL-'));
        });

        test('sets expiration when provided', () async {
          final expiresAt = DateTime.now().add(const Duration(days: 90));

          final giftCard = await service.issueManualGiftCard(
            context: adminContext,
            amountCents: 5000,
            recipientEmail: 'recipient@example.com',
            reason: 'Promotional',
            expiresAt: expiresAt,
          );

          expect(giftCard.expiresAt, isNotNull);
        });

        test('logs manual issuance for audit', () async {
          await service.issueManualGiftCard(
            context: adminContext,
            amountCents: 5000,
            recipientEmail: 'recipient@example.com',
            reason: 'Test reason',
          );

          final manualIssueEvent = mockAuditLog.loggedEvents.firstWhere(
            (e) => e.metadata['action'] == 'manualIssue',
          );
          expect(manualIssueEvent.metadata['reason'], 'Test reason');
        });
      });

      group('Balance Adjustment', () {
        late GiftCard activeCard;

        setUp(() async {
          activeCard = await service.issueManualGiftCard(
            context: adminContext,
            amountCents: 5000,
            recipientEmail: 'recipient@example.com',
            reason: 'Test',
          );
        });

        test('increases balance', () async {
          final updated = await service.adjustGiftCardBalance(
            context: adminContext,
            giftCardId: activeCard.id,
            adjustmentCents: 2000, // Add $20
            reason: 'Goodwill credit',
          );

          expect(updated.remainingBalanceCents, 7000);
        });

        test('decreases balance', () async {
          final updated = await service.adjustGiftCardBalance(
            context: adminContext,
            giftCardId: activeCard.id,
            adjustmentCents: -2000, // Remove $20
            reason: 'Correction',
          );

          expect(updated.remainingBalanceCents, 3000);
        });

        test('throws error for negative resulting balance', () async {
          expect(
            () => service.adjustGiftCardBalance(
              context: adminContext,
              giftCardId: activeCard.id,
              adjustmentCents: -10000, // More than balance
              reason: 'Invalid',
            ),
            throwsA(isA<GiftCardException>().having(
              (e) => e.code,
              'code',
              'INVALID_ADJUSTMENT',
            )),
          );
        });

        test('changes status to depleted when balance reaches zero', () async {
          final updated = await service.adjustGiftCardBalance(
            context: adminContext,
            giftCardId: activeCard.id,
            adjustmentCents: -5000, // Remove all balance
            reason: 'Test depletion',
          );

          expect(updated.remainingBalanceCents, 0);
          expect(updated.status, GiftCardStatus.depleted);
        });
      });

      group('Expiration Extension', () {
        late GiftCard activeCard;

        setUp(() async {
          activeCard = await service.issueManualGiftCard(
            context: adminContext,
            amountCents: 5000,
            recipientEmail: 'recipient@example.com',
            reason: 'Test',
            expiresAt: DateTime.now().add(const Duration(days: 30)),
          );
        });

        test('extends expiration date', () async {
          final newExpiration = DateTime.now().add(const Duration(days: 365));

          final updated = await service.extendExpiration(
            context: adminContext,
            giftCardId: activeCard.id,
            newExpiresAt: newExpiration,
            reason: 'Customer request',
          );

          expect(
            updated.expiresAt!.difference(DateTime.now()).inDays,
            greaterThanOrEqualTo(364),
          );
        });

        test('logs extension for audit', () async {
          final newExpiration = DateTime.now().add(const Duration(days: 365));

          await service.extendExpiration(
            context: adminContext,
            giftCardId: activeCard.id,
            newExpiresAt: newExpiration,
            reason: 'Audit test',
          );

          final extendEvent = mockAuditLog.loggedEvents.firstWhere(
            (e) => e.metadata['action'] == 'extendExpiration',
          );
          expect(extendEvent.metadata['reason'], 'Audit test');
        });
      });

      group('Voiding', () {
        test('voids active gift card', () async {
          final activeCard = await service.issueManualGiftCard(
            context: adminContext,
            amountCents: 5000,
            recipientEmail: 'recipient@example.com',
            reason: 'Test',
          );

          await service.voidGiftCard(
            context: adminContext,
            giftCardId: activeCard.id,
            reason: 'Customer refund requested',
          );

          // Verify the card is voided
          final validation = await service.validateGiftCardCode(
            context: adminContext,
            code: activeCard.code,
          );

          expect(validation.valid, false);
        });
      });
    });

    group('Email Notification', () {
      test('resend email for active card', () async {
        final activeCard = await service.issueManualGiftCard(
          context: adminContext,
          amountCents: 5000,
          recipientEmail: 'recipient@example.com',
          reason: 'Test',
        );

        // Should not throw
        await service.resendGiftCardEmail(
          context: adminContext,
          giftCardId: activeCard.id,
        );

        // Verify email was sent
        expect(mockEmail.sentEmails, isNotEmpty);
      });

      test('throws error for inactive card', () async {
        mockStripe.clientSecret = 'pi_test_secret';

        final purchase = await service.purchaseGiftCard(
          context: adminContext,
          amountCents: 5000,
          purchaserEmail: 'buyer@example.com',
        );

        // Card is still pending
        expect(
          () => service.resendGiftCardEmail(
            context: adminContext,
            giftCardId: purchase.giftCard.id,
          ),
          throwsA(isA<GiftCardException>().having(
            (e) => e.code,
            'code',
            'INVALID_STATUS',
          )),
        );
      });
    });

    group('Query Methods', () {
      test('gets gift card statistics', () async {
        // Create some cards
        await service.issueManualGiftCard(
          context: adminContext,
          amountCents: 5000,
          recipientEmail: 'r1@example.com',
          reason: 'Test 1',
        );

        await service.issueManualGiftCard(
          context: adminContext,
          amountCents: 10000,
          recipientEmail: 'r2@example.com',
          reason: 'Test 2',
        );

        final stats = await service.getGiftCardStats(adminContext);

        expect(stats.totalSoldCount, 2);
        expect(stats.totalSoldCents, 15000);
        expect(stats.outstandingBalanceCents, 15000);
      });

      test('watches gift cards stream', () async {
        await service.issueManualGiftCard(
          context: adminContext,
          amountCents: 5000,
          recipientEmail: 'recipient@example.com',
          reason: 'Test',
        );

        final stream = service.watchGiftCards(adminContext);

        await expectLater(
          stream.first,
          completion(hasLength(1)),
        );
      });
    });
  });
}

// ============================================================
// Mock Classes
// ============================================================

class MockStripeService implements StripeService {
  String clientSecret = '';

  @override
  Future<Map<String, dynamic>> createPaymentIntent({
    required String cloudFunctionUrl,
    required int amountCents,
    String currency = 'usd',
    String? customerId,
    String? destinationAccountId,
    int? applicationFeeAmountCents,
    Map<String, dynamic>? metadata,
  }) async {
    if (clientSecret.isEmpty) {
      throw Exception('Stripe not configured for test');
    }
    return {'clientSecret': clientSecret};
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    // Return sensible defaults for other methods
    final memberName = invocation.memberName.toString();
    if (memberName.contains('isInitialized')) {
      return true;
    }
    if (invocation.isGetter) {
      return null;
    }
    return Future.value(<String, dynamic>{});
  }
}

class MockEmailService implements EmailService {
  final List<Map<String, dynamic>> sentEmails = [];

  @override
  Future<EmailResult> sendPlainEmail({
    required String recipientEmail,
    required String recipientName,
    required String subject,
    required String body,
    String? replyTo,
  }) async {
    sentEmails.add({
      'to': recipientEmail,
      'subject': subject,
      'body': body,
    });
    return EmailResult.success(messageId: 'mock-${sentEmails.length}');
  }

  @override
  Future<EmailResult> sendTemplatedEmail({
    required String recipientEmail,
    required String recipientName,
    required MessageTemplate template,
    required Map<String, String> variables,
  }) async {
    sentEmails.add({
      'to': recipientEmail,
      'template': template.toString(),
      'variables': variables,
    });
    return EmailResult.success(messageId: 'mock-${sentEmails.length}');
  }

  @override
  bool isValidEmail(String email) {
    return email.contains('@');
  }
}
