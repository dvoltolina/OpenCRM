import 'package:flutter_test/flutter_test.dart';
import 'package:the_scheduler/data/models/subscription.dart';
import '../../helpers/test_data_factories.dart';

void main() {
  group('Subscription Model', () {
    group('JSON Serialization', () {
      test('creates subscription from JSON', () {
        final json = {
          'id': 'sub-1',
          'businessId': 'business-1',
          'tier': 'professional',
          'status': 'active',
          'stripeCustomerId': 'cus_123',
          'stripeSubscriptionId': 'sub_123',
          'stripePriceId': 'price_123',
          'currentPeriodStart': '2025-12-01T00:00:00.000Z',
          'currentPeriodEnd': '2026-01-01T00:00:00.000Z',
          'cancelAtPeriodEnd': false,
          'createdAt': '2025-12-01T10:00:00.000Z',
          'updatedAt': '2025-12-01T10:00:00.000Z',
        };

        final subscription = Subscription.fromJson(json);

        expect(subscription.id, 'sub-1');
        expect(subscription.businessId, 'business-1');
        expect(subscription.tier, SubscriptionTier.professional);
        expect(subscription.status, SubscriptionStatus.active);
        expect(subscription.stripeCustomerId, 'cus_123');
        expect(subscription.stripeSubscriptionId, 'sub_123');
        expect(subscription.stripePriceId, 'price_123');
        expect(subscription.cancelAtPeriodEnd, false);
      });

      test('converts subscription to JSON', () {
        final subscription = TestData.subscription(
          id: 'sub-1',
          tier: SubscriptionTier.professional,
          status: SubscriptionStatus.active,
        );

        final json = subscription.toJson();

        expect(json['id'], 'sub-1');
        expect(json['tier'], 'professional');
        expect(json['status'], 'active');
        expect(json['cancelAtPeriodEnd'], false);
      });

      test('handles all subscription tiers', () {
        expect(SubscriptionTier.free.name, 'free');
        expect(SubscriptionTier.starter.name, 'starter');
        expect(SubscriptionTier.professional.name, 'professional');
        expect(SubscriptionTier.enterprise.name, 'enterprise');
      });

      test('handles all subscription statuses', () {
        expect(SubscriptionStatus.active.name, 'active');
        expect(SubscriptionStatus.trialing.name, 'trialing');
        expect(SubscriptionStatus.pastDue.name, 'pastDue');
        expect(SubscriptionStatus.canceled.name, 'canceled');
        expect(SubscriptionStatus.incomplete.name, 'incomplete');
        expect(SubscriptionStatus.incompleteExpired.name, 'incompleteExpired');
        expect(SubscriptionStatus.unpaid.name, 'unpaid');
      });

      test('handles optional fields', () {
        final now = DateTime.now();
        final subscription = Subscription(
          id: 'sub-1',
          businessId: 'business-1',
          tier: SubscriptionTier.free,
          status: SubscriptionStatus.active,
          stripeCustomerId: 'cus_123',
          currentPeriodStart: now,
          currentPeriodEnd: now.add(const Duration(days: 30)),
          createdAt: now,
          updatedAt: now,
        );

        expect(subscription.stripeSubscriptionId, null);
        expect(subscription.stripePriceId, null);
        expect(subscription.trialEnd, null);
        expect(subscription.canceledAt, null);
      });
    });

    group('Tier Properties', () {
      test('displayName returns correct names', () {
        expect(SubscriptionTier.free.displayName, 'Free (Solo)');
        expect(SubscriptionTier.starter.displayName, 'Starter (Professional)');
        expect(
            SubscriptionTier.professional.displayName, 'Professional (Practice)');
        expect(SubscriptionTier.enterprise.displayName, 'Enterprise (Network)');
      });

      test('monthlyPriceCents returns correct prices', () {
        expect(SubscriptionTier.free.monthlyPriceCents, 0);
        expect(SubscriptionTier.starter.monthlyPriceCents, 2900);
        expect(SubscriptionTier.professional.monthlyPriceCents, 7900);
        expect(SubscriptionTier.enterprise.monthlyPriceCents, 29900);
      });

      test('annualPriceCents returns correct prices', () {
        expect(SubscriptionTier.free.annualPriceCents, 0);
        expect(SubscriptionTier.starter.annualPriceCents, 29000);
        expect(SubscriptionTier.professional.annualPriceCents, 79000);
        expect(SubscriptionTier.enterprise.annualPriceCents, 299000);
      });

      test('maxProviders returns correct limits', () {
        expect(SubscriptionTier.free.maxProviders, 1);
        expect(SubscriptionTier.starter.maxProviders, 3);
        expect(SubscriptionTier.professional.maxProviders, 10);
        expect(SubscriptionTier.enterprise.maxProviders, -1); // unlimited
      });

      test('maxLocations returns correct limits', () {
        expect(SubscriptionTier.free.maxLocations, 1);
        expect(SubscriptionTier.starter.maxLocations, 1);
        expect(SubscriptionTier.professional.maxLocations, 3);
        expect(SubscriptionTier.enterprise.maxLocations, -1); // unlimited
      });

      test('maxAppointmentsPerMonth returns correct limits', () {
        expect(SubscriptionTier.free.maxAppointmentsPerMonth, 50);
        expect(SubscriptionTier.starter.maxAppointmentsPerMonth, 200);
        expect(SubscriptionTier.professional.maxAppointmentsPerMonth, -1);
        expect(SubscriptionTier.enterprise.maxAppointmentsPerMonth, -1);
      });

      test('maxClients returns correct limits', () {
        expect(SubscriptionTier.free.maxClients, 100);
        expect(SubscriptionTier.starter.maxClients, -1); // unlimited
        expect(SubscriptionTier.professional.maxClients, -1);
        expect(SubscriptionTier.enterprise.maxClients, -1);
      });

      test('includedSmsPerMonth returns correct limits', () {
        expect(SubscriptionTier.free.includedSmsPerMonth, 0);
        expect(SubscriptionTier.starter.includedSmsPerMonth, 100);
        expect(SubscriptionTier.professional.includedSmsPerMonth, 500);
        expect(SubscriptionTier.enterprise.includedSmsPerMonth, -1);
      });
    });

    group('Tier Features', () {
      test('hasAutomatedReminders is correct for each tier', () {
        expect(SubscriptionTier.free.hasAutomatedReminders, false);
        expect(SubscriptionTier.starter.hasAutomatedReminders, true);
        expect(SubscriptionTier.professional.hasAutomatedReminders, true);
        expect(SubscriptionTier.enterprise.hasAutomatedReminders, true);
      });

      test('hasPaymentProcessing is correct for each tier', () {
        expect(SubscriptionTier.free.hasPaymentProcessing, false);
        expect(SubscriptionTier.starter.hasPaymentProcessing, false);
        expect(SubscriptionTier.professional.hasPaymentProcessing, true);
        expect(SubscriptionTier.enterprise.hasPaymentProcessing, true);
      });

      test('hasCustomBranding is correct for each tier', () {
        expect(SubscriptionTier.free.hasCustomBranding, false);
        expect(SubscriptionTier.starter.hasCustomBranding, true);
        expect(SubscriptionTier.professional.hasCustomBranding, true);
        expect(SubscriptionTier.enterprise.hasCustomBranding, true);
      });

      test('hasHipaaCompliance is correct for each tier', () {
        expect(SubscriptionTier.free.hasHipaaCompliance, false);
        expect(SubscriptionTier.starter.hasHipaaCompliance, false);
        expect(SubscriptionTier.professional.hasHipaaCompliance, true);
        expect(SubscriptionTier.enterprise.hasHipaaCompliance, true);
      });

      test('hasApiAccess is correct for each tier', () {
        expect(SubscriptionTier.free.hasApiAccess, false);
        expect(SubscriptionTier.starter.hasApiAccess, false);
        expect(SubscriptionTier.professional.hasApiAccess, false);
        expect(SubscriptionTier.enterprise.hasApiAccess, true);
      });

      test('hasClientPortal is correct for each tier', () {
        expect(SubscriptionTier.free.hasClientPortal, false);
        expect(SubscriptionTier.starter.hasClientPortal, true);
        expect(SubscriptionTier.professional.hasClientPortal, true);
        expect(SubscriptionTier.enterprise.hasClientPortal, true);
      });

      test('hasAdvancedReporting is correct for each tier', () {
        expect(SubscriptionTier.free.hasAdvancedReporting, false);
        expect(SubscriptionTier.starter.hasAdvancedReporting, false);
        expect(SubscriptionTier.professional.hasAdvancedReporting, true);
        expect(SubscriptionTier.enterprise.hasAdvancedReporting, true);
      });

      test('hasTwoWayCalendarSync is correct for each tier', () {
        expect(SubscriptionTier.free.hasTwoWayCalendarSync, false);
        expect(SubscriptionTier.starter.hasTwoWayCalendarSync, false);
        expect(SubscriptionTier.professional.hasTwoWayCalendarSync, true);
        expect(SubscriptionTier.enterprise.hasTwoWayCalendarSync, true);
      });
    });

    group('copyWith', () {
      test('copies with new tier', () {
        final subscription = TestData.subscription(tier: SubscriptionTier.free);
        final upgraded =
            subscription.copyWith(tier: SubscriptionTier.professional);

        expect(upgraded.tier, SubscriptionTier.professional);
        expect(upgraded.id, subscription.id);
        expect(upgraded.businessId, subscription.businessId);
      });

      test('copies with new status', () {
        final subscription =
            TestData.subscription(status: SubscriptionStatus.trialing);
        final updated = subscription.copyWith(status: SubscriptionStatus.active);

        expect(updated.status, SubscriptionStatus.active);
      });

      test('copies with cancellation', () {
        final subscription = TestData.subscription();
        final canceledAt = DateTime(2025, 12, 15);
        final canceled = subscription.copyWith(
          status: SubscriptionStatus.canceled,
          cancelAtPeriodEnd: true,
          canceledAt: canceledAt,
        );

        expect(canceled.status, SubscriptionStatus.canceled);
        expect(canceled.cancelAtPeriodEnd, true);
        expect(canceled.canceledAt, canceledAt);
      });

      test('preserves all fields when no changes', () {
        final subscription = TestData.subscription(
          id: 'sub-1',
          tier: SubscriptionTier.professional,
        );
        final copy = subscription.copyWith();

        expect(copy.id, subscription.id);
        expect(copy.tier, subscription.tier);
        expect(copy.businessId, subscription.businessId);
      });
    });

    group('Business Logic', () {
      test('supports multi-tenant isolation', () {
        final sub1 = TestData.subscription(businessId: 'business-1');
        final sub2 = TestData.subscription(businessId: 'business-2');

        expect(sub1.businessId, 'business-1');
        expect(sub2.businessId, 'business-2');
        expect(sub1.businessId, isNot(sub2.businessId));
      });

      test('tracks subscription lifecycle', () {
        final startDate = DateTime(2025, 12, 1);
        final trialEndDate = DateTime(2025, 12, 15);
        final endDate = DateTime(2026, 1, 1);

        // Trial period
        var subscription = Subscription(
          id: 'sub-1',
          businessId: 'business-1',
          tier: SubscriptionTier.professional,
          status: SubscriptionStatus.trialing,
          stripeCustomerId: 'cus_123',
          currentPeriodStart: startDate,
          currentPeriodEnd: endDate,
          trialEnd: trialEndDate,
          createdAt: startDate,
          updatedAt: startDate,
        );

        expect(subscription.status, SubscriptionStatus.trialing);
        expect(subscription.trialEnd, trialEndDate);

        // Activated after trial
        subscription = subscription.copyWith(
          status: SubscriptionStatus.active,
          updatedAt: trialEndDate,
        );

        expect(subscription.status, SubscriptionStatus.active);

        // Canceled
        final cancelDate = DateTime(2025, 12, 20);
        subscription = subscription.copyWith(
          status: SubscriptionStatus.canceled,
          cancelAtPeriodEnd: true,
          canceledAt: cancelDate,
          updatedAt: cancelDate,
        );

        expect(subscription.status, SubscriptionStatus.canceled);
        expect(subscription.cancelAtPeriodEnd, true);
        expect(subscription.canceledAt, cancelDate);
      });

      test('handles past due subscription', () {
        final subscription = TestData.subscription(
          status: SubscriptionStatus.pastDue,
        );

        expect(subscription.status, SubscriptionStatus.pastDue);
      });

      test('handles unpaid subscription', () {
        final subscription = TestData.subscription(
          status: SubscriptionStatus.unpaid,
        );

        expect(subscription.status, SubscriptionStatus.unpaid);
      });
    });

    group('Feature Gating Examples', () {
      test('free tier has basic limits', () {
        final freeTier = SubscriptionTier.free;

        expect(freeTier.maxProviders, 1);
        expect(freeTier.maxLocations, 1);
        expect(freeTier.maxAppointmentsPerMonth, 50);
        expect(freeTier.maxClients, 100);
        expect(freeTier.includedSmsPerMonth, 0);
        expect(freeTier.hasAutomatedReminders, false);
        expect(freeTier.hasPaymentProcessing, false);
        expect(freeTier.hasClientPortal, false);
      });

      test('starter tier has increased limits', () {
        final starterTier = SubscriptionTier.starter;

        expect(starterTier.maxProviders, 3);
        expect(starterTier.maxLocations, 1);
        expect(starterTier.maxAppointmentsPerMonth, 200);
        expect(starterTier.maxClients, -1); // unlimited
        expect(starterTier.includedSmsPerMonth, 100);
        expect(starterTier.hasAutomatedReminders, true);
        expect(starterTier.hasPaymentProcessing, false);
        expect(starterTier.hasClientPortal, true);
      });

      test('professional tier has advanced features', () {
        final professionalTier = SubscriptionTier.professional;

        expect(professionalTier.maxProviders, 10);
        expect(professionalTier.maxLocations, 3);
        expect(professionalTier.maxAppointmentsPerMonth, -1); // unlimited
        expect(professionalTier.includedSmsPerMonth, 500);
        expect(professionalTier.hasPaymentProcessing, true);
        expect(professionalTier.hasHipaaCompliance, true);
        expect(professionalTier.hasAdvancedReporting, true);
        expect(professionalTier.hasTwoWayCalendarSync, true);
      });

      test('enterprise tier has all features', () {
        final enterpriseTier = SubscriptionTier.enterprise;

        expect(enterpriseTier.maxProviders, -1); // unlimited
        expect(enterpriseTier.maxLocations, -1); // unlimited
        expect(enterpriseTier.maxAppointmentsPerMonth, -1);
        expect(enterpriseTier.includedSmsPerMonth, -1);
        expect(enterpriseTier.hasPaymentProcessing, true);
        expect(enterpriseTier.hasHipaaCompliance, true);
        expect(enterpriseTier.hasApiAccess, true);
        expect(enterpriseTier.hasAdvancedReporting, true);
        expect(enterpriseTier.hasTwoWayCalendarSync, true);
      });
    });

    group('Test Data Factory', () {
      test('creates subscription with defaults', () {
        final subscription = TestData.subscription();

        expect(subscription.id, isNotEmpty);
        expect(subscription.businessId, TestData.businessId);
        expect(subscription.tier, isNotNull);
        expect(subscription.status, isNotNull);
        expect(subscription.stripeCustomerId, isNotEmpty);
      });

      test('creates subscription with custom values', () {
        final subscription = TestData.subscription(
          id: 'custom-sub',
          tier: SubscriptionTier.enterprise,
          status: SubscriptionStatus.trialing,
        );

        expect(subscription.id, 'custom-sub');
        expect(subscription.tier, SubscriptionTier.enterprise);
        expect(subscription.status, SubscriptionStatus.trialing);
      });
    });
  });
}
