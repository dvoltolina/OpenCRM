import 'package:flutter/material.dart';

import '../../../../core/services/feature_gating_service.dart';
import '../../../../core/ui/components/components.dart';
import '../../../../data/models/subscription.dart';

/// Upgrade recommendation card
class BillingUpgradeRecommendationCard extends StatelessWidget {
  final dynamic securityContext;
  final ThemeData theme;
  final FeatureGatingService featureGating;

  const BillingUpgradeRecommendationCard({
    super.key,
    required this.securityContext,
    required this.theme,
    required this.featureGating,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: featureGating.getUpgradeRecommendation(securityContext),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }

        final recommendation = snapshot.data!;

        return Card(
          color: Colors.amber[50],
          child: Padding(
            padding: AppSpacing.cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: Colors.amber[800]),
                    HSpace.sm,
                    Text(
                      'Upgrade Recommended',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber[900],
                      ),
                    ),
                  ],
                ),
                VSpace.sm,
                Text(
                  'Consider upgrading to ${recommendation.recommendedTier.displayName}:',
                  style: TextStyle(color: Colors.amber[900]),
                ),
                VSpace.xs,
                ...recommendation.reasons.map((reason) => Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 4),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle,
                              size: 16, color: Colors.amber[800]),
                          HSpace.xs,
                          Expanded(
                            child: Text(
                              reason,
                              style: TextStyle(color: Colors.amber[900]),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        );
      },
    );
  }
}
