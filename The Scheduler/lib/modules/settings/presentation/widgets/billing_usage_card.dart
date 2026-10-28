import 'package:flutter/material.dart';

import '../../../../data/models/subscription.dart';
import '../../../../data/repositories/subscription_repository.dart';
import 'billing_usage_bar.dart';

/// Usage statistics card for current billing period
class BillingUsageCard extends StatelessWidget {
  final dynamic securityContext;
  final Subscription subscription;
  final ThemeData theme;
  final SubscriptionRepository subscriptionRepo;

  const BillingUsageCard({
    super.key,
    required this.securityContext,
    required this.subscription,
    required this.theme,
    required this.subscriptionRepo,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Usage This Period',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            FutureBuilder<Map<String, int>>(
              future: subscriptionRepo.getUsageStats(securityContext),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final usage = snapshot.data!;
                final tier = subscription.tier;

                return Column(
                  children: [
                    BillingUsageBar(
                      label: 'Providers',
                      current: usage['providers'] ?? 0,
                      max: tier.maxProviders,
                      theme: theme,
                    ),
                    const SizedBox(height: 12),
                    BillingUsageBar(
                      label: 'Locations',
                      current: usage['locations'] ?? 0,
                      max: tier.maxLocations,
                      theme: theme,
                    ),
                    const SizedBox(height: 12),
                    BillingUsageBar(
                      label: 'Appointments',
                      current: usage['appointmentsThisMonth'] ?? 0,
                      max: tier.maxAppointmentsPerMonth,
                      theme: theme,
                    ),
                    const SizedBox(height: 12),
                    BillingUsageBar(
                      label: 'SMS Sent',
                      current: usage['smsThisMonth'] ?? 0,
                      max: tier.includedSmsPerMonth,
                      theme: theme,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
