import 'package:flutter_test/flutter_test.dart';
import 'package:the_scheduler/data/models/gift_card.dart';
import 'package:the_scheduler/data/models/gift_card_template.dart';

void main() {
  group('GiftCard Model', () {
    group('JSON Serialization', () {
      test('serializes to JSON and back', () {
        final giftCard = GiftCard(
          id: 'gc-123',
          businessId: 'biz-456',
          code: 'GIFT-ABCD-1234',
          originalAmountCents: 5000,
          remainingBalanceCents: 5000,
          currency: 'usd',
          status: GiftCardStatus.active,
          purchaserEmail: 'buyer@example.com',
          purchaserName: 'John Buyer',
          purchasedAt: DateTime(2025, 1, 15, 10, 0),
          createdAt: DateTime(2025, 1, 15, 10, 0),
          activatedAt: DateTime(2025, 1, 15, 10, 5),
          recipientEmail: 'recipient@example.com',
          recipientName: 'Jane Recipient',
          personalMessage: 'Happy Birthday!',
          templateId: 'template-1',
        );

        final json = giftCard.toJson();
        final restored = GiftCard.fromJson(json);

        expect(restored.id, giftCard.id);
        expect(restored.businessId, giftCard.businessId);
        expect(restored.code, giftCard.code);
        expect(restored.originalAmountCents, giftCard.originalAmountCents);
        expect(restored.remainingBalanceCents, giftCard.remainingBalanceCents);
        expect(restored.currency, giftCard.currency);
        expect(restored.status, giftCard.status);
        expect(restored.purchaserEmail, giftCard.purchaserEmail);
        expect(restored.purchaserName, giftCard.purchaserName);
        expect(restored.recipientEmail, giftCard.recipientEmail);
        expect(restored.recipientName, giftCard.recipientName);
        expect(restored.personalMessage, giftCard.personalMessage);
        expect(restored.templateId, giftCard.templateId);
      });

      test('handles null optional fields', () {
        final giftCard = GiftCard(
          id: 'gc-123',
          businessId: 'biz-456',
          code: 'GIFT-ABCD-1234',
          originalAmountCents: 5000,
          remainingBalanceCents: 5000,
          status: GiftCardStatus.pending,
          purchaserEmail: 'buyer@example.com',
          purchasedAt: DateTime(2025, 1, 15),
          createdAt: DateTime(2025, 1, 15),
        );

        final json = giftCard.toJson();
        final restored = GiftCard.fromJson(json);

        expect(restored.purchaserName, isNull);
        expect(restored.recipientEmail, isNull);
        expect(restored.recipientName, isNull);
        expect(restored.personalMessage, isNull);
        expect(restored.templateId, isNull);
        expect(restored.activatedAt, isNull);
        expect(restored.expiresAt, isNull);
        expect(restored.paymentId, isNull);
      });

      test('serializes redemptions array', () {
        // Test fromJson with redemptions data as it comes from Firestore
        final json = {
          'id': 'gc-123',
          'businessId': 'biz-456',
          'code': 'GIFT-ABCD-1234',
          'originalAmountCents': 5000,
          'remainingBalanceCents': 2500,
          'currency': 'usd',
          'status': 'active',
          'purchaserEmail': 'buyer@example.com',
          'purchasedAt': '2025-01-15T00:00:00.000',
          'createdAt': '2025-01-15T00:00:00.000',
          'redemptions': [
            {
              'id': 'red-1',
              'giftCardId': 'gc-123',
              'appointmentId': 'appt-456',
              'amountCents': 2500,
              'redeemedAt': '2025-02-01T14:00:00.000',
              'redeemedByClientId': 'client-789',
            },
          ],
        };

        final restored = GiftCard.fromJson(json);

        expect(restored.redemptions.length, 1);
        expect(restored.redemptions[0].amountCents, 2500);
        expect(restored.redemptions[0].appointmentId, 'appt-456');
        expect(restored.redemptions[0].redeemedByClientId, 'client-789');
      });
    });

    group('Helper Getters', () {
      test('originalAmountDollars converts cents to dollars', () {
        final giftCard = _createGiftCard(originalAmountCents: 5000);
        expect(giftCard.originalAmountDollars, 50.0);
      });

      test('remainingBalanceDollars converts cents to dollars', () {
        final giftCard = _createGiftCard(remainingBalanceCents: 2500);
        expect(giftCard.remainingBalanceDollars, 25.0);
      });

      test('totalRedeemedCents calculates correctly', () {
        final giftCard = _createGiftCard(
          originalAmountCents: 5000,
          remainingBalanceCents: 2000,
        );
        expect(giftCard.totalRedeemedCents, 3000);
      });

      test('totalRedeemedDollars converts correctly', () {
        final giftCard = _createGiftCard(
          originalAmountCents: 5000,
          remainingBalanceCents: 2000,
        );
        expect(giftCard.totalRedeemedDollars, 30.0);
      });

      test('hasBalance returns true when balance > 0', () {
        final giftCard = _createGiftCard(remainingBalanceCents: 100);
        expect(giftCard.hasBalance, true);
      });

      test('hasBalance returns false when balance is 0', () {
        final giftCard = _createGiftCard(remainingBalanceCents: 0);
        expect(giftCard.hasBalance, false);
      });
    });

    group('isValid', () {
      test('returns true for active card with no expiration', () {
        final giftCard = _createGiftCard(
          status: GiftCardStatus.active,
          expiresAt: null,
        );
        expect(giftCard.isValid, true);
      });

      test('returns true for active card with future expiration', () {
        final giftCard = _createGiftCard(
          status: GiftCardStatus.active,
          expiresAt: DateTime.now().add(const Duration(days: 30)),
        );
        expect(giftCard.isValid, true);
      });

      test('returns false for active card with past expiration', () {
        final giftCard = _createGiftCard(
          status: GiftCardStatus.active,
          expiresAt: DateTime.now().subtract(const Duration(days: 1)),
        );
        expect(giftCard.isValid, false);
      });

      test('returns false for pending status', () {
        final giftCard = _createGiftCard(status: GiftCardStatus.pending);
        expect(giftCard.isValid, false);
      });

      test('returns false for depleted status', () {
        final giftCard = _createGiftCard(status: GiftCardStatus.depleted);
        expect(giftCard.isValid, false);
      });

      test('returns false for expired status', () {
        final giftCard = _createGiftCard(status: GiftCardStatus.expired);
        expect(giftCard.isValid, false);
      });

      test('returns false for voided status', () {
        final giftCard = _createGiftCard(status: GiftCardStatus.voided);
        expect(giftCard.isValid, false);
      });
    });

    group('isExpired', () {
      test('returns true for expired status', () {
        final giftCard = _createGiftCard(status: GiftCardStatus.expired);
        expect(giftCard.isExpired, true);
      });

      test('returns true when expiresAt is in the past', () {
        final giftCard = _createGiftCard(
          status: GiftCardStatus.active,
          expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
        );
        expect(giftCard.isExpired, true);
      });

      test('returns false when expiresAt is in the future', () {
        final giftCard = _createGiftCard(
          status: GiftCardStatus.active,
          expiresAt: DateTime.now().add(const Duration(days: 30)),
        );
        expect(giftCard.isExpired, false);
      });

      test('returns false when expiresAt is null', () {
        final giftCard = _createGiftCard(
          status: GiftCardStatus.active,
          expiresAt: null,
        );
        expect(giftCard.isExpired, false);
      });
    });

    group('isRedeemable', () {
      test('returns true for valid card with balance', () {
        final giftCard = _createGiftCard(
          status: GiftCardStatus.active,
          remainingBalanceCents: 5000,
        );
        expect(giftCard.isRedeemable, true);
      });

      test('returns false for valid card with no balance', () {
        final giftCard = _createGiftCard(
          status: GiftCardStatus.active,
          remainingBalanceCents: 0,
        );
        expect(giftCard.isRedeemable, false);
      });

      test('returns false for invalid card with balance', () {
        final giftCard = _createGiftCard(
          status: GiftCardStatus.voided,
          remainingBalanceCents: 5000,
        );
        expect(giftCard.isRedeemable, false);
      });
    });

    group('statusDisplay', () {
      test('returns correct display strings', () {
        expect(
          _createGiftCard(status: GiftCardStatus.pending).statusDisplay,
          'Pending',
        );
        expect(
          _createGiftCard(status: GiftCardStatus.active).statusDisplay,
          'Active',
        );
        expect(
          _createGiftCard(status: GiftCardStatus.depleted).statusDisplay,
          'Depleted',
        );
        expect(
          _createGiftCard(status: GiftCardStatus.expired).statusDisplay,
          'Expired',
        );
        expect(
          _createGiftCard(status: GiftCardStatus.voided).statusDisplay,
          'Voided',
        );
      });
    });
  });

  group('GiftCardRedemption Model', () {
    group('JSON Serialization', () {
      test('serializes to JSON and back', () {
        final redemption = GiftCardRedemption(
          id: 'red-123',
          giftCardId: 'gc-456',
          appointmentId: 'appt-789',
          amountCents: 2500,
          redeemedAt: DateTime(2025, 2, 1, 14, 30),
          redeemedByClientId: 'client-abc',
        );

        final json = redemption.toJson();
        final restored = GiftCardRedemption.fromJson(json);

        expect(restored.id, redemption.id);
        expect(restored.giftCardId, redemption.giftCardId);
        expect(restored.appointmentId, redemption.appointmentId);
        expect(restored.amountCents, redemption.amountCents);
        expect(restored.redeemedByClientId, redemption.redeemedByClientId);
      });
    });

    group('Helper Getters', () {
      test('amountDollars converts cents to dollars', () {
        final redemption = GiftCardRedemption(
          id: 'red-123',
          giftCardId: 'gc-456',
          appointmentId: 'appt-789',
          amountCents: 2500,
          redeemedAt: DateTime(2025, 2, 1),
          redeemedByClientId: 'client-abc',
        );
        expect(redemption.amountDollars, 25.0);
      });

      test('handles fractional dollars', () {
        final redemption = GiftCardRedemption(
          id: 'red-123',
          giftCardId: 'gc-456',
          appointmentId: 'appt-789',
          amountCents: 1299,
          redeemedAt: DateTime(2025, 2, 1),
          redeemedByClientId: 'client-abc',
        );
        expect(redemption.amountDollars, 12.99);
      });
    });
  });

  group('GiftCardTemplate Model', () {
    group('JSON Serialization', () {
      test('serializes to JSON and back', () {
        final template = GiftCardTemplate(
          id: 'tpl-123',
          businessId: 'biz-456',
          name: 'Birthday Special',
          description: 'Perfect for birthdays',
          imageUrl: 'https://example.com/birthday.jpg',
          backgroundColor: '#FF5733',
          textColor: '#FFFFFF',
          presetAmountsCents: [2500, 5000, 10000],
          minAmountCents: 1000,
          maxAmountCents: 50000,
          validityDays: 365,
          isActive: true,
          createdAt: DateTime(2025, 1, 1),
        );

        final json = template.toJson();
        final restored = GiftCardTemplate.fromJson(json);

        expect(restored.id, template.id);
        expect(restored.businessId, template.businessId);
        expect(restored.name, template.name);
        expect(restored.description, template.description);
        expect(restored.imageUrl, template.imageUrl);
        expect(restored.backgroundColor, template.backgroundColor);
        expect(restored.textColor, template.textColor);
        expect(restored.presetAmountsCents, template.presetAmountsCents);
        expect(restored.minAmountCents, template.minAmountCents);
        expect(restored.maxAmountCents, template.maxAmountCents);
        expect(restored.validityDays, template.validityDays);
        expect(restored.isActive, template.isActive);
      });

      test('handles null optional fields', () {
        final template = GiftCardTemplate(
          id: 'tpl-123',
          businessId: 'biz-456',
          name: 'Simple Template',
          description: 'Basic template',
          imageUrl: '',
          backgroundColor: '#FFFFFF',
          textColor: '#000000',
          createdAt: DateTime(2025, 1, 1),
        );

        final json = template.toJson();
        final restored = GiftCardTemplate.fromJson(json);

        expect(restored.presetAmountsCents, isNull);
        expect(restored.minAmountCents, isNull);
        expect(restored.maxAmountCents, isNull);
        expect(restored.validityDays, isNull);
      });
    });

    group('Preset Amount Helpers', () {
      test('presetAmountsDollars converts cents to dollars', () {
        final template = _createTemplate(
          presetAmountsCents: [2500, 5000, 10000],
        );
        expect(template.presetAmountsDollars, [25.0, 50.0, 100.0]);
      });

      test('presetAmountsDollars returns empty list when null', () {
        final template = _createTemplate(presetAmountsCents: null);
        expect(template.presetAmountsDollars, isEmpty);
      });

      test('minAmountDollars converts correctly', () {
        final template = _createTemplate(minAmountCents: 1000);
        expect(template.minAmountDollars, 10.0);
      });

      test('minAmountDollars returns null when not set', () {
        final template = _createTemplate(minAmountCents: null);
        expect(template.minAmountDollars, isNull);
      });

      test('maxAmountDollars converts correctly', () {
        final template = _createTemplate(maxAmountCents: 50000);
        expect(template.maxAmountDollars, 500.0);
      });

      test('maxAmountDollars returns null when not set', () {
        final template = _createTemplate(maxAmountCents: null);
        expect(template.maxAmountDollars, isNull);
      });
    });

    group('allowsCustomAmount', () {
      test('returns true when no preset amounts', () {
        final template = _createTemplate(presetAmountsCents: null);
        expect(template.allowsCustomAmount, true);
      });

      test('returns true when preset amounts are empty', () {
        final template = _createTemplate(presetAmountsCents: []);
        expect(template.allowsCustomAmount, true);
      });

      test('returns true when min amount is set', () {
        final template = _createTemplate(
          presetAmountsCents: [2500, 5000],
          minAmountCents: 1000,
        );
        expect(template.allowsCustomAmount, true);
      });

      test('returns true when max amount is set', () {
        final template = _createTemplate(
          presetAmountsCents: [2500, 5000],
          maxAmountCents: 50000,
        );
        expect(template.allowsCustomAmount, true);
      });
    });

    group('neverExpires', () {
      test('returns true when validityDays is null', () {
        final template = _createTemplate(validityDays: null);
        expect(template.neverExpires, true);
      });

      test('returns false when validityDays is set', () {
        final template = _createTemplate(validityDays: 365);
        expect(template.neverExpires, false);
      });
    });

    group('calculateExpirationDate', () {
      test('returns null when validityDays is null', () {
        final template = _createTemplate(validityDays: null);
        final purchaseDate = DateTime(2025, 1, 15);
        expect(template.calculateExpirationDate(purchaseDate), isNull);
      });

      test('calculates correct expiration date', () {
        final template = _createTemplate(validityDays: 365);
        final purchaseDate = DateTime(2025, 1, 15);
        final expiration = template.calculateExpirationDate(purchaseDate);

        expect(expiration, DateTime(2026, 1, 15));
      });

      test('handles short validity periods', () {
        final template = _createTemplate(validityDays: 30);
        final purchaseDate = DateTime(2025, 1, 15);
        final expiration = template.calculateExpirationDate(purchaseDate);

        expect(expiration, DateTime(2025, 2, 14));
      });
    });

    group('isAmountValid', () {
      test('returns true when no limits are set', () {
        final template = _createTemplate(
          minAmountCents: null,
          maxAmountCents: null,
        );
        expect(template.isAmountValid(100), true);
        expect(template.isAmountValid(100000), true);
      });

      test('returns false when below minimum', () {
        final template = _createTemplate(minAmountCents: 1000);
        expect(template.isAmountValid(500), false);
        expect(template.isAmountValid(999), false);
      });

      test('returns true when at or above minimum', () {
        final template = _createTemplate(minAmountCents: 1000);
        expect(template.isAmountValid(1000), true);
        expect(template.isAmountValid(1001), true);
      });

      test('returns false when above maximum', () {
        final template = _createTemplate(maxAmountCents: 50000);
        expect(template.isAmountValid(50001), false);
        expect(template.isAmountValid(100000), false);
      });

      test('returns true when at or below maximum', () {
        final template = _createTemplate(maxAmountCents: 50000);
        expect(template.isAmountValid(50000), true);
        expect(template.isAmountValid(25000), true);
      });

      test('validates within range when both limits set', () {
        final template = _createTemplate(
          minAmountCents: 1000,
          maxAmountCents: 50000,
        );

        expect(template.isAmountValid(500), false); // Below min
        expect(template.isAmountValid(1000), true); // At min
        expect(template.isAmountValid(25000), true); // In range
        expect(template.isAmountValid(50000), true); // At max
        expect(template.isAmountValid(50001), false); // Above max
      });
    });
  });

  group('GiftCardStatus enum', () {
    test('all statuses have correct JSON values', () {
      expect(GiftCardStatus.pending.name, 'pending');
      expect(GiftCardStatus.active.name, 'active');
      expect(GiftCardStatus.depleted.name, 'depleted');
      expect(GiftCardStatus.expired.name, 'expired');
      expect(GiftCardStatus.voided.name, 'voided');
    });
  });
}

// Helper function to create GiftCard with defaults
GiftCard _createGiftCard({
  String id = 'gc-test',
  String businessId = 'biz-test',
  String code = 'GIFT-TEST-1234',
  int originalAmountCents = 5000,
  int remainingBalanceCents = 5000,
  String currency = 'usd',
  GiftCardStatus status = GiftCardStatus.active,
  String purchaserEmail = 'test@example.com',
  DateTime? expiresAt,
}) {
  return GiftCard(
    id: id,
    businessId: businessId,
    code: code,
    originalAmountCents: originalAmountCents,
    remainingBalanceCents: remainingBalanceCents,
    currency: currency,
    status: status,
    purchaserEmail: purchaserEmail,
    purchasedAt: DateTime(2025, 1, 1),
    createdAt: DateTime(2025, 1, 1),
    expiresAt: expiresAt,
  );
}

// Helper function to create GiftCardTemplate with defaults
GiftCardTemplate _createTemplate({
  String id = 'tpl-test',
  String businessId = 'biz-test',
  String name = 'Test Template',
  String description = 'Test Description',
  String imageUrl = 'https://example.com/test.jpg',
  String backgroundColor = '#FFFFFF',
  String textColor = '#000000',
  List<int>? presetAmountsCents,
  int? minAmountCents,
  int? maxAmountCents,
  int? validityDays,
  bool isActive = true,
}) {
  return GiftCardTemplate(
    id: id,
    businessId: businessId,
    name: name,
    description: description,
    imageUrl: imageUrl,
    backgroundColor: backgroundColor,
    textColor: textColor,
    presetAmountsCents: presetAmountsCents,
    minAmountCents: minAmountCents,
    maxAmountCents: maxAmountCents,
    validityDays: validityDays,
    isActive: isActive,
    createdAt: DateTime(2025, 1, 1),
  );
}
