import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/time_entry.dart';

/// Header displaying date and total hours for a single day's entries.
///
/// Groups time entries by day and shows aggregated hours worked.
class TimesheetDayHeader extends StatelessWidget {
  const TimesheetDayHeader({
    super.key,
    required this.date,
    required this.entries,
  });

  final DateTime date;
  final List<TimeEntry> entries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('EEEE, MMM d');
    final totalMinutes = entries.fold<int>(
      0,
      (sum, e) => sum + (e.workedMinutes ?? 0),
    );
    final hours = totalMinutes / 60.0;

    return Row(
      children: [
        Text(
          dateFormat.format(date),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${hours.toStringAsFixed(1)} hrs',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
