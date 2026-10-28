import 'package:flutter/material.dart';

import '../../../../data/models/subscription.dart';
import 'billing_status_chip.dart';

/// Current plan card widget showing subscription details
class BillingCurrentPlanCard extends StatelessWidget {
  final Subscription subscription;
  final ThemeData theme;

  const BillingCurrentPlanCard({
    super.key,
    required this.subscription,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
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
                      'Current Plan',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subscription.tier.displayName,
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                BillingStatusChip(subscription: subscription, theme: theme),
              ],
            ),
            const SizedBox(height: 16),
            if (subscription.tier != SubscriptionTier.free)
              Column(
                children: [
                  _buildInfoRow(
                    'Billing Cycle',
                    _formatBillingCycle(subscription),
                    theme,
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    'Amount',
                    _formatAmount(subscription),
                    theme,
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    'Next Billing Date',
                    _formatDate(subscription.currentPeriodEnd),
                    theme,
                  ),
                  if (subscription.cancelAtPeriodEnd) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber, color: Colors.orange[700]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Your subscription will end on ${_formatDate(subscription.currentPeriodEnd)}',
                              style: TextStyle(color: Colors.orange[900]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (subscription.isTrialing) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[700]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${subscription.daysRemainingInTrial} days remaining in trial',
                              style: TextStyle(color: Colors.blue[900]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }

  String _formatBillingCycle(Subscription subscription) {
    final days = subscription.currentPeriodEnd
        .difference(subscription.currentPeriodStart)
        .inDays;
    return days >= 300 ? 'Annual' : 'Monthly';
  }

  String _formatAmount(Subscription subscription) {
    final isAnnual = _formatBillingCycle(subscription) == 'Annual';
    final amount = isAnnual
        ? subscription.tier.annualPriceCents
        : subscription.tier.monthlyPriceCents;
    return '\$${(amount! / 100).toStringAsFixed(2)}${isAnnual ? '/year' : '/month'}';
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
