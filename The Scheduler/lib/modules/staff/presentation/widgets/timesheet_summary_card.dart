import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/timesheet_summary.dart';

/// Summary card displaying timesheet statistics and status breakdown.
///
/// Shows total hours, regular/overtime, breaks, shifts, estimated pay,
/// and a breakdown of entry statuses (approved, pending, rejected).
class TimesheetSummaryCard extends StatelessWidget {
  const TimesheetSummaryCard({
    super.key,
    required this.timesheet,
  });

  final TimesheetSummary timesheet;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat.MMMd();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.summarize,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Period Summary',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${dateFormat.format(timesheet.periodStart)} - ${dateFormat.format(timesheet.periodEnd)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Stats grid
            Wrap(
              spacing: 32,
              runSpacing: 16,
              children: [
                SummaryStatItem(
                  label: 'Total Hours',
                  value: timesheet.totalWorkedHours.toStringAsFixed(1),
                  icon: Icons.schedule,
                ),
                SummaryStatItem(
                  label: 'Regular Hours',
                  value: timesheet.regularHours.toStringAsFixed(1),
                  icon: Icons.work_outline,
                ),
                if (timesheet.hasOvertime)
                  SummaryStatItem(
                    label: 'Overtime',
                    value: timesheet.overtimeHours.toStringAsFixed(1),
                    icon: Icons.trending_up,
                    isHighlighted: true,
                  ),
                SummaryStatItem(
                  label: 'Break Hours',
                  value: timesheet.totalBreakHours.toStringAsFixed(1),
                  icon: Icons.coffee,
                ),
                SummaryStatItem(
                  label: 'Shifts',
                  value: timesheet.totalShifts.toString(),
                  icon: Icons.badge,
                ),
                if (timesheet.estimatedPayAmount > 0)
                  SummaryStatItem(
                    label: 'Est. Pay',
                    value: '\$${timesheet.estimatedPayAmount.toStringAsFixed(2)}',
                    icon: Icons.attach_money,
                    isPrimary: true,
                  ),
              ],
            ),

            // Entry status breakdown
            if (timesheet.entries.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  StatusChip(
                    label: '${timesheet.approvedEntriesCount} Approved',
                    color: Colors.green,
                  ),
                  const SizedBox(width: 8),
                  StatusChip(
                    label: '${timesheet.pendingEntriesCount} Pending',
                    color: Colors.orange,
                  ),
                  if (timesheet.rejectedEntriesCount > 0) ...[
                    const SizedBox(width: 8),
                    StatusChip(
                      label: '${timesheet.rejectedEntriesCount} Rejected',
                      color: Colors.red,
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Individual stat item within the summary card.
class SummaryStatItem extends StatelessWidget {
  const SummaryStatItem({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.isHighlighted = false,
    this.isPrimary = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool isHighlighted;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isHighlighted
        ? Colors.orange
        : isPrimary
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: theme.colorScheme.outline),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Colored chip displaying entry status counts.
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}
