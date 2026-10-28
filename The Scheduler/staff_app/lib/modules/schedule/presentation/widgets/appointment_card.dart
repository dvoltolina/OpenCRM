import 'package:flutter/material.dart';

import '../../../../data/local/staff_database.dart';
import '../../providers/schedule_providers.dart';

/// Card widget displaying a single appointment.
///
/// Shows time, client name, service, address, and status.
/// Highlights current appointments and dims past ones.
class AppointmentCard extends StatelessWidget {
  const AppointmentCard({
    super.key,
    required this.appointment,
    this.onTap,
  });

  final AppointmentsTableData appointment;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final isPast = appointment.isPast;
    final isCurrent = appointment.isCurrent;
    final statusColor = _getStatusColor(colorScheme);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      clipBehavior: Clip.antiAlias,
      elevation: isCurrent ? 4 : 1,
      shadowColor: isCurrent ? statusColor.withValues(alpha: 0.4) : null,
      child: InkWell(
        onTap: onTap,
        child: Opacity(
          opacity: isPast && appointment.isCompleted ? 0.6 : 1.0,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Status indicator bar
                Container(
                  width: 4,
                  color: statusColor,
                ),
                // Time column
                Container(
                  width: 72,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  color: isCurrent
                      ? statusColor.withValues(alpha: 0.1)
                      : null,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        appointment.startTimeFormatted,
                        style: textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isCurrent ? statusColor : null,
                        ),
                      ),
                      Text(
                        appointment.endTimeFormatted,
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const VerticalDivider(width: 1),
                // Main content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Client name and status row
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                appointment.displayName,
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            _StatusBadge(
                              status: appointment.status,
                              isCheckedIn: appointment.isCheckedIn,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Service name
                        Text(
                          appointment.displayService,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // Address (if available)
                        if (appointment.clientAddress != null &&
                            appointment.clientAddress!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  appointment.clientAddress!,
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                        // Pending sync indicator
                        if (appointment.pendingSync) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.sync,
                                size: 14,
                                color: colorScheme.tertiary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Pending sync',
                                style: textTheme.labelSmall?.copyWith(
                                  color: colorScheme.tertiary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                // Chevron
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(
                    Icons.chevron_right,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(ColorScheme colorScheme) {
    if (appointment.isCompleted) return Colors.green;
    if (appointment.isCancelled) return Colors.red;
    if (appointment.isNoShow) return Colors.grey;
    if (appointment.isCheckedIn) return colorScheme.primary;
    if (appointment.isCurrent) return Colors.orange;
    if (appointment.status == 'confirmed') return colorScheme.primary;
    return Colors.orange; // pending
  }
}

/// Internal status badge widget.
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.status,
    required this.isCheckedIn,
  });

  final String status;
  final bool isCheckedIn;

  @override
  Widget build(BuildContext context) {
    final (label, color) = _getStatusInfo(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  (String, Color) _getStatusInfo(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (status == 'completed') {
      return ('Completed', Colors.green);
    }
    if (status == 'cancelled') {
      return ('Cancelled', Colors.red);
    }
    if (status == 'noShow' || status == 'no_show') {
      return ('No Show', Colors.grey);
    }
    if (isCheckedIn) {
      return ('Checked In', colorScheme.primary);
    }
    if (status == 'confirmed') {
      return ('Confirmed', colorScheme.primary);
    }
    return ('Pending', Colors.orange);
  }
}
