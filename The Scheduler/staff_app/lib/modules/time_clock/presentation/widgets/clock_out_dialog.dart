import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'elapsed_time_counter.dart';

/// Dialog shown before clocking out to confirm and add optional notes.
///
/// Returns the notes string if confirmed, or null if cancelled.
class ClockOutDialog extends StatefulWidget {
  const ClockOutDialog({
    super.key,
    required this.clockInTime,
    this.totalBreakMinutes = 0,
  });

  /// When the user clocked in.
  final DateTime clockInTime;

  /// Total break time taken in minutes.
  final int totalBreakMinutes;

  /// Shows the dialog and returns notes if confirmed, null if cancelled.
  static Future<String?> show(
    BuildContext context, {
    required DateTime clockInTime,
    int totalBreakMinutes = 0,
  }) async {
    return showDialog<String?>(
      context: context,
      builder: (context) => ClockOutDialog(
        clockInTime: clockInTime,
        totalBreakMinutes: totalBreakMinutes,
      ),
    );
  }

  @override
  State<ClockOutDialog> createState() => _ClockOutDialogState();
}

class _ClockOutDialogState extends State<ClockOutDialog> {
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeFormat = DateFormat.jm();
    final elapsed = DateTime.now().difference(widget.clockInTime);
    final workedMinutes = elapsed.inMinutes - widget.totalBreakMinutes;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.logout,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          const Text('Clock Out'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _SummaryRow(
                    label: 'Clocked In',
                    value: timeFormat.format(widget.clockInTime),
                    icon: Icons.login,
                  ),
                  const SizedBox(height: 8),
                  _SummaryRow(
                    label: 'Clock Out',
                    value: timeFormat.format(DateTime.now()),
                    icon: Icons.logout,
                  ),
                  const Divider(height: 24),
                  _SummaryRow(
                    label: 'Total Time',
                    valueWidget: CompactElapsedTime(
                      since: widget.clockInTime,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    icon: Icons.schedule,
                  ),
                  if (widget.totalBreakMinutes > 0) ...[
                    const SizedBox(height: 8),
                    _SummaryRow(
                      label: 'Break Time',
                      value: _formatMinutes(widget.totalBreakMinutes),
                      icon: Icons.coffee,
                    ),
                  ],
                  const SizedBox(height: 8),
                  _SummaryRow(
                    label: 'Worked',
                    value: _formatMinutes(workedMinutes),
                    icon: Icons.work,
                    highlight: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Notes section
            Text(
              'Notes (optional)',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                hintText: 'Add any notes about your shift...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              maxLength: 500,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: () {
            final notes = _notesController.text.trim();
            Navigator.of(context).pop(notes.isEmpty ? '' : notes);
          },
          icon: const Icon(Icons.logout),
          label: const Text('Clock Out'),
        ),
      ],
    );
  }

  String _formatMinutes(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes.abs() % 60;
    if (hours > 0) {
      return '${hours}h ${mins}m';
    }
    return '${mins}m';
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    this.value,
    this.valueWidget,
    required this.icon,
    this.highlight = false,
  });

  final String label;
  final String? value;
  final Widget? valueWidget;
  final IconData icon;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: highlight
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        if (valueWidget != null)
          valueWidget!
        else
          Text(
            value ?? '',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
              color: highlight ? theme.colorScheme.primary : null,
            ),
          ),
      ],
    );
  }
}
