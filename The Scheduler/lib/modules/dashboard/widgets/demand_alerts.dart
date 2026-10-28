import 'package:flutter/material.dart';

import '../../../ai/models/demand_forecast.dart';
import '../../../core/ui/components/components.dart';

/// Urgent days alert.
class UrgentDaysAlert extends StatelessWidget {
  const UrgentDaysAlert({super.key, required this.urgentDays});

  final List<StaffingRecommendation> urgentDays;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber,
                color: AppColors.error,
                size: AppIconSize.sm,
              ),
              HSpace.xs,
              Text(
                'Staffing Attention Needed',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          VSpace.xs,
          ...urgentDays.take(3).map((rec) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
              child: Text(
                '• ${_formatDate(rec.date)}: ${rec.reasoning}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.error,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[date.weekday - 1]} ${date.day}/${date.month}';
  }
}

/// High demand days section.
class HighDemandSection extends StatelessWidget {
  const HighDemandSection({
    super.key,
    required this.highDemandDays,
    this.onDaySelected,
  });

  final List<DemandForecast> highDemandDays;
  final void Function(DemandForecast)? onDaySelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.local_fire_department,
              color: AppColors.warning,
              size: AppIconSize.xs,
            ),
            HSpace.xs,
            Text(
              'High Demand Days',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        VSpace.xs,
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: highDemandDays.take(5).map((day) {
            return ActionChip(
              label: Text(
                '${day.dayName} ${day.date.day}/${day.date.month}',
                style: theme.textTheme.labelSmall,
              ),
              avatar: Icon(
                day.demandLevel == DemandLevel.veryHigh
                    ? Icons.whatshot
                    : Icons.trending_up,
                size: AppIconSize.xs,
                color: day.demandLevel == DemandLevel.veryHigh
                    ? AppColors.error
                    : AppColors.warning,
              ),
              backgroundColor: day.demandLevel == DemandLevel.veryHigh
                  ? AppColors.error.withValues(alpha: 0.1)
                  : AppColors.warning.withValues(alpha: 0.1),
              onPressed:
                  onDaySelected != null ? () => onDaySelected!(day) : null,
            );
          }).toList(),
        ),
      ],
    );
  }
}
