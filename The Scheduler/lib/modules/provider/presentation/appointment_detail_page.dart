import 'package:flutter/material.dart';

import 'job_completion_page.dart';
import 'provider_today_page.dart';
import 'widgets/location_history_section.dart';

class AppointmentDetailPage extends StatelessWidget {
  const AppointmentDetailPage({super.key, required this.appointment});

  final SampleAppointment appointment;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Details'),
        actions: [
          IconButton(
            tooltip: 'Call',
            icon: const Icon(Icons.phone),
            onPressed: () {},
          ),
          IconButton(
            tooltip: 'Text',
            icon: const Icon(Icons.sms_outlined),
            onPressed: () {},
          ),
          IconButton(
            tooltip: 'Navigate',
            icon: const Icon(Icons.navigation),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Section(
            title: 'Status',
            child: Row(
              children: [
                Chip(label: Text(appointment.status)),
                const SizedBox(width: 8),
                const Icon(Icons.offline_pin, size: 16),
                const SizedBox(width: 4),
                const Text('Synced'),
              ],
            ),
          ),
          _Section(
            title: 'Schedule',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_formatDate(appointment.start),
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  '${_formatTime(appointment.start)} - ${_formatTime(appointment.end)}',
                ),
                const SizedBox(height: 8),
                Text(appointment.service),
              ],
            ),
          ),
          _Section(
            title: 'Client & Location',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(appointment.clientName,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.place_outlined, size: 16),
                    const SizedBox(width: 4),
                    Expanded(child: Text(appointment.address)),
                    IconButton(
                      icon: const Icon(Icons.navigation),
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
          const LocationHistorySection(),
          _Section(
            title: 'Staff Notes',
            child: TextField(
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Add your notes for this visit',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            icon: const Icon(Icons.check_circle),
            label: const Text('Complete Job'),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => JobCompletionPage(appointment: appointment),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.month}/${date.day}/${date.year}';
  String _formatTime(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final meridiem = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $meridiem';
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}
