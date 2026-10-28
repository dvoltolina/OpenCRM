import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/models/time_entry.dart';
import '../../../data/models/timesheet_summary.dart';

class ManagerTimesheetDetailPage extends StatelessWidget {
  const ManagerTimesheetDetailPage(this.timesheet, {super.key});

  final TimesheetSummary timesheet;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    return Scaffold(
      appBar: AppBar(
        title: Text(timesheet.staffName),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '${dateFormat.format(timesheet.periodStart)} - ${dateFormat.format(timesheet.periodEnd)}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          _SummaryRow(label: 'Status', value: timesheet.status.name),
          _SummaryRow(
            label: 'Hours',
            value: timesheet.totalWorkedHours.toStringAsFixed(1),
          ),
          _SummaryRow(
            label: 'Overtime',
            value: timesheet.overtimeHours.toStringAsFixed(1),
          ),
          _SummaryRow(label: 'Shifts', value: timesheet.totalShifts.toString()),
          const SizedBox(height: 16),
          Text(
            'Entries',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...timesheet.entries.map(_EntryTile.new),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value),
        ],
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile(this.entry);

  final TimeEntry entry;

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('MMM d • h:mm a');
    final clockIn = timeFormat.format(entry.clockInTime);
    final clockOut = entry.clockOutTime != null
        ? timeFormat.format(entry.clockOutTime!)
        : 'In progress';
    return Card(
      child: ListTile(
        title: Text('$clockIn - $clockOut'),
        subtitle: Text(
          '${entry.status.name} • ${(entry.workedMinutes ?? 0) ~/ 60}h ${(entry.workedMinutes ?? 0) % 60}m',
        ),
      ),
    );
  }
}
