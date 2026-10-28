import 'package:flutter/material.dart';

import '../../../../data/models/subscription.dart';

/// Individual plan card showing tier details and upgrade/downgrade option
class BillingPlanCard extends StatelessWidget {
  final SubscriptionTier tier;
  final Subscription currentSubscription;
  final ThemeData theme;
  final dynamic branding;
  final VoidCallback onUpgradePressed;

  const BillingPlanCard({
    super.key,
    required this.tier,
    required this.currentSubscription,
    required this.theme,
    required this.branding,
    required this.onUpgradePressed,
  });

  @override
  Widget build(BuildContext context) {
    final isCurrent = tier == currentSubscription.tier;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tier.displayName,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatPlanPrice(tier),
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: branding.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (isCurrent)
                  Chip(
                    label: const Text('Current'),
                    backgroundColor: Colors.green[100],
                    labelStyle: TextStyle(color: Colors.green[900]),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ..._getPlanFeatures(tier).map((feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle,
                          size: 16, color: Colors.green[600]),
                      const SizedBox(width: 8),
                      Expanded(child: Text(feature)),
                    ],
                  ),
                )),
            if (!isCurrent) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onUpgradePressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: branding.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(tier.monthlyPriceCents! >
                          currentSubscription.tier.monthlyPriceCents!
                      ? 'Upgrade'
                      : 'Downgrade'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<String> _getPlanFeatures(SubscriptionTier tier) {
    final features = <String>[];

    if (tier.maxProviders == -1) {
      features.add('Unlimited providers');
    } else {
      features.add('Up to ${tier.maxProviders} provider${tier.maxProviders > 1 ? 's' : ''}');
    }

    if (tier.maxLocations == -1) {
      features.add('Unlimited locations');
    } else {
      features.add('${tier.maxLocations} location${tier.maxLocations > 1 ? 's' : ''}');
    }

    if (tier.maxAppointmentsPerMonth == -1) {
      features.add('Unlimited appointments');
    } else {
      features.add('${tier.maxAppointmentsPerMonth} appointments/month');
    }

    if (tier.hasAutomatedReminders) features.add('Automated reminders');
    if (tier.includedSmsPerMonth > 0) {
      if (tier.includedSmsPerMonth == -1) {
        features.add('Unlimited SMS');
      } else {
        features.add('${tier.includedSmsPerMonth} SMS/month');
      }
    }
    if (tier.hasClientPortal) features.add('Client self-service portal');
    if (tier.hasPaymentProcessing) features.add('Payment processing');
    if (tier.hasCustomBranding) features.add('Custom branding');
    if (tier.hasAdvancedReporting) features.add('Advanced reporting');
    if (tier.hasTwoWayCalendarSync) features.add('Two-way calendar sync');
    if (tier.hasHipaaCompliance) features.add('HIPAA compliance');
    if (tier.hasApiAccess) features.add('API access');

    return features;
  }

  String _formatPlanPrice(SubscriptionTier tier) {
    if (tier.monthlyPriceCents == 0) return 'Free';
    return '\$${(tier.monthlyPriceCents! / 100).toStringAsFixed(0)}/month';
  }
}
