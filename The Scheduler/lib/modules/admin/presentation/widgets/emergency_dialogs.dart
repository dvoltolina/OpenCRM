import 'package:flutter/material.dart';

/// Dialog for disabling online booking with reason and optional end date.
class DisableBookingDialog extends StatefulWidget {
  const DisableBookingDialog({super.key});

  @override
  State<DisableBookingDialog> createState() => _DisableBookingDialogState();
}

class _DisableBookingDialogState extends State<DisableBookingDialog> {
  final _reasonController = TextEditingController();
  DateTime? _until;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Disable Online Booking'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please provide a reason:'),
            const SizedBox(height: 12),
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason',
                hintText: 'e.g., System maintenance',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            const Text('Disable until (optional):'),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 1)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) {
                  setState(() => _until = picked);
                }
              },
              icon: const Icon(Icons.calendar_today),
              label: Text(_until == null
                  ? 'Select date'
                  : '${_until!.month}/${_until!.day}/${_until!.year}'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_reasonController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please provide a reason')),
              );
              return;
            }
            Navigator.of(context).pop({
              'reason': _reasonController.text.trim(),
              'until': _until,
            });
          },
          child: const Text('Disable'),
        ),
      ],
    );
  }
}

/// Dialog for collecting a reason for emergency actions.
class EmergencyReasonDialog extends StatefulWidget {
  const EmergencyReasonDialog({
    super.key,
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  State<EmergencyReasonDialog> createState() => _EmergencyReasonDialogState();
}

class _EmergencyReasonDialogState extends State<EmergencyReasonDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.description),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'Reason',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            autofocus: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_controller.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please provide a reason')),
              );
              return;
            }
            Navigator.of(context).pop(_controller.text.trim());
          },
          child: const Text('Continue'),
        ),
      ],
    );
  }
}

/// Dialog for sending an emergency announcement to all staff.
class EmergencyAnnouncementDialog extends StatefulWidget {
  const EmergencyAnnouncementDialog({super.key});

  @override
  State<EmergencyAnnouncementDialog> createState() =>
      _EmergencyAnnouncementDialogState();
}

class _EmergencyAnnouncementDialogState
    extends State<EmergencyAnnouncementDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Emergency Announcement'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
              'This will send a high-priority notification to all active staff members:'),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'Message',
              hintText: 'e.g., Urgent: All staff report to main office',
              border: OutlineInputBorder(),
            ),
            maxLines: 4,
            autofocus: true,
            maxLength: 250,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_controller.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter a message')),
              );
              return;
            }
            Navigator.of(context).pop(_controller.text.trim());
          },
          child: const Text('Send'),
        ),
      ],
    );
  }
}
