/// Reusable prediction display widgets.
///
/// Agent AI-12: AI Dashboard & UI Components
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../models/noshow_prediction.dart';
import '../../models/risk_indicator.dart';

// Re-export client risk widgets for convenience
export 'client_risk_widgets.dart';

/// Displays a no-show prediction with risk gauge and details.
class PredictionCard extends StatelessWidget {
  const PredictionCard({
    super.key,
    required this.prediction,
    this.clientName,
    this.serviceName,
    this.appointmentTime,
    this.onTap,
    this.showActions = true,
    this.compact = false,
  });

  final NoshowPrediction prediction;
  final String? clientName;
  final String? serviceName;
  final DateTime? appointmentTime;
  final VoidCallback? onTap;
  final bool showActions;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (!prediction.isAvailable) {
      return _UnavailableCard(compact: compact);
    }

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.lg),
          child:
              compact ? _buildCompactContent(context) : _buildFullContent(context),
        ),
      ),
    );
  }

  Widget _buildCompactContent(BuildContext context) {
    return Row(
      children: [
        NoShowRiskGauge(
          probability: prediction.probability,
          riskLevel: prediction.riskLevel,
          size: 48,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (clientName != null)
                Text(
                  clientName!,
                  style: Theme.of(context).textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              Text(
                '${prediction.probabilityPercent}% no-show risk',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Color(prediction.riskLevel.colorValue),
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
        RiskLevelChip(riskLevel: prediction.riskLevel),
      ],
    );
  }

  Widget _buildFullContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Row(
          children: [
            NoShowRiskGauge(
              probability: prediction.probability,
              riskLevel: prediction.riskLevel,
              size: 64,
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
                  if (serviceName != null)
                    Text(
                      serviceName!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  const SizedBox(height: AppSpacing.xs),
                  RiskLevelChip(riskLevel: prediction.riskLevel),
                ],
              ),
            ),
          ],
        ),

        // Top risk factors
        if (prediction.topFeatures.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Risk Factors',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: prediction.riskIncreasingFeatures.take(3).map((feature) {
              return RiskIndicatorChip(
                label: feature.featureDisplayName,
                severity: feature.increasesRisk
                    ? IndicatorSeverity.high
                    : IndicatorSeverity.low,
              );
            }).toList(),
          ),
        ],

        // Recommended actions
        if (showActions && prediction.urgentActions.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Recommended Actions',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          ...prediction.urgentActions.take(2).map((action) {
            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                _getActionIcon(action.actionId),
                color: Color(action.priority.colorValue),
                size: 20,
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

        // Confidence footer
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Icon(
              Icons.info_outline,
              size: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              '${prediction.confidencePercent}% confidence',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const Spacer(),
            if (!prediction.isValid)
              Text(
                'Expired',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
          ],
        ),
      ],
    );
  }

  IconData _getActionIcon(String actionId) {
    return switch (actionId) {
      'send_reminder' => Icons.notifications_outlined,
      'collect_deposit' => Icons.payment_outlined,
      'confirm_appointment' => Icons.check_circle_outline,
      'call_client' => Icons.phone_outlined,
      'add_waitlist_backup' => Icons.list_outlined,
      _ => Icons.lightbulb_outline,
    };
  }
}

/// Circular gauge showing no-show probability.
class NoShowRiskGauge extends StatelessWidget {
  const NoShowRiskGauge({
    super.key,
    required this.probability,
    required this.riskLevel,
    this.size = 64,
  });

  final double probability;
  final RiskLevel riskLevel;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = Color(riskLevel.colorValue);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: size * 0.1,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
              valueColor: AlwaysStoppedAnimation(
                Theme.of(context).colorScheme.surfaceContainerHigh,
              ),
            ),
          ),
          // Progress circle
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: probability,
              strokeWidth: size * 0.1,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation(color),
              strokeCap: StrokeCap.round,
            ),
          ),
          // Percentage text
          Text(
            '${(probability * 100).round()}%',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: size * 0.22,
                ),
          ),
        ],
      ),
    );
  }
}

/// Chip displaying risk level with appropriate color.
class RiskLevelChip extends StatelessWidget {
  const RiskLevelChip({
    super.key,
    required this.riskLevel,
    this.small = false,
  });

  final RiskLevel riskLevel;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final color = Color(riskLevel.colorValue);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? AppSpacing.sm : AppSpacing.md,
        vertical: small ? AppSpacing.xs : AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getIcon(),
            size: small ? 12 : 16,
            color: color,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            riskLevel.shortLabel,
            style: TextStyle(
              color: color,
              fontSize: small ? 10 : 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIcon() {
    return switch (riskLevel) {
      RiskLevel.high => Icons.error_outline,
      RiskLevel.medium => Icons.warning_amber_outlined,
      RiskLevel.low => Icons.check_circle_outline,
      RiskLevel.unknown => Icons.help_outline,
    };
  }
}

/// Chip for displaying risk indicators.
class RiskIndicatorChip extends StatelessWidget {
  const RiskIndicatorChip({
    super.key,
    required this.label,
    required this.severity,
    this.onTap,
  });

  final String label;
  final IndicatorSeverity severity;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = _getSeverityColor();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.chip),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.chip),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Color _getSeverityColor() {
    return switch (severity) {
      IndicatorSeverity.critical => AppColors.error,
      IndicatorSeverity.high => AppColors.error,
      IndicatorSeverity.medium => AppColors.warning,
      IndicatorSeverity.low => AppColors.success,
    };
  }
}

/// Badge showing sentiment score.
class SentimentBadge extends StatelessWidget {
  const SentimentBadge({
    super.key,
    required this.score,
    this.size = SentimentBadgeSize.medium,
    this.showLabel = true,
  });

  final double score;
  final SentimentBadgeSize size;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    final icon = _getIcon();
    final label = _getLabel();

    final iconSize = switch (size) {
      SentimentBadgeSize.small => 16.0,
      SentimentBadgeSize.medium => 20.0,
      SentimentBadgeSize.large => 24.0,
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: showLabel ? AppSpacing.md : AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: color),
          if (showLabel) ...[
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: size == SentimentBadgeSize.small ? 10 : 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getColor() {
    if (score >= 0.3) return AppColors.success; // Positive
    if (score >= -0.3) return AppColors.textSecondary; // Neutral
    return AppColors.error; // Negative
  }

  IconData _getIcon() {
    if (score >= 0.3) return Icons.sentiment_satisfied_alt;
    if (score >= -0.3) return Icons.sentiment_neutral;
    return Icons.sentiment_dissatisfied;
  }

  String _getLabel() {
    if (score >= 0.3) return 'Positive';
    if (score >= -0.3) return 'Neutral';
    return 'Negative';
  }
}

enum SentimentBadgeSize { small, medium, large }

/// Card shown when prediction is unavailable.
class _UnavailableCard extends StatelessWidget {
  const _UnavailableCard({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.lg),
        child: Row(
          children: [
            Icon(
              Icons.cloud_off_outlined,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              size: compact ? 24 : 32,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Prediction Unavailable',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  if (!compact)
                    Text(
                      'AI service is temporarily unavailable',
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
