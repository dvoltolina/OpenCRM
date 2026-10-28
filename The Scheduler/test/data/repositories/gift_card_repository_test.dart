import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_scheduler/data/models/gift_card.dart';
import 'package:the_scheduler/data/models/security_context.dart';
import 'package:the_scheduler/data/repositories/gift_card_repository.dart';

import '../../helpers/mock_repositories.dart';
import '../../helpers/test_data_factories.dart';

void main() {
  group('GiftCardRepository', () {
    late GiftCardRepository repository;
    late FakeFirebaseFirestore fakeFirestore;
    late MockAuditLogRepository mockAuditLog;
    late SecurityContext adminContext;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      mockAuditLog = MockAuditLogRepository();
      repository = GiftCardRepository(
        firestore: fakeFirestore,
        auditLogRepository: mockAuditLog,
      );
      adminContext = TestData.securityContext(
        role: UserRole.admin,
        businessId: 'test-business',
      );
    });

    group('CRUD Operations', () {
      test('creates gift card with pending status', () async {
        final giftCard = await repository.createGiftCard(
          context: adminContext,
          amountCents: 5000,
          purchaserEmail: 'buyer@example.com',
          purchaserName: 'John Buyer',
        );

        expect(giftCard.id, isNotEmpty);
        expect(giftCard.code, isNotEmpty);
        expect(giftCard.code.length, greaterThanOrEqualTo(12));
        expect(giftCard.originalAmountCents, 5000);
        expect(giftCard.remainingBalanceCents, 5000);
        expect(giftCard.status, GiftCardStatus.pending);
        expect(giftCard.purchaserEmail, 'buyer@example.com');
        expect(giftCard.purchaserName, 'John Buyer');
        expect(giftCard.businessId, 'test-business');
      });

      test('creates gift card with recipient info', () async {
        final giftCard = await repository.createGiftCard(
          context: adminContext,
          amountCents: 10000,
          purchaserEmail: 'buyer@example.com',
          recipientEmail: 'recipient@example.com',
          recipientName: 'Jane Recipient',
          personalMessage: 'Happy Birthday!',
          templateId: 'template-1',
        );

        expect(giftCard.recipientEmail, 'recipient@example.com');
        expect(giftCard.recipientName, 'Jane Recipient');
        expect(giftCard.personalMessage, 'Happy Birthday!');
        expect(giftCard.templateId, 'template-1');
      });

      test('generates unique codes', () async {
        final codes = <String>[];
        for (int i = 0; i < 10; i++) {
          final giftCard = await repository.createGiftCard(
            context: adminContext,
            amountCents: 5000,
            purchaserEmail: 'buyer@example.com',
          );
          codes.add(giftCard.code);
        }

        // All codes should be unique
        expect(codes.toSet().length, codes.length);
      });

      test('gets gift card by ID', () async {
        final created = await repository.createGiftCard(
          context: adminContext,
          amountCents: 7500,
          purchaserEmail: 'buyer@example.com',
        );

        final retrieved = await repository.getGiftCard(adminContext, created.id);

        expect(retrieved, isNotNull);
        expect(retrieved!.id, created.id);
        expect(retrieved.code, created.code);
        expect(retrieved.originalAmountCents, 7500);
      });

      test('returns null for non-existent gift card', () async {
        final result = await repository.getGiftCard(
          adminContext,
          'non-existent-id',
        );

        expect(result, isNull);
      });

      test('gets gift card by code', () async {
        final created = await repository.createGiftCard(
          context: adminContext,
          amountCents: 5000,
          purchaserEmail: 'buyer@example.com',
        );

        final retrieved = await repository.getGiftCardByCode(
          adminContext,
          created.code,
        );

        expect(retrieved, isNotNull);
        expect(retrieved!.id, created.id);
      });

      test('gets gift card by code case-insensitively', () async {
        final created = await repository.createGiftCard(
          context: adminContext,
          amountCents: 5000,
          purchaserEmail: 'buyer@example.com',
        );

        final retrieved = await repository.getGiftCardByCode(
          adminContext,
          created.code.toLowerCase(),
        );

        expect(retrieved, isNotNull);
        expect(retrieved!.id, created.id);
      });

      test('returns null for invalid code', () async {
        final result = await repository.getGiftCardByCode(
          adminContext,
          'INVALID-CODE-123',
        );

        expect(result, isNull);
      });

      test('activates pending gift card', () async {
        final pending = await repository.createGiftCard(
          context: adminContext,
          amountCents: 5000,
          purchaserEmail: 'buyer@example.com',
        );

        final expiresAt = DateTime.now().add(const Duration(days: 365));
        final activated = await repository.activateGiftCard(
          context: adminContext,
          giftCardId: pending.id,
          paymentId: 'pi_test_123',
          expiresAt: expiresAt,
        );

        expect(activated.status, GiftCardStatus.active);
        expect(activated.paymentId, 'pi_test_123');
        expect(activated.activatedAt, isNotNull);
      });

      test('voids active gift card', () async {
        final giftCard = await repository.createGiftCard(
          context: adminContext,
          amountCents: 5000,
          purchaserEmail: 'buyer@example.com',
        );

        await repository.activateGiftCard(
          context: adminContext,
          giftCardId: giftCard.id,
          paymentId: 'pi_test_123',
        );

        await repository.voidGiftCard(
          context: adminContext,
          giftCardId: giftCard.id,
          reason: 'Customer requested refund',
        );

        final voided = await repository.getGiftCard(adminContext, giftCard.id);
        expect(voided!.status, GiftCardStatus.voided);
      });

      test('updates gift card fields', () async {
        final giftCard = await repository.createGiftCard(
          context: adminContext,
          amountCents: 5000,
          purchaserEmail: 'buyer@example.com',
        );

        await repository.updateGiftCard(
          context: adminContext,
          giftCardId: giftCard.id,
          updates: {
            'remainingBalanceCents': 6000,
            'personalMessage': 'Updated message',
          },
        );

        final updated = await repository.getGiftCard(adminContext, giftCard.id);
        expect(updated!.remainingBalanceCents, 6000);
        expect(updated.personalMessage, 'Updated message');
      });
    });

    group('Redemption Operations', () {
      late GiftCard activeCard;

      setUp(() async {
        activeCard = await repository.createGiftCard(
          context: adminContext,
          amountCents: 10000, // $100
          purchaserEmail: 'buyer@example.com',
        );

        await repository.activateGiftCard(
          context: adminContext,
          giftCardId: activeCard.id,
          paymentId: 'pi_test_123',
        );
      });

      test('redeems partial balance successfully', () async {
        final redemption = await repository.redeemGiftCard(
          context: adminContext,
          giftCardCode: activeCard.code,
          appointmentId: 'appt-123',
          amountCents: 5000, // $50
          clientId: 'client-1',
        );

        expect(redemption.amountCents, 5000);
        expect(redemption.appointmentId, 'appt-123');
        expect(redemption.giftCardId, activeCard.id);
        expect(redemption.redeemedByClientId, 'client-1');

        final updated = await repository.getGiftCard(adminContext, activeCard.id);
        expect(updated!.remainingBalanceCents, 5000);
        expect(updated.status, GiftCardStatus.active);
      });

      test('depletes card when full balance used', () async {
        final redemption = await repository.redeemGiftCard(
          context: adminContext,
          giftCardCode: activeCard.code,
          appointmentId: 'appt-123',
          amountCents: 10000, // Full balance
          clientId: 'client-1',
        );

        expect(redemption.amountCents, 10000);

        final updated = await repository.getGiftCard(adminContext, activeCard.id);
        expect(updated!.remainingBalanceCents, 0);
        expect(updated.status, GiftCardStatus.depleted);
      });

      test('throws error for insufficient balance', () async {
        expect(
          () => repository.redeemGiftCard(
            context: adminContext,
            giftCardCode: activeCard.code,
            appointmentId: 'appt-123',
            amountCents: 15000, // More than $100 balance
            clientId: 'client-1',
          ),
          throwsA(isA<GiftCardException>().having(
            (e) => e.code,
            'code',
            'INSUFFICIENT_BALANCE',
          )),
        );
      });

      test('throws error for invalid code', () async {
        expect(
          () => repository.redeemGiftCard(
            context: adminContext,
            giftCardCode: 'INVALID-CODE',
            appointmentId: 'appt-123',
            amountCents: 5000,
            clientId: 'client-1',
          ),
          throwsA(isA<GiftCardException>().having(
            (e) => e.code,
            'code',
            'INVALID_CODE',
          )),
        );
      });

      test('throws error for expired card', () async {
        // Create and activate a card that's already expired
        final expiredCard = await repository.createGiftCard(
          context: adminContext,
          amountCents: 5000,
          purchaserEmail: 'buyer@example.com',
        );

        await repository.activateGiftCard(
          context: adminContext,
          giftCardId: expiredCard.id,
          paymentId: 'pi_test_456',
          expiresAt: DateTime.now().subtract(const Duration(days: 1)),
        );

        expect(
          () => repository.redeemGiftCard(
            context: adminContext,
            giftCardCode: expiredCard.code,
            appointmentId: 'appt-123',
            amountCents: 2500,
            clientId: 'client-1',
          ),
          throwsA(isA<GiftCardException>().having(
            (e) => e.code,
            'code',
            'EXPIRED',
          )),
        );
      });

      test('throws error for inactive card', () async {
        // Create a pending card (not activated)
        final pendingCard = await repository.createGiftCard(
          context: adminContext,
          amountCents: 5000,
          purchaserEmail: 'buyer@example.com',
        );

        expect(
          () => repository.redeemGiftCard(
            context: adminContext,
            giftCardCode: pendingCard.code,
            appointmentId: 'appt-123',
            amountCents: 2500,
            clientId: 'client-1',
          ),
          throwsA(isA<GiftCardException>().having(
            (e) => e.code,
            'code',
            'INACTIVE',
          )),
        );
      });

      test('handles multiple redemptions', () async {
        // First redemption
        await repository.redeemGiftCard(
          context: adminContext,
          giftCardCode: activeCard.code,
          appointmentId: 'appt-1',
          amountCents: 3000, // $30
          clientId: 'client-1',
        );

        // Second redemption
        await repository.redeemGiftCard(
          context: adminContext,
          giftCardCode: activeCard.code,
          appointmentId: 'appt-2',
          amountCents: 4000, // $40
          clientId: 'client-1',
        );

        final updated = await repository.getGiftCard(adminContext, activeCard.id);
        expect(updated!.remainingBalanceCents, 3000); // $30 remaining
        expect(updated.status, GiftCardStatus.active);
      });
    });

    group('Balance Checking', () {
      test('returns valid balance for active card', () async {
        final giftCard = await repository.createGiftCard(
          context: adminContext,
          amountCents: 5000,
          purchaserEmail: 'buyer@example.com',
        );

        await repository.activateGiftCard(
          context: adminContext,
          giftCardId: giftCard.id,
          paymentId: 'pi_test_123',
        );

        final balance = await repository.checkBalance(
          businessId: 'test-business',
          code: giftCard.code,
        );

        expect(balance.valid, true);
        expect(balance.balanceCents, 5000);
        expect(balance.code, giftCard.code);
      });

      test('returns invalid for non-existent code', () async {
        final balance = await repository.checkBalance(
          businessId: 'test-business',
          code: 'INVALID-CODE',
        );

        expect(balance.valid, false);
        expect(balance.balanceCents, 0);
      });

      test('returns invalid for pending card', () async {
        final giftCard = await repository.createGiftCard(
          context: adminContext,
          amountCents: 5000,
          purchaserEmail: 'buyer@example.com',
        );

        final balance = await repository.checkBalance(
          businessId: 'test-business',
          code: giftCard.code,
        );

        expect(balance.valid, false);
        expect(balance.balanceCents, 0);
      });

      test('returns invalid for expired card', () async {
        final giftCard = await repository.createGiftCard(
          context: adminContext,
          amountCents: 5000,
          purchaserEmail: 'buyer@example.com',
        );

        await repository.activateGiftCard(
          context: adminContext,
          giftCardId: giftCard.id,
          paymentId: 'pi_test_123',
          expiresAt: DateTime.now().subtract(const Duration(days: 1)),
        );

        final balance = await repository.checkBalance(
          businessId: 'test-business',
          code: giftCard.code,
        );

        expect(balance.valid, false);
        expect(balance.balanceCents, 0);
      });

      test('includes expiration date when set', () async {
        final expiresAt = DateTime.now().add(const Duration(days: 365));
        final giftCard = await repository.createGiftCard(
          context: adminContext,
          amountCents: 5000,
          purchaserEmail: 'buyer@example.com',
        );

        await repository.activateGiftCard(
          context: adminContext,
          giftCardId: giftCard.id,
          paymentId: 'pi_test_123',
          expiresAt: expiresAt,
        );

        final balance = await repository.checkBalance(
          businessId: 'test-business',
          code: giftCard.code,
        );

        expect(balance.expiresAt, isNotNull);
      });
    });

    group('Query Operations', () {
      setUp(() async {
        // Create various gift cards
        for (int i = 0; i < 5; i++) {
          final gc = await repository.createGiftCard(
            context: adminContext,
            amountCents: 5000 + (i * 1000),
            purchaserEmail: 'buyer$i@example.com',
          );

          if (i < 3) {
            // Activate first 3
            await repository.activateGiftCard(
              context: adminContext,
              giftCardId: gc.id,
              paymentId: 'pi_$i',
            );
          }
        }
      });

      test('watches gift cards stream', () async {
        final stream = repository.watchGiftCards(adminContext);

        await expectLater(
          stream.first,
          completion(hasLength(5)),
        );
      });

      test('watches with status filter', () async {
        final stream = repository.watchGiftCards(
          adminContext,
          status: GiftCardStatus.pending,
        );

        await expectLater(
          stream.first,
          completion(hasLength(2)),
        );
      });

      test('watches with limit', () async {
        final stream = repository.watchGiftCards(
          adminContext,
          limit: 3,
        );

        await expectLater(
          stream.first,
          completion(hasLength(3)),
        );
      });

      test('watches active cards only', () async {
        final stream = repository.watchGiftCards(
          adminContext,
          status: GiftCardStatus.active,
        );

        final cards = await stream.first;
        expect(cards.length, 3);
        expect(
          cards.every((gc) => gc.status == GiftCardStatus.active),
          true,
        );
      });
    });

    group('Stats Aggregation', () {
      test('calculates correct stats', () async {
        // Create some gift cards with various states
        final gc1 = await repository.createGiftCard(
          context: adminContext,
          amountCents: 5000,
          purchaserEmail: 'buyer1@example.com',
        );
        await repository.activateGiftCard(
          context: adminContext,
          giftCardId: gc1.id,
          paymentId: 'pi_1',
        );

        final gc2 = await repository.createGiftCard(
          context: adminContext,
          amountCents: 10000,
          purchaserEmail: 'buyer2@example.com',
        );
        await repository.activateGiftCard(
          context: adminContext,
          giftCardId: gc2.id,
          paymentId: 'pi_2',
        );

        // Redeem part of gc1
        await repository.redeemGiftCard(
          context: adminContext,
          giftCardCode: gc1.code,
          appointmentId: 'appt-1',
          amountCents: 3000,
          clientId: 'client-1',
        );

        final stats = await repository.getGiftCardStats(adminContext);

        expect(stats.totalSoldCount, 2);
        expect(stats.totalSoldCents, 15000);
        expect(stats.outstandingBalanceCents, 12000); // 5000-3000 + 10000
        expect(stats.totalRedeemedCents, 3000);
        expect(stats.redemptionCount, 1);
      });
    });

    group('Audit Logging', () {
      test('logs create event', () async {
        await repository.createGiftCard(
          context: adminContext,
          amountCents: 5000,
          purchaserEmail: 'buyer@example.com',
        );

        expect(mockAuditLog.loggedEvents, hasLength(1));
        expect(
          mockAuditLog.loggedEvents.first.metadata['action'],
          'create',
        );
      });

      test('logs activate event', () async {
        final gc = await repository.createGiftCard(
          context: adminContext,
          amountCents: 5000,
          purchaserEmail: 'buyer@example.com',
        );

        await repository.activateGiftCard(
          context: adminContext,
          giftCardId: gc.id,
          paymentId: 'pi_test',
        );

        expect(mockAuditLog.loggedEvents, hasLength(2));
        expect(
          mockAuditLog.loggedEvents.last.metadata['action'],
          'activate',
        );
      });

      test('logs redeem event', () async {
        final gc = await repository.createGiftCard(
          context: adminContext,
          amountCents: 5000,
          purchaserEmail: 'buyer@example.com',
        );

        await repository.activateGiftCard(
          context: adminContext,
          giftCardId: gc.id,
          paymentId: 'pi_test',
        );

        await repository.redeemGiftCard(
          context: adminContext,
          giftCardCode: gc.code,
          appointmentId: 'appt-1',
          amountCents: 2500,
          clientId: 'client-1',
        );

        expect(mockAuditLog.loggedEvents.length, greaterThanOrEqualTo(3));
        final redeemEvent = mockAuditLog.loggedEvents.firstWhere(
          (e) => e.metadata['action'] == 'redeem',
        );
        expect(redeemEvent.metadata['amountCents'], 2500);
      });

      test('logs void event', () async {
        final gc = await repository.createGiftCard(
          context: adminContext,
          amountCents: 5000,
          purchaserEmail: 'buyer@example.com',
        );

        await repository.voidGiftCard(
          context: adminContext,
          giftCardId: gc.id,
          reason: 'Test void',
        );

        final voidEvent = mockAuditLog.loggedEvents.firstWhere(
          (e) => e.metadata['action'] == 'void',
        );
        expect(voidEvent.metadata['reason'], 'Test void');
      });
    });

    group('Security', () {
      test('enforces business isolation', () async {
        final otherContext = TestData.securityContext(
          businessId: 'other-business',
          role: UserRole.admin,
        );

        final gc = await repository.createGiftCard(
          context: adminContext,
          amountCents: 5000,
          purchaserEmail: 'buyer@example.com',
        );

        // Should not find the card from different business
        final result = await repository.getGiftCard(otherContext, gc.id);
        expect(result, isNull);
      });
    });
  });
}
