import 'package:flutter/material.dart';

import '../../../../data/models/appointment.dart';
import '../../../../data/models/recurrence_pattern.dart';

/// Card displaying recurring appointment series information.
class RecurringSeriesCard extends StatelessWidget {
  const RecurringSeriesCard({
    required this.seriesAppointments,
    required this.currentOccurrenceIndex,
    super.key,
  });

  final List<Appointment> seriesAppointments;
  final int? currentOccurrenceIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final series = seriesAppointments;
    final totalCount = series.length;
    final occurrenceNumber = currentOccurrenceIndex != null
        ? currentOccurrenceIndex! + 1
        : null;

    // Get recurrence pattern from parent
    final parent = series.firstWhere(
      (apt) => apt.recurrencePattern != null,
      orElse: () => series.first,
    );
    final pattern = parent.recurrencePattern;

    // Count upcoming vs past
    final now = DateTime.now();
    final upcomingCount = series.where((apt) => apt.startTime.isAfter(now)).length;
    final completedCount = totalCount - upcomingCount;

    return Card(
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.repeat,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Recurring Appointment',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Occurrence indicator
            if (occurrenceNumber != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Appointment $occurrenceNumber of $totalCount',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const SizedBox(height: 12),

            // Pattern description
            if (pattern != null) ...[
              Row(
                children: [
                  Icon(
                    Icons.schedule_outlined,
                    size: 16,
                    color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      pattern.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.event_outlined,
                    size: 16,
                    color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    pattern.endDescription,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Series stats
            Row(
              children: [
                _buildSeriesStatChip(
                  '$upcomingCount upcoming',
                  Icons.event_available,
                  theme.colorScheme.primary,
                  theme,
                ),
                const SizedBox(width: 8),
                _buildSeriesStatChip(
                  '$completedCount completed',
                  Icons.check_circle_outline,
                  theme.colorScheme.tertiary,
                  theme,
                ),
              ],
            ),

            // Series navigation hint
            const SizedBox(height: 16),
            Text(
              'Use the cancel or reschedule options to manage this appointment or the entire series.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeriesStatChip(String label, IconData icon, Color color, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
