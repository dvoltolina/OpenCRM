import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ai/models/demand_forecast.dart';
import '../../../core/providers/providers.dart';
import '../../../core/ui/components/components.dart';
import 'demand_alerts.dart';
import 'forecast_chart_components.dart';

/// Chart displaying demand forecast visualization.
///
/// Shows predicted booking volume over time with confidence
/// intervals and staffing recommendations.
///
/// Updated with Modern Sophisticated Blue design system - gradient header and soft shadows.
/// Agent AI-21: Waitlist Intelligence & Demand Forecasting
class DemandForecastChart extends ConsumerWidget {
  const DemandForecastChart({
    super.key,
    required this.result,
    this.onDaySelected,
    this.showStaffingRecommendations = true,
    this.height = 250,
  });

  /// Forecast result to display.
  final DemandForecastResult result;

  /// Called when a day is selected.
  final void Function(DemandForecast day)? onDaySelected;

  /// Whether to show staffing recommendations.
  final bool showStaffingRecommendations;

  /// Chart height.
  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final config = ref.watch(appConfigProvider);
    final branding = config.branding;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        // Soft layered shadows with blue tint
        boxShadow: [
          BoxShadow(
            color: branding.primaryColor.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: branding.accentColor.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gradient header
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  branding.primaryColor.withValues(alpha: 0.1),
                  branding.accentColor.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppRadius.card),
                topRight: Radius.circular(AppRadius.card),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.trending_up,
                  color: branding.accentColor,
                  size: AppIconSize.md,
                ),
                HSpace.sm,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Demand Forecast',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: branding.primaryColor,
                        ),
                      ),
                      Text(
                        '${result.forecastDays} day outlook',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                // Summary stats
                StatChip(
                  label: 'Avg',
                  value: '${result.averageDemand.round()}',
                  color: Colors.blue,
                ),
                HSpace.xs,
                if (result.peakDay != null)
                  StatChip(
                    label: 'Peak',
                    value: '${result.peakDay!.predictedCount.round()}',
                    color: Colors.orange,
                  ),
              ],
            ),
          ),
          // Chart content
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: height,
                  child: SimpleForecastChart(
                    forecasts: result.forecasts,
                    onDaySelected: onDaySelected,
                  ),
                ),
                VSpace.sm,
                const ChartLegend(),
                // Urgent days alert
                if (result.hasUrgentNeeds) ...[
                  VSpace.md,
                  UrgentDaysAlert(urgentDays: result.urgentDays),
                ],
                // High demand days
                if (result.highDemandDays.isNotEmpty) ...[
                  VSpace.md,
                  HighDemandSection(
                    highDemandDays: result.highDemandDays,
                    onDaySelected: onDaySelected,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Staffing recommendation card.
/// Updated with Modern Sophisticated Blue design system - soft shadows and gradient accents.
class StaffingRecommendationCard extends ConsumerWidget {
  const StaffingRecommendationCard({
    super.key,
    required this.recommendation,
    this.onActionTap,
  });

  final StaffingRecommendation recommendation;
  final void Function(StaffingSuggestion suggestion)? onActionTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final config = ref.watch(appConfigProvider);
    final branding = config.branding;
    final color = _getActionColor(recommendation.action);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        // Soft layered shadows
        boxShadow: [
          BoxShadow(
            color: branding.primaryColor.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: branding.accentColor.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with gradient background
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color.shade100,
                        color.shade50,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(
                    _getActionIcon(recommendation.action),
                    color: color.shade700,
                    size: AppIconSize.md,
                  ),
                ),
                HSpace.sm,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recommendation.action.displayName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: color.shade700,
                        ),
                      ),
                      Text(
                        _formatDate(recommendation.date),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                // Urgency indicator
                if (recommendation.isUrgent)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: AppSpacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.card),
                    ),
                    child: Text(
                      'Urgent',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            VSpace.sm,
            // Reasoning
            Text(
              recommendation.reasoning,
              style: theme.textTheme.bodyMedium,
            ),
            // Capacity info
            VSpace.xs,
            Row(
              children: [
                CapacityChip(
                  label: 'Current',
                  value: '${recommendation.currentCapacity}',
                  color: Colors.grey,
                ),
                HSpace.xs,
                Icon(
                  Icons.arrow_forward,
                  size: AppIconSize.xs,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                HSpace.xs,
                CapacityChip(
                  label: 'Recommended',
                  value: '${recommendation.recommendedCapacity}',
                  color: color,
                ),
              ],
            ),
            // Suggestions
            if (recommendation.suggestions.isNotEmpty) ...[
              VSpace.sm,
              const Divider(),
              VSpace.xs,
              ...recommendation.suggestions.map((suggestion) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: InkWell(
                    onTap: onActionTap != null
                        ? () => onActionTap!(suggestion)
                        : null,
                    child: Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          size: AppIconSize.xs,
                          color: color.shade600,
                        ),
                        HSpace.xs,
                        Expanded(
                          child: Text(
                            suggestion.description,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                        if (onActionTap != null)
                          Icon(
                            Icons.chevron_right,
                            size: AppIconSize.xs,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  MaterialColor _getActionColor(StaffingAction action) {
    switch (action) {
      case StaffingAction.addStaff:
        return Colors.orange;
      case StaffingAction.runPromotion:
        return Colors.purple;
      case StaffingAction.optimal:
        return Colors.green;
      case StaffingAction.reduceStaff:
        return Colors.blue;
      case StaffingAction.reduceHours:
        return Colors.grey;
    }
  }

  IconData _getActionIcon(StaffingAction action) {
    switch (action) {
      case StaffingAction.addStaff:
        return Icons.person_add;
      case StaffingAction.runPromotion:
        return Icons.campaign;
      case StaffingAction.optimal:
        return Icons.check_circle;
      case StaffingAction.reduceStaff:
        return Icons.person_remove;
      case StaffingAction.reduceHours:
        return Icons.schedule;
    }
  }

  String _formatDate(DateTime date) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return '${days[date.weekday - 1]}, ${date.day}/${date.month}';
  }
}
