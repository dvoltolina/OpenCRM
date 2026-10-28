import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../data/local/staff_database.dart';
import 'elapsed_time_counter.dart';

/// Card widget displaying a single time entry.
///
/// Shows clock in/out times, worked duration, breaks, and sync status.
class TimeEntryCard extends StatelessWidget {
  const TimeEntryCard({
    super.key,
    required this.entry,
    this.onTap,
  });

  /// The time entry data to display.
  final TimeEntriesTableData entry;

  /// Callback when the card is tapped.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = entry.status == 'active' && entry.clockOutTime == null;
    final timeFormat = DateFormat.jm(); // e.g., "9:30 AM"

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
              // Header row with status and sync indicator
              Row(
                children: [
                  _buildStatusChip(context, isActive),
                  const Spacer(),
                  if (entry.pendingSync) _buildPendingSyncIndicator(context),
                ],
              ),
              const SizedBox(height: 12),

              // Time row
              Row(
                children: [
                  // Clock in time
                  _TimeColumn(
                    label: 'Clock In',
                    time: timeFormat.format(entry.clockInTime),
                    icon: Icons.login,
                  ),

                  // Arrow or duration indicator
                  Expanded(
                    child: Center(
                      child: isActive
                          ? Icon(
                              Icons.arrow_forward,
                              color: theme.colorScheme.primary,
                            )
                          : Icon(
                              Icons.arrow_forward,
                              color: theme.colorScheme.outline,
                            ),
                    ),
                  ),

                  // Clock out time or "Now"
                  _TimeColumn(
                    label: 'Clock Out',
                    time: entry.clockOutTime != null
                        ? timeFormat.format(entry.clockOutTime!)
                        : 'Now',
                    icon: Icons.logout,
                    isActive: isActive,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Duration and breaks row
              Row(
                children: [
                  // Worked duration
                  Expanded(
                    child: _DurationInfo(
                      label: 'Worked',
                      minutes: entry.workedMinutes,
                      isActive: isActive,
                      clockInTime: entry.clockInTime,
                    ),
                  ),

                  // Break duration
                  if (entry.breakMinutes != null && entry.breakMinutes! > 0)
                    Expanded(
                      child: _DurationInfo(
                        label: 'Breaks',
                        minutes: entry.breakMinutes,
                        isBreak: true,
                      ),
                    ),
                ],
              ),

              // Notes if present
              if (entry.staffNotes != null && entry.staffNotes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.notes,
                      size: 16,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.staffNotes!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
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

  Widget _buildStatusChip(BuildContext context, bool isActive) {
    final theme = Theme.of(context);

    Color chipColor;
    String label;
    IconData icon;

    if (isActive) {
      chipColor = theme.colorScheme.primaryContainer;
      label = 'Active';
      icon = Icons.timer;
    } else {
      switch (entry.status) {
        case 'pending':
          chipColor = theme.colorScheme.tertiaryContainer;
          label = 'Pending Approval';
          icon = Icons.hourglass_empty;
        case 'approved':
          chipColor = Colors.green.shade100;
          label = 'Approved';
          icon = Icons.check_circle;
        case 'rejected':
          chipColor = theme.colorScheme.errorContainer;
          label = 'Rejected';
          icon = Icons.cancel;
        default:
          chipColor = theme.colorScheme.surfaceContainerHighest;
          label = entry.status;
          icon = Icons.circle;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingSyncIndicator(BuildContext context) {
    final theme = Theme.of(context);

    return Tooltip(
      message: 'Pending sync',
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: theme.colorScheme.tertiaryContainer,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.cloud_upload,
          size: 16,
          color: theme.colorScheme.onTertiaryContainer,
        ),
      ),
    );
  }
}

class _TimeColumn extends StatelessWidget {
  const _TimeColumn({
    required this.label,
    required this.time,
    required this.icon,
    this.isActive = false,
  });

  final String label;
  final String time;
  final IconData icon;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: isActive
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          time,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: isActive ? theme.colorScheme.primary : null,
          ),
        ),
      ],
    );
  }
}

class _DurationInfo extends StatelessWidget {
  const _DurationInfo({
    required this.label,
    this.minutes,
    this.isActive = false,
    this.isBreak = false,
    this.clockInTime,
  });

  final String label;
  final int? minutes;
  final bool isActive;
  final bool isBreak;
  final DateTime? clockInTime;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        if (isActive && clockInTime != null)
          CompactElapsedTime(
            since: clockInTime!,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          )
        else
          Text(
            _formatMinutes(minutes ?? 0),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: isBreak ? theme.colorScheme.tertiary : null,
            ),
          ),
      ],
    );
  }

  String _formatMinutes(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0) {
      return '${hours}h ${mins}m';
    }
    return '${mins}m';
  }
}
