import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/time_entry.dart';

/// Card displaying a single time entry with approval/rejection actions.
///
/// Shows clock in/out times, duration, breaks, notes, and action buttons
/// for pending entries. Displays rejection reason for rejected entries.
class TimeEntryCard extends StatelessWidget {
  const TimeEntryCard({
    super.key,
    required this.entry,
    this.onApprove,
    this.onReject,
  });

  final TimeEntry entry;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeFormat = DateFormat.jm();

    final clockIn = timeFormat.format(entry.clockInTime);
    final clockOut = entry.clockOutTime != null
        ? timeFormat.format(entry.clockOutTime!)
        : 'Active';
    final duration = entry.durationHours.toStringAsFixed(1);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time row
            Row(
              children: [
                EntryStatusBadge(status: entry.status),
                const SizedBox(width: 12),
                Icon(Icons.login, size: 16, color: theme.colorScheme.outline),
                const SizedBox(width: 4),
                Text(clockIn, style: theme.textTheme.bodyMedium),
                const SizedBox(width: 16),
                Icon(Icons.logout, size: 16, color: theme.colorScheme.outline),
                const SizedBox(width: 4),
                Text(
                  clockOut,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontStyle: entry.clockOutTime == null
                        ? FontStyle.italic
                        : FontStyle.normal,
                  ),
                ),
                const Spacer(),
                Text(
                  '$duration hrs',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            // Break info
            if (entry.breakMinutes != null && entry.breakMinutes! > 0) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.coffee, size: 14, color: theme.colorScheme.outline),
                  const SizedBox(width: 4),
                  Text(
                    '${entry.breakMinutes} min break',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ],

            // Notes
            if (entry.staffNotes != null && entry.staffNotes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.note,
                      size: 14,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.staffNotes!,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Rejection reason
            if (entry.status == TimeEntryStatus.rejected &&
                entry.rejectionReason != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.warning_amber,
                      size: 14,
                      color: Colors.red.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.rejectionReason!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Action buttons
            if (onApprove != null || onReject != null) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onReject != null)
                    TextButton(
                      onPressed: onReject,
                      child: const Text('Reject'),
                    ),
                  if (onApprove != null) ...[
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: onApprove,
                      child: const Text('Approve'),
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

/// Badge showing the current status of a time entry.
class EntryStatusBadge extends StatelessWidget {
  const EntryStatusBadge({
    super.key,
    required this.status,
  });

  final TimeEntryStatus status;

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case TimeEntryStatus.active:
        color = Colors.blue;
        label = 'Active';
        icon = Icons.timer;
      case TimeEntryStatus.pending:
        color = Colors.orange;
        label = 'Pending';
        icon = Icons.hourglass_empty;
      case TimeEntryStatus.approved:
        color = Colors.green;
        label = 'Approved';
        icon = Icons.check_circle;
      case TimeEntryStatus.rejected:
        color = Colors.red;
        label = 'Rejected';
        icon = Icons.cancel;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
