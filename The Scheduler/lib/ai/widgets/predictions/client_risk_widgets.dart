/// Client risk score display widgets.
///
/// Agent AI-12: AI Dashboard & UI Components
/// Extracted from prediction_widgets.dart for HIPAA 600-line compliance.
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../models/client_risk_score.dart';

/// Client risk score card displaying overall health metrics.
class ClientRiskCard extends StatelessWidget {
  const ClientRiskCard({
    super.key,
    required this.riskScore,
    this.clientName,
    this.onTap,
    this.compact = false,
  });

  final ClientRiskScore riskScore;
  final String? clientName;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  ScoreCircle(
                    value: riskScore.overallHealthScore,
                    label: 'Health',
                    color: getHealthColor(riskScore.overallHealthScore),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (clientName != null)
                          Text(
                            clientName!,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        Text(
                          riskScore.healthLabel,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: getHealthColor(riskScore.overallHealthScore),
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              if (!compact) ...[
                const Divider(height: AppSpacing.xxl),

                // Score breakdown
                Row(
                  children: [
                    Expanded(
                      child: ScoreItem(
                        label: 'Churn Risk',
                        value: riskScore.churnRiskScore,
                        trend: riskScore.churnTrend,
                        invertTrend: true,
                      ),
                    ),
                    Expanded(
                      child: ScoreItem(
                        label: 'Satisfaction',
                        value: riskScore.satisfactionScore,
                        trend: riskScore.satisfactionTrend,
                      ),
                    ),
                    Expanded(
                      child: ScoreItem(
                        label: 'VIP Score',
                        value: riskScore.vipScore,
                        trend: riskScore.vipTrend,
                      ),
                    ),
                  ],
                ),

                // Risk factors
                if (riskScore.topRiskFactors.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Top Risk Factors',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: riskScore.topRiskFactors.take(3).map((factor) {
                      return Chip(
                        label: Text(factor),
                        labelStyle: const TextStyle(fontSize: 11),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      );
                    }).toList(),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Returns color based on health score value.
Color getHealthColor(int score) {
  if (score >= 80) return AppColors.success;
  if (score >= 60) return AppColors.success;
  if (score >= 40) return AppColors.warning;
  if (score >= 20) return AppColors.warning;
  return AppColors.error;
}

/// Circular score display widget.
class ScoreCircle extends StatelessWidget {
  const ScoreCircle({
    super.key,
    required this.value,
    required this.label,
    required this.color,
  });

  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.15),
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: Text(
              value.toString(),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// Score item with trend indicator.
class ScoreItem extends StatelessWidget {
  const ScoreItem({
    super.key,
    required this.label,
    required this.value,
    required this.trend,
    this.invertTrend = false,
  });

  final String label;
  final int value;
  final ScoreTrend trend;
  final bool invertTrend;

  @override
  Widget build(BuildContext context) {
    final trendIcon = switch (trend) {
      ScoreTrend.improving => Icons.trending_up,
      ScoreTrend.stable => Icons.trending_flat,
      ScoreTrend.declining => Icons.trending_down,
    };

    final trendColor = _getTrendColor();

    return Column(
      children: [
        Text(
          value.toString(),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(trendIcon, size: 14, color: trendColor),
            const SizedBox(width: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }

  Color _getTrendColor() {
    final isPositive = invertTrend
        ? trend == ScoreTrend.declining
        : trend == ScoreTrend.improving;

    if (isPositive) return AppColors.success;
    if (trend == ScoreTrend.stable) return AppColors.textSecondary;
    return AppColors.error;
  }
}
