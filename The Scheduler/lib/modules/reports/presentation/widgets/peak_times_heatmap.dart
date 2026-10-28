import 'package:flutter/material.dart';

import '../../../../data/models/analytics_metrics.dart';

/// Heatmap showing busy times by day of week and hour
class PeakTimesHeatmap extends StatelessWidget {
  const PeakTimesHeatmap({super.key, required this.metrics});

  final AnalyticsMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Get hour distribution
    final hourCounts = metrics.appointmentsByHourOfDay;
    if (hourCounts.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              'No peak times data available',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ),
      );
    }

    // Get max count for color intensity
    final maxCount = hourCounts.values.isEmpty
        ? 1
        : hourCounts.values.reduce((a, b) => a > b ? a : b);

    // Business hours (8 AM to 6 PM)
    final businessHours = List.generate(11, (i) => 8 + i);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Peak Booking Times',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Appointments by hour of day',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            // Hour heatmap
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: businessHours.map((hour) {
                final count = hourCounts[hour] ?? 0;
                final intensity = maxCount > 0 ? count / maxCount : 0.0;
                final color = Color.lerp(
                  theme.colorScheme.primaryContainer,
                  theme.colorScheme.primary,
                  intensity,
                )!;

                return Tooltip(
                  message: '$count appointments at ${_formatHour(hour)}',
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _formatHour(hour),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: intensity > 0.5
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          count.toString(),
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: intensity > 0.5
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            // Legend
            Row(
              children: [
                Text('Less busy', style: theme.textTheme.bodySmall),
                const SizedBox(width: 8),
                Container(
                  width: 100,
                  height: 20,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primaryContainer,
                        theme.colorScheme.primary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                Text('More busy', style: theme.textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 24),
            // Day of week breakdown
            Text(
              'Appointments by Day of Week',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ...metrics.appointmentsByDayOfWeek.entries.map((entry) {
              final percentage = metrics.totalAppointments > 0
                  ? (entry.value / metrics.totalAppointments) * 100
                  : 0.0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(entry.key, style: theme.textTheme.bodyMedium),
                        Text(
                          '${entry.value} (${percentage.toStringAsFixed(1)}%)',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        minHeight: 8,
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation(
                          theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _formatHour(int hour) {
    if (hour == 0) return '12 AM';
    if (hour < 12) return '$hour AM';
    if (hour == 12) return '12 PM';
    return '${hour - 12} PM';
  }
}
