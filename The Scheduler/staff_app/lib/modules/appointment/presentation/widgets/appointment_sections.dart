import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../data/local/staff_database.dart';
import 'client_contact_actions.dart';

/// Badge showing appointment status with color coding.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.status,
    this.small = true,
  });

  final String status;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final (color, label) = _getStatusInfo(status);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 12,
        vertical: small ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: small ? 12 : 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  (Color, String) _getStatusInfo(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return (Colors.blue, 'Confirmed');
      case 'checked_in':
      case 'in_progress':
        return (Colors.green, 'In Progress');
      case 'completed':
        return (Colors.grey, 'Completed');
      case 'cancelled':
        return (Colors.red, 'Cancelled');
      case 'no_show':
        return (Colors.orange, 'No Show');
      default:
        return (Colors.grey, status);
    }
  }
}

class StatusCard extends StatelessWidget {
  const StatusCard({super.key, required this.appointment});

  final AppointmentsTableData appointment;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.event_available),
        title: Text('Status: ${appointment.status}'),
        subtitle: appointment.pendingSync ? const Text('Pending sync') : null,
        trailing: StatusBadge(status: appointment.status, small: false),
      ),
    );
  }
}

class TimeServiceCard extends StatelessWidget {
  const TimeServiceCard({super.key, required this.appointment});

  final AppointmentsTableData appointment;

  String get _displayService => appointment.serviceName ?? 'Service';

  String get _timeRange {
    final start = DateFormat.jm().format(appointment.startTime);
    final end = DateFormat.jm().format(appointment.endTime);
    return '$start - $end';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.schedule),
        title: Text(_displayService),
        subtitle: Text(_timeRange),
      ),
    );
  }
}

class ClientInfoCard extends StatelessWidget {
  const ClientInfoCard({
    super.key,
    required this.appointment,
    this.client,
  });

  final AppointmentsTableData appointment;
  final ClientsTableData? client;

  @override
  Widget build(BuildContext context) {
    final name = client?.name ?? appointment.clientName ?? 'Client';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (appointment.clientEmail != null)
              Text(appointment.clientEmail!,
                  style: Theme.of(context).textTheme.bodyMedium),
            if (appointment.clientPhone != null)
              Text(appointment.clientPhone!,
                  style: Theme.of(context).textTheme.bodyMedium),
            if (appointment.clientAddress != null)
              Text(appointment.clientAddress!,
                  style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            ClientContactActions(
              phone: appointment.clientPhone,
              address: appointment.clientAddress,
            ),
          ],
        ),
      ),
    );
  }
}

class NotesCard extends StatefulWidget {
  const NotesCard({
    super.key,
    required this.initialNotes,
    required this.onSave,
  });

  final String? initialNotes;
  final ValueChanged<String> onSave;

  @override
  State<NotesCard> createState() => _NotesCardState();
}

class _NotesCardState extends State<NotesCard> {
  late final TextEditingController _controller;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialNotes ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Staff Notes',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Add notes for this appointment',
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: _saving
                    ? null
                    : () {
                        setState(() => _saving = true);
                        widget.onSave(_controller.text);
                        if (mounted) setState(() => _saving = false);
                      },
                child: _saving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
