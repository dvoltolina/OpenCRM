import 'package:flutter/material.dart';

import '../provider_today_page.dart';

class ProviderAppointmentCard extends StatelessWidget {
  const ProviderAppointmentCard({
    super.key,
    required this.appointment,
    this.onTap,
    this.onNavigate,
    this.highlighted = false,
  });

  final SampleAppointment appointment;
  final VoidCallback? onTap;
  final VoidCallback? onNavigate;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeRange =
        '${_formatTime(appointment.start)} - ${_formatTime(appointment.end)}';

    return Card(
      color: highlighted
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.surface,
      child: ListTile(
        onTap: onTap,
        title: Text(timeRange, style: theme.textTheme.titleMedium),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(appointment.service, style: theme.textTheme.bodyLarge),
            Text('Client: ${appointment.clientName}'),
            Row(
              children: [
                const Icon(Icons.place_outlined, size: 16),
                const SizedBox(width: 4),
                Expanded(child: Text(appointment.address)),
                if (onNavigate != null)
                  IconButton(
                    icon: const Icon(Icons.directions),
                    onPressed: onNavigate,
                    tooltip: 'Navigate',
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [_StatusChip(status: appointment.status)],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final meridiem = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $meridiem';
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'pending':
        color = Colors.orange;
        break;
      case 'confirmed':
        color = Colors.green;
        break;
      case 'checkedIn':
        color = Colors.blue;
        break;
      case 'completed':
        color = Colors.grey;
        break;
      default:
        color = Colors.blueGrey;
    }

    return Chip(
      label: Text(status),
      backgroundColor: color.withValues(alpha: 0.15),
      labelStyle: TextStyle(color: color),
      visualDensity: VisualDensity.compact,
    );
  }
}
