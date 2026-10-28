import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/time_entry.dart';

/// Dialog for rejecting a time entry with a reason.
///
/// Prompts the user to enter a reason for rejection before
/// rejecting the time entry. Returns the rejection reason or null.
class RejectEntryDialog extends StatefulWidget {
  const RejectEntryDialog({
    super.key,
    required this.entry,
  });

  final TimeEntry entry;

  @override
  State<RejectEntryDialog> createState() => _RejectEntryDialogState();
}

class _RejectEntryDialogState extends State<RejectEntryDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat.jm();
    final dateFormat = DateFormat.MMMd();

    return AlertDialog(
      title: const Text('Reject Entry'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${dateFormat.format(widget.entry.clockInTime)} · '
            '${timeFormat.format(widget.entry.clockInTime)} - '
            '${widget.entry.clockOutTime != null ? timeFormat.format(widget.entry.clockOutTime!) : 'Active'}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'Reason for rejection',
              hintText: 'Enter reason...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            autofocus: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_controller.text.trim().isNotEmpty) {
              Navigator.pop(context, _controller.text.trim());
            }
          },
          child: const Text('Reject'),
        ),
      ],
    );
  }
}
