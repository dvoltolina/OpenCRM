import 'package:flutter/material.dart';

import '../../../../data/models/timesheet_summary.dart';

/// Card widget displaying a staff member's timesheet summary.
///
/// Shows total hours, overtime, shifts, estimated pay, and status.
/// Tapping opens the detail view.
class TimesheetCard extends StatelessWidget {
  const TimesheetCard({
    super.key,
    required this.timesheet,
    this.onTap,
    this.onApprove,
  });

  final TimesheetSummary timesheet;
  final VoidCallback? onTap;
  final VoidCallback? onApprove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with name and status
              Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    backgroundImage: timesheet.staffAvatarUrl != null
                        ? NetworkImage(timesheet.staffAvatarUrl!)
                        : null,
                    child: timesheet.staffAvatarUrl == null
                        ? Text(
                            _getInitials(timesheet.staffName),
                            style: TextStyle(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),

                  // Name and email
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          timesheet.staffName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (timesheet.staffEmail != null)
                          Text(
                            timesheet.staffEmail!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Status badge
                  _StatusBadge(status: timesheet.status),
                ],
              ),
              const SizedBox(height: 16),

              // Stats row
              Row(
                children: [
                  // Total hours
                  _StatItem(
                    label: 'Hours',
                    value: timesheet.totalWorkedHours.toStringAsFixed(1),
                    icon: Icons.schedule,
                  ),

                  // Overtime
                  if (timesheet.hasOvertime) ...[
                    const SizedBox(width: 16),
                    _StatItem(
                      label: 'Overtime',
                      value: timesheet.overtimeHours.toStringAsFixed(1),
                      icon: Icons.trending_up,
                      isHighlighted: true,
                    ),
                  ],

                  // Shifts
                  const SizedBox(width: 16),
                  _StatItem(
                    label: 'Shifts',
                    value: timesheet.totalShifts.toString(),
                    icon: Icons.badge,
                  ),

                  const Spacer(),

                  // Estimated pay
                  if (timesheet.estimatedPayAmount > 0)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Est. Pay',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          '\$${timesheet.estimatedPayAmount.toStringAsFixed(2)}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                ],
              ),

              // Warning if has rejected entries
              if (timesheet.hasRejectedEntries) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.warning_amber,
                        size: 16,
                        color: theme.colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${timesheet.rejectedEntriesCount} rejected entries need attention',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Approve button for pending timesheets
              if (timesheet.isPendingApproval && onApprove != null) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FilledButton.icon(
                      onPressed: onApprove,
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Approve All'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final TimesheetStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color backgroundColor;
    Color textColor;
    String label;
    IconData icon;

    switch (status) {
      case TimesheetStatus.draft:
        backgroundColor = theme.colorScheme.surfaceContainerHighest;
        textColor = theme.colorScheme.onSurface;
        label = 'Draft';
        icon = Icons.edit;
      case TimesheetStatus.submitted:
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade900;
        label = 'Pending';
        icon = Icons.hourglass_empty;
      case TimesheetStatus.approved:
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade900;
        label = 'Approved';
        icon = Icons.check_circle;
      case TimesheetStatus.processed:
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade900;
        label = 'Processed';
        icon = Icons.paid;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    this.isHighlighted = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isHighlighted ? Colors.orange : theme.colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
