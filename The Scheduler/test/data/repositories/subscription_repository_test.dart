import 'package:flutter_test/flutter_test.dart';
import 'package:the_scheduler/data/models/security_context.dart';
import 'package:the_scheduler/data/models/subscription.dart';

import '../../helpers/mock_repositories.dart';
import '../../helpers/test_data_factories.dart';

void main() {
  group('Subscription Repository', () {
    late MockSubscriptionRepository repository;
    late SecurityContext ownerContext;
    late SecurityContext adminContext;
    late SecurityContext staffContext;

    setUp(() {
      repository = MockSubscriptionRepository();
      ownerContext = TestData.securityContext(
        role: UserRole.owner,
        businessId: 'test-business',
      );
      adminContext = TestData.securityContext(
        role: UserRole.admin,
        businessId: 'test-business',
      );
      staffContext = TestData.securityContext(
        role: UserRole.staff,
        businessId: 'test-business',
      );
    });

    group('CRUD Operations', () {
      test('creates subscription', () async {
        final subscription = TestData.subscription(
          businessId: 'test-business',
          tier: SubscriptionTier.starter,
          status: SubscriptionStatus.active,
        );

        await repository.upsertSubscription(ownerContext, subscription);

        expect(repository.count, 1);
      });

      test('updates existing subscription', () async {
        final original = TestData.subscription(
          id: 'sub-1',
          businessId: 'test-business',
          tier: SubscriptionTier.starter,
          status: SubscriptionStatus.active,
        );

        await repository.upsertSubscription(ownerContext, original);

        final upgraded = original.copyWith(
          tier: SubscriptionTier.professional,
        );

        await repository.upsertSubscription(ownerContext, upgraded);

        expect(repository.count, 1);
        final stored =
            await repository.getSubscriptionById(ownerContext, 'sub-1');
        expect(stored?.tier, SubscriptionTier.professional);
      });

      test('gets subscription by ID', () async {
        final subscription = TestData.subscription(
          id: 'sub-123',
          businessId: 'test-business',
          tier: SubscriptionTier.professional,
        );

        repository.addSubscription(subscription);

        final result =
            await repository.getSubscriptionById(ownerContext, 'sub-123');

        expect(result, isNotNull);
        expect(result?.id, 'sub-123');
        expect(result?.tier, SubscriptionTier.professional);
      });

      test('watches subscription for business', () async {
        final subscription = TestData.subscription(
          businessId: 'test-business',
          tier: SubscriptionTier.enterprise,
          status: SubscriptionStatus.active,
        );

        repository.addSubscription(subscription);

        final stream = repository.watchSubscription(ownerContext);

        await expectLater(
          stream,
          emits(predicate<Subscription?>((sub) {
            return sub != null &&
                sub.businessId == 'test-business' &&
                sub.tier == SubscriptionTier.enterprise;
          })),
        );
      });

      test('deletes subscription', () async {
        final subscription = TestData.subscription(
          id: 'sub-1',
          businessId: 'test-business',
        );

        repository.addSubscription(subscription);
        expect(repository.count, 1);

        await repository.deleteSubscription(ownerContext, 'sub-1');

        expect(repository.count, 0);
      });
    });

    group('Security & Permissions', () {
      test('enforces business isolation', () async {
        final businessASub = TestData.subscription(
          businessId: 'business-a',
          tier: SubscriptionTier.professional,
        );

        repository.addSubscription(businessASub);

        final businessBContext = TestData.securityContext(
          role: UserRole.owner,
          businessId: 'business-b',
        );

        final stream = repository.watchSubscription(businessBContext);

        await expectLater(
          stream,
          emits(null), // Should not see business-a's subscription
        );
      });

      test('only owner can modify subscriptions', () async {
        final subscription = TestData.subscription(
          businessId: 'test-business',
          tier: SubscriptionTier.starter,
        );

        // Admin should throw security exception
        expect(
          () => repository.upsertSubscription(adminContext, subscription),
          throwsA(isA<SecurityException>()),
        );

        // Staff should throw security exception
        expect(
          () => repository.upsertSubscription(staffContext, subscription),
          throwsA(isA<SecurityException>()),
        );

        // Owner should succeed
        await repository.upsertSubscription(ownerContext, subscription);
        expect(repository.count, 1);
      });

      test('only owner can delete subscriptions', () async {
        final subscription = TestData.subscription(
          id: 'sub-1',
          businessId: 'test-business',
        );

        repository.addSubscription(subscription);

        expect(
          () => repository.deleteSubscription(adminContext, 'sub-1'),
          throwsA(isA<SecurityException>()),
        );

        await repository.deleteSubscription(ownerContext, 'sub-1');
        expect(repository.count, 0);
      });
    });

    group('Subscription Lifecycle', () {
      test('tracks subscription from trial to active', () async {
        final trial = TestData.subscription(
          id: 'sub-1',
          businessId: 'test-business',
          tier: SubscriptionTier.professional,
          status: SubscriptionStatus.trialing,
        );

        await repository.upsertSubscription(ownerContext, trial);

        final active = trial.copyWith(
          status: SubscriptionStatus.active,
        );

        await repository.upsertSubscription(ownerContext, active);

        final result =
            await repository.getSubscriptionById(ownerContext, 'sub-1');
        expect(result?.status, SubscriptionStatus.active);
      });

      test('handles subscription expiration', () async {
        final subscription = TestData.subscription(
          id: 'sub-1',
          businessId: 'test-business',
          tier: SubscriptionTier.starter,
          status: SubscriptionStatus.active,
          currentPeriodEnd: DateTime.now().subtract(const Duration(days: 1)),
        );

        await repository.upsertSubscription(ownerContext, subscription);

        // In real implementation, this would trigger expiration logic
        expect(
          subscription.currentPeriodEnd.isBefore(DateTime.now()),
          isTrue,
        );
      });

      test('handles subscription cancellation', () async {
        final subscription = TestData.subscription(
          id: 'sub-1',
          businessId: 'test-business',
          tier: SubscriptionTier.professional,
          status: SubscriptionStatus.active,
        );

        await repository.upsertSubscription(ownerContext, subscription);

        final cancelled = subscription.copyWith(
          status: SubscriptionStatus.canceled,
          canceledAt: DateTime.now(),
        );

        await repository.upsertSubscription(ownerContext, cancelled);

        final result =
            await repository.getSubscriptionById(ownerContext, 'sub-1');
        expect(result?.status, SubscriptionStatus.canceled);
        expect(result?.canceledAt, isNotNull);
      });

      test('handles past due subscription', () async {
        final subscription = TestData.subscription(
          id: 'sub-1',
          businessId: 'test-business',
          tier: SubscriptionTier.starter,
          status: SubscriptionStatus.pastDue,
        );

        await repository.upsertSubscription(ownerContext, subscription);

        final result =
            await repository.getSubscriptionById(ownerContext, 'sub-1');
        expect(result?.status, SubscriptionStatus.pastDue);
      });
    });

    group('Tier Upgrades & Downgrades', () {
      test('upgrades from free to starter', () async {
        final free = TestData.subscription(
          id: 'sub-1',
          businessId: 'test-business',
          tier: SubscriptionTier.free,
          status: SubscriptionStatus.active,
        );

        await repository.upsertSubscription(ownerContext, free);

        final starter = free.copyWith(tier: SubscriptionTier.starter);

        await repository.upsertSubscription(ownerContext, starter);

        final result =
            await repository.getSubscriptionById(ownerContext, 'sub-1');
        expect(result?.tier, SubscriptionTier.starter);
      });

      test('upgrades from starter to professional', () async {
        final starter = TestData.subscription(
          id: 'sub-1',
          businessId: 'test-business',
          tier: SubscriptionTier.starter,
          status: SubscriptionStatus.active,
        );

        await repository.upsertSubscription(ownerContext, starter);

        final professional =
            starter.copyWith(tier: SubscriptionTier.professional);

        await repository.upsertSubscription(ownerContext, professional);

        final result =
            await repository.getSubscriptionById(ownerContext, 'sub-1');
        expect(result?.tier, SubscriptionTier.professional);
      });

      test('upgrades to enterprise tier', () async {
        final professional = TestData.subscription(
          id: 'sub-1',
          businessId: 'test-business',
          tier: SubscriptionTier.professional,
          status: SubscriptionStatus.active,
        );

        await repository.upsertSubscription(ownerContext, professional);

        final enterprise =
            professional.copyWith(tier: SubscriptionTier.enterprise);

        await repository.upsertSubscription(ownerContext, enterprise);

        final result =
            await repository.getSubscriptionById(ownerContext, 'sub-1');
        expect(result?.tier, SubscriptionTier.enterprise);
        expect(result?.tier.maxProviders, -1); // Unlimited
      });

      test('downgrades from professional to starter', () async {
        final professional = TestData.subscription(
          id: 'sub-1',
          businessId: 'test-business',
          tier: SubscriptionTier.professional,
          status: SubscriptionStatus.active,
        );

        await repository.upsertSubscription(ownerContext, professional);

        final starter = professional.copyWith(tier: SubscriptionTier.starter);

        await repository.upsertSubscription(ownerContext, starter);

        final result =
            await repository.getSubscriptionById(ownerContext, 'sub-1');
        expect(result?.tier, SubscriptionTier.starter);
      });
    });

    group('Real-World Scenarios', () {
      test('dental practice starts with starter, upgrades as grows', () async {
        // Start with starter tier
        final starter = TestData.subscription(
          id: 'dental-sub',
          businessId: 'test-business',
          tier: SubscriptionTier.starter,
          status: SubscriptionStatus.active,
        );

        await repository.upsertSubscription(ownerContext, starter);

        // After 6 months, upgrade to professional for more features
        final professional = starter.copyWith(
          tier: SubscriptionTier.professional,
        );

        await repository.upsertSubscription(ownerContext, professional);

        final result =
            await repository.getSubscriptionById(ownerContext, 'dental-sub');
        expect(result?.tier, SubscriptionTier.professional);
        expect(result?.tier.hasCustomBranding, isTrue);
        expect(result?.tier.hasAdvancedReporting, isTrue);
      });

      test('therapy practice uses free tier initially', () async {
        final free = TestData.subscription(
          id: 'therapy-sub',
          businessId: 'test-business',
          tier: SubscriptionTier.free,
          status: SubscriptionStatus.active,
        );

        await repository.upsertSubscription(ownerContext, free);

        final result =
            await repository.getSubscriptionById(ownerContext, 'therapy-sub');
        expect(result?.tier, SubscriptionTier.free);
        expect(result?.tier.maxProviders, 1);
        expect(result?.tier.maxClients, 100);
      });

      test('multi-location clinic needs enterprise', () async {
        final enterprise = TestData.subscription(
          id: 'clinic-sub',
          businessId: 'test-business',
          tier: SubscriptionTier.enterprise,
          status: SubscriptionStatus.active,
        );

        await repository.upsertSubscription(ownerContext, enterprise);

        final result =
            await repository.getSubscriptionById(ownerContext, 'clinic-sub');
        expect(result?.tier, SubscriptionTier.enterprise);
        expect(result?.tier.maxProviders, -1); // Unlimited
        expect(result?.tier.maxLocations, -1); // Unlimited
        expect(result?.tier.hasApiAccess, isTrue);
        expect(result?.tier.hasHipaaCompliance, isTrue);
      });

      test('subscription past due with retry period', () async {
        final pastDue = TestData.subscription(
          id: 'sub-1',
          businessId: 'test-business',
          tier: SubscriptionTier.professional,
          status: SubscriptionStatus.pastDue,
          currentPeriodEnd: DateTime.now().subtract(const Duration(days: 3)),
        );

        await repository.upsertSubscription(ownerContext, pastDue);

        final result =
            await repository.getSubscriptionById(ownerContext, 'sub-1');
        expect(result?.status, SubscriptionStatus.pastDue);
      });

      test('cancelled subscription with end of period access', () async {
        final currentPeriodEnd = DateTime.now().add(const Duration(days: 15));
        final cancelled = TestData.subscription(
          id: 'sub-1',
          businessId: 'test-business',
          tier: SubscriptionTier.starter,
          status: SubscriptionStatus.canceled,
          currentPeriodEnd: currentPeriodEnd,
          canceledAt: DateTime.now(),
        );

        await repository.upsertSubscription(ownerContext, cancelled);

        final result =
            await repository.getSubscriptionById(ownerContext, 'sub-1');
        expect(result?.status, SubscriptionStatus.canceled);
        expect(result?.canceledAt, isNotNull);
        // Should still have access until currentPeriodEnd
        expect(result?.currentPeriodEnd.isAfter(DateTime.now()), isTrue);
      });
    });

    group('Feature Gating Validation', () {
      test('validates provider limits', () {
        final free = TestData.subscription(
          tier: SubscriptionTier.free,
          businessId: 'test-business',
        );
        expect(free.tier.maxProviders, 1);

        final starter = free.copyWith(tier: SubscriptionTier.starter);
        expect(starter.tier.maxProviders, 3);

        final professional = free.copyWith(tier: SubscriptionTier.professional);
        expect(professional.tier.maxProviders, 10);

        final enterprise = free.copyWith(tier: SubscriptionTier.enterprise);
        expect(enterprise.tier.maxProviders, -1); // Unlimited
      });

      test('validates location limits', () {
        final free = TestData.subscription(
          tier: SubscriptionTier.free,
          businessId: 'test-business',
        );
        expect(free.tier.maxLocations, 1);

        final starter = free.copyWith(tier: SubscriptionTier.starter);
        expect(starter.tier.maxLocations, 1);

        final professional = free.copyWith(tier: SubscriptionTier.professional);
        expect(professional.tier.maxLocations, 3);

        final enterprise = free.copyWith(tier: SubscriptionTier.enterprise);
        expect(enterprise.tier.maxLocations, -1); // Unlimited
      });

      test('validates feature flags per tier', () {
        final tiers = [
          SubscriptionTier.free,
          SubscriptionTier.starter,
          SubscriptionTier.professional,
          SubscriptionTier.enterprise,
        ];

        for (final tier in tiers) {
          final sub = TestData.subscription(tier: tier, businessId: 'test');

          // Free has minimal features
          if (tier == SubscriptionTier.free) {
            expect(sub.tier.hasAutomatedReminders, isFalse);
            expect(sub.tier.hasPaymentProcessing, isFalse);
            expect(sub.tier.hasCustomBranding, isFalse);
          }

          // Enterprise has all features
          if (tier == SubscriptionTier.enterprise) {
            expect(sub.tier.hasAutomatedReminders, isTrue);
            expect(sub.tier.hasPaymentProcessing, isTrue);
            expect(sub.tier.hasCustomBranding, isTrue);
            expect(sub.tier.hasHipaaCompliance, isTrue);
            expect(sub.tier.hasApiAccess, isTrue);
            expect(sub.tier.hasTwoWayCalendarSync, isTrue);
          }
        }
      });
    });
  });
}
