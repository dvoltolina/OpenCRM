/// Client AI insights panel for client detail pages.
///
/// Agent AI-12: AI Dashboard & UI Components
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/client.dart';
import '../../../data/models/security_context.dart';
import '../../models/client_risk_score.dart';
import '../../models/risk_indicator.dart';
import '../../providers/ai_providers.dart';
import 'client_insights_helpers.dart';
import 'prediction_widgets.dart';

/// Panel showing AI insights for a specific client.
class ClientAiInsightsPanel extends ConsumerWidget {
  const ClientAiInsightsPanel({
    super.key,
    required this.securityContext,
    required this.client,
    this.expanded = true,
    this.onViewDetails,
  });

  final SecurityContext securityContext;
  final Client client;
  final bool expanded;
  final VoidCallback? onViewDetails;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final riskScoreAsync = ref.watch(
      clientRiskScoreProvider((
        context: securityContext,
        clientId: client.id,
      )),
    );

    return riskScoreAsync.when(
      data: (riskScore) {
        if (riskScore == null || riskScore.isEmpty) {
          return EmptyInsightsCard(clientName: client.firstName);
        }
        return expanded
            ? _ExpandedInsightsCard(
                riskScore: riskScore,
                onViewDetails: onViewDetails,
              )
            : _CompactInsightsCard(
                riskScore: riskScore,
                onViewDetails: onViewDetails,
              );
      },
      loading: () => const InsightsLoadingCard(),
      error: (_, __) => const InsightsErrorCard(),
    );
  }
}

/// Compact version of insights panel.
class _CompactInsightsCard extends StatelessWidget {
  const _CompactInsightsCard({
    required this.riskScore,
    this.onViewDetails,
  });

  final ClientRiskScore riskScore;
  final VoidCallback? onViewDetails;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onViewDetails,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // Health score circle
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: getInsightsHealthColor(riskScore.overallHealthScore)
                      .withValues(alpha: 0.15),
                  border: Border.all(
                    color: getInsightsHealthColor(riskScore.overallHealthScore),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    riskScore.overallHealthScore.toString(),
                    style: TextStyle(
                      color:
                          getInsightsHealthColor(riskScore.overallHealthScore),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Labels
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 14,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'AI Insights',
                          style:
                              Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                        ),
                      ],
                    ),
                    Text(
                      riskScore.healthLabel,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                ),
              ),

              // Risk indicator
              if (riskScore.needsAttention)
                _NeedsAttentionBadge()
              else if (riskScore.isPotentialVip)
                _VipBadge(),

              if (onViewDetails != null) ...[
                const SizedBox(width: AppSpacing.sm),
                const Icon(Icons.chevron_right, size: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NeedsAttentionBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber_outlined, size: 14, color: AppColors.error),
          const SizedBox(width: 4),
          Text(
            'Needs Attention',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.error,
            ),
          ),
        ],
      ),
    );
  }
}

class _VipBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, size: 14, color: AppColors.warning),
          const SizedBox(width: 4),
          Text(
            'VIP',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }
}

/// Expanded version of insights panel.
class _ExpandedInsightsCard extends StatelessWidget {
  const _ExpandedInsightsCard({
    required this.riskScore,
    this.onViewDetails,
  });

  final ClientRiskScore riskScore;
  final VoidCallback? onViewDetails;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(context),
            const SizedBox(height: AppSpacing.lg),

            // Score gauges
            _buildScoreGauges(),

            // Risk indicators
            if (riskScore.riskIndicators.isNotEmpty) ...[
              const Divider(height: AppSpacing.xxl),
              _buildRiskIndicators(context),
            ],

            // VIP indicators
            if (riskScore.vipIndicators.isNotEmpty) ...[
              const Divider(height: AppSpacing.xxl),
              _buildVipIndicators(context),
            ],

            // Recommended actions
            if (riskScore.recommendedActions.isNotEmpty) ...[
              const Divider(height: AppSpacing.xxl),
              _buildRecommendedActions(context),
            ],

            // View details button
            if (onViewDetails != null) ...[
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: TextButton.icon(
                  onPressed: onViewDetails,
                  icon: const Icon(Icons.analytics_outlined, size: 18),
                  label: const Text('View Full Analysis'),
                ),
              ),
            ],

            // Analysis info
            const SizedBox(height: AppSpacing.md),
            _buildAnalysisInfo(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.auto_awesome,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          'AI Insights',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const Spacer(),
        if (!riskScore.hasReliableData)
          Tooltip(
            message: 'Limited data available for analysis',
            child: Icon(
              Icons.info_outline,
              size: 18,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }

  Widget _buildScoreGauges() {
    return Row(
      children: [
        Expanded(
          child: InsightsScoreGauge(
            label: 'Health',
            value: riskScore.overallHealthScore,
            trend: null,
            color: getInsightsHealthColor(riskScore.overallHealthScore),
          ),
        ),
        Expanded(
          child: InsightsScoreGauge(
            label: 'Churn Risk',
            value: riskScore.churnRiskScore,
            trend: riskScore.churnTrend,
            color: getInsightsRiskColor(riskScore.churnRiskScore),
            invertTrend: true,
          ),
        ),
        Expanded(
          child: InsightsScoreGauge(
            label: 'Satisfaction',
            value: riskScore.satisfactionScore,
            trend: riskScore.satisfactionTrend,
            color: getInsightsSatisfactionColor(riskScore.satisfactionScore),
          ),
        ),
        Expanded(
          child: InsightsScoreGauge(
            label: 'VIP Score',
            value: riskScore.vipScore,
            trend: riskScore.vipTrend,
            color: riskScore.vipScore >= 70
                ? AppColors.warning
                : context.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildRiskIndicators(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Risk Indicators',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: riskScore.riskIndicators.take(5).map((indicator) {
            return RiskIndicatorChip(
              label: indicator.description,
              severity: indicator.severity,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildVipIndicators(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'VIP Indicators',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: riskScore.vipIndicators.take(3).map((indicator) {
            return _VipIndicatorChip(description: indicator.description);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRecommendedActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recommended Actions',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: AppSpacing.md),
        ...riskScore.recommendedActions.take(3).map((action) {
          return ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              _getActionIcon(action.actionId),
              size: 20,
              color: _getPriorityColor(action.priority),
            ),
            title: Text(
              action.title,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            subtitle: Text(
              action.description,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAnalysisInfo(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.history,
          size: 12,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text(
          '${riskScore.textsAnalyzed} communications analyzed',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  IconData _getActionIcon(String actionId) {
    if (actionId.contains('call')) return Icons.phone_outlined;
    if (actionId.contains('email')) return Icons.email_outlined;
    if (actionId.contains('sms') || actionId.contains('message')) {
      return Icons.sms_outlined;
    }
    if (actionId.contains('discount') || actionId.contains('offer')) {
      return Icons.local_offer_outlined;
    }
    return Icons.lightbulb_outline;
  }

  Color _getPriorityColor(ClientActionPriority priority) {
    return switch (priority) {
      ClientActionPriority.critical => AppColors.error,
      ClientActionPriority.high => AppColors.error,
      ClientActionPriority.medium => AppColors.warning,
      ClientActionPriority.low => AppColors.textSecondary,
    };
  }
}

class _VipIndicatorChip extends StatelessWidget {
  const _VipIndicatorChip({required this.description});

  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, size: 14, color: AppColors.warning),
          const SizedBox(width: 4),
          Text(
            description,
            style: const TextStyle(fontSize: 12, color: AppColors.warning),
          ),
        ],
      ),
    );
  }
}
