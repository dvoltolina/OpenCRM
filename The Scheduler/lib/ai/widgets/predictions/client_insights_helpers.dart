/// Helper widgets for client AI insights panel.
///
/// Agent AI-12: AI Dashboard & UI Components
/// Extracted from client_ai_insights_panel.dart for HIPAA 600-line compliance.
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../models/client_risk_score.dart';

/// Score gauge widget for insights panel.
class InsightsScoreGauge extends StatelessWidget {
  const InsightsScoreGauge({
    super.key,
    required this.label,
    required this.value,
    required this.trend,
    required this.color,
    this.invertTrend = false,
  });

  final String label;
  final int value;
  final ScoreTrend? trend;
  final Color color;
  final bool invertTrend;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Score circle
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.15),
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
        // Trend indicator
        if (trend != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getTrendIcon(),
                size: 12,
                color: _getTrendColor(),
              ),
              const SizedBox(width: 2),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          )
        else
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
    );
  }

  IconData _getTrendIcon() {
    return switch (trend!) {
      ScoreTrend.improving => Icons.trending_up,
      ScoreTrend.stable => Icons.trending_flat,
      ScoreTrend.declining => Icons.trending_down,
    };
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

/// Empty state card for insights.
class EmptyInsightsCard extends StatelessWidget {
  const EmptyInsightsCard({
    super.key,
    required this.clientName,
  });

  final String clientName;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Icon(
              Icons.auto_awesome_outlined,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Insights',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(
                    'Not enough data for $clientName yet',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Loading state card for insights.
class InsightsLoadingCard extends StatelessWidget {
  const InsightsLoadingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              'Loading AI insights...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

/// Error state card for insights.
class InsightsErrorCard extends StatelessWidget {
  const InsightsErrorCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Icon(
              Icons.cloud_off_outlined,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              'AI insights unavailable',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// Color helper functions

/// Get health score color.
Color getInsightsHealthColor(int score) {
  if (score >= 80) return AppColors.success;
  if (score >= 60) return AppColors.success;
  if (score >= 40) return AppColors.warning;
  if (score >= 20) return AppColors.warning;
  return AppColors.error;
}

/// Get risk score color (inverted - high is bad).
Color getInsightsRiskColor(int score) {
  if (score >= 70) return AppColors.error;
  if (score >= 40) return AppColors.warning;
  return AppColors.success;
}

/// Get satisfaction score color.
Color getInsightsSatisfactionColor(int score) {
  if (score >= 80) return AppColors.success;
  if (score >= 60) return AppColors.success;
  if (score >= 40) return AppColors.warning;
  return AppColors.error;
}
