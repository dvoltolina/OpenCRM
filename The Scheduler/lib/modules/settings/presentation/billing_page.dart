import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../core/services/feature_gating_service.dart';
import '../../../core/ui/components/components.dart';
import '../../../data/models/subscription.dart';
import '../../../data/models/security_context.dart';
import '../../../data/repositories/subscription_repository.dart';
import 'widgets/billing_actions.dart';
import 'widgets/billing_current_plan_card.dart';
import 'widgets/billing_plan_card.dart';
import 'widgets/billing_upgrade_recommendation_card.dart';
import 'widgets/billing_usage_card.dart';

/// Billing and subscription management page
///
/// This page displays the current subscription plan, usage statistics,
/// and provides options to upgrade/downgrade or manage billing through
/// Stripe Customer Portal.
class BillingPage extends ConsumerWidget {
  const BillingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branding = ref.watch(appConfigProvider).branding;
    final theme = Theme.of(context);
    final securityContextAsync = ref.watch(securityContextProvider);
    final subscriptionRepo = ref.watch(subscriptionRepositoryProvider);

    return securityContextAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error loading session: $error')),
      data: (securityContext) {
        if (securityContext == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final featureGating = FeatureGatingService(
          subscriptionRepository: subscriptionRepo,
        );

        return StreamBuilder<Subscription?>(
          stream: subscriptionRepo.watchSubscription(securityContext),
          builder: (context, subscriptionSnapshot) {
            if (subscriptionSnapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final subscription = subscriptionSnapshot.data ??
                _createDefaultSubscription(securityContext.businessId);

            return ScrollablePageScaffold(
              title: 'Billing',
              showBackButton: false,
              showAppBar: false,
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCurrentPlanCard(subscription, theme),
                  VSpace.lg,
                  _buildUsageCard(securityContext, subscription, theme, subscriptionRepo),
                  VSpace.lg,
                  _buildUpgradeRecommendation(securityContext, theme, featureGating),
                  VSpace.xl,
                  _buildAvailablePlans(context, subscription, theme, branding),
                  VSpace.xl,
                  _buildBillingActions(context, subscription, branding),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCurrentPlanCard(Subscription subscription, ThemeData theme) {
    return BillingCurrentPlanCard(
      subscription: subscription,
      theme: theme,
    );
  }

  Widget _buildUsageCard(
    SecurityContext securityContext,
    Subscription subscription,
    ThemeData theme,
    SubscriptionRepository subscriptionRepo,
  ) {
    return BillingUsageCard(
      securityContext: securityContext,
      subscription: subscription,
      theme: theme,
      subscriptionRepo: subscriptionRepo,
    );
  }

  Widget _buildUpgradeRecommendation(
      SecurityContext securityContext, ThemeData theme, FeatureGatingService featureGating) {
    return BillingUpgradeRecommendationCard(
      securityContext: securityContext,
      theme: theme,
      featureGating: featureGating,
    );
  }

  Widget _buildAvailablePlans(
    BuildContext context,
    Subscription currentSubscription,
    ThemeData theme,
    dynamic branding,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Plans',
          style:
              theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        VSpace.md,
        ...SubscriptionTier.values
                .map((tier) => _buildPlanCard(
                      context,
                      tier,
                      currentSubscription,
                      theme,
                      branding,
                    ))
            ,
      ],
    );
  }

  Widget _buildPlanCard(
    BuildContext context,
    SubscriptionTier tier,
    Subscription currentSubscription,
    ThemeData theme,
    dynamic branding,
  ) {
    return BillingPlanCard(
      tier: tier,
      currentSubscription: currentSubscription,
      theme: theme,
      branding: branding,
      onUpgradePressed: () => _showUpgradeDialog(context, tier),
    );
  }

  Widget _buildBillingActions(BuildContext context, Subscription subscription, dynamic branding) {
    return BillingActions(
      subscription: subscription,
      branding: branding,
      onOpenCustomerPortal: () => _openCustomerPortal(context),
      onViewInvoices: () => _viewInvoices(context),
      onCancelSubscription: () => _cancelSubscription(context),
      onReactivateSubscription: () => _reactivateSubscription(context),
    );
  }

  Subscription _createDefaultSubscription(String businessId) {
    final now = DateTime.now();
    return Subscription(
      id: 'default',
      businessId: businessId,
      tier: SubscriptionTier.free,
      status: SubscriptionStatus.active,
      stripeCustomerId: '',
      currentPeriodStart: now,
      currentPeriodEnd: now.add(const Duration(days: 30)),
      createdAt: now,
      updatedAt: now,
    );
  }

  String _formatPlanPrice(SubscriptionTier tier) {
    if (tier.monthlyPriceCents == 0) return 'Free';
    return '\$${(tier.monthlyPriceCents! / 100).toStringAsFixed(0)}/month';
  }

  // Action methods
  void _showUpgradeDialog(BuildContext rootContext, SubscriptionTier tier) {
    showDialog(
      context: rootContext,
      builder: (dialogContext) => AlertDialog(
        title: Text('Upgrade to ${tier.displayName}'),
        content: Text(
          'You will be charged ${_formatPlanPrice(tier)} starting today. '
          'Your current billing period will be prorated.',
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Cancel'),
                  ),
                ),
                HSpace.xs,
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      // TODO: Implement upgrade flow with Stripe
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Stripe integration coming soon. This will redirect to Stripe Checkout.',
                          ),
                        ),
                      );
                    },
                    child: const Text('Confirm'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openCustomerPortal(BuildContext rootContext) {
    // TODO: Open Stripe Customer Portal
    ScaffoldMessenger.of(rootContext).showSnackBar(
      const SnackBar(
        content: Text('Opening Stripe Customer Portal...'),
      ),
    );
  }

  void _viewInvoices(BuildContext rootContext) {
    // TODO: Navigate to invoices list
    ScaffoldMessenger.of(rootContext).showSnackBar(
      const SnackBar(content: Text('View invoices coming soon')),
    );
  }

  void _cancelSubscription(BuildContext rootContext) {
    final theme = Theme.of(rootContext);
    showDialog(
      context: rootContext,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel Subscription'),
        content: const Text(
          'Your subscription will remain active until the end of your current billing period. '
          'You can reactivate anytime before then.',
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Keep Subscription'),
                  ),
                ),
                HSpace.xs,
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      // TODO: Call cancel subscription
                    },
                    style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
                    child: const Text('Cancel Subscription'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _reactivateSubscription(BuildContext rootContext) {
    // TODO: Call reactivate subscription
    ScaffoldMessenger.of(rootContext).showSnackBar(
      const SnackBar(content: Text('Reactivating subscription...')),
    );
  }
}
