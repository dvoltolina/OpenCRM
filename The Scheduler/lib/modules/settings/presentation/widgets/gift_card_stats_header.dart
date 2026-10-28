import 'package:flutter/material.dart';

import '../../../../core/ui/components/components.dart';
import '../../../../data/repositories/gift_card_repository.dart';

/// Stats header displaying gift card totals
class GiftCardStatsHeader extends StatelessWidget {
  const GiftCardStatsHeader({required this.stats, super.key});

  final GiftCardStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: AppSpacing.cardPadding,
      child: Row(
        children: [
          Expanded(
            child: GiftCardStatCard(
              label: 'Total Sold',
              value: '\$${(stats.totalSoldCents / 100).toStringAsFixed(2)}',
              subValue: '${stats.totalSoldCount} cards',
              color: theme.colorScheme.primary,
              icon: Icons.sell,
            ),
          ),
          HSpace.sm,
          Expanded(
            child: GiftCardStatCard(
              label: 'Outstanding',
              value: '\$${(stats.outstandingBalanceCents / 100).toStringAsFixed(2)}',
              subValue: 'Active balance',
              color: Colors.orange,
              icon: Icons.account_balance_wallet,
            ),
          ),
          HSpace.sm,
          Expanded(
            child: GiftCardStatCard(
              label: 'Redeemed',
              value: '\$${(stats.totalRedeemedCents / 100).toStringAsFixed(2)}',
              subValue: '${stats.redemptionCount} redemptions',
              color: Colors.green,
              icon: Icons.redeem,
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual stat card widget
class GiftCardStatCard extends StatelessWidget {
  const GiftCardStatCard({
    required this.label,
    required this.value,
    required this.subValue,
    required this.color,
    required this.icon,
    super.key,
  });

  final String label;
  final String value;
  final String subValue;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: color),
                HSpace.xs,
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            VSpace.xs,
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            VSpace.xxs,
            Text(
              subValue,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton loading state for stats header
class GiftCardStatsHeaderSkeleton extends StatelessWidget {
  const GiftCardStatsHeaderSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.cardPadding,
      child: Row(
        children: List.generate(3, (index) {
          return Expanded(
            child: Card(
              child: Container(
                height: 100,
                padding: AppSpacing.cardPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 60,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    VSpace.sm,
                    Container(
                      width: 80,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).expand((w) => [w, HSpace.sm]).take(5).toList(),
      ),
    );
  }
}
