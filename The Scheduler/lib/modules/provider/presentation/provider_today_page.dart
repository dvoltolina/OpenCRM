import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../time_clock/widgets/time_clock_widget.dart';
import '../../time_clock/providers/time_clock_providers.dart';
import '../../../core/providers/providers.dart';
import '../../../data/models/time_entry.dart';
import 'appointment_detail_page.dart';
import 'widgets/provider_appointment_card.dart';

class ProviderTodayPage extends ConsumerWidget {
  const ProviderTodayPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final securityContext = ref.watch(securityContextProvider).valueOrNull;
    final activeEntryAsync = securityContext == null
        ? const AsyncValue<TimeEntry?>.data(null)
        : ref.watch(activeTimeEntryProvider(securityContext));

    final appointments = _sampleAppointments;
    final now = DateTime.now();

    final upcoming = appointments
        .where((a) => a.end.isAfter(now))
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));

    final currentOrNext = upcoming.isNotEmpty ? upcoming.first : null;

    return RefreshIndicator(
      onRefresh: () async {},
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            floating: true,
            title: Text(
              'Today • ${_formatDate(now)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            actions: [
              IconButton(
                tooltip: 'Sync status',
                onPressed: () {},
                icon: const Icon(Icons.cloud_sync_outlined),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (activeEntryAsync.valueOrNull == null)
                    _ClockBanner(onClockIn: () {
                      if (securityContext != null) {
                        ref
                            .read(timeClockNotifierProvider.notifier)
                            .clockIn(context: securityContext);
                      }
                    }),
                  if (currentOrNext != null) ...[
                    const SizedBox(height: 12),
                    ProviderAppointmentCard(
                      appointment: currentOrNext,
                      highlighted: true,
                      onTap: () => _openDetail(context, currentOrNext),
                      onNavigate: () {},
                    ),
                  ],
                  const SizedBox(height: 12),
                  if (securityContext != null)
                    TimeClockWidget(securityContext: securityContext),
                  const SizedBox(height: 12),
                  if (appointments.isEmpty)
                    const _EmptyState()
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: appointments.length,
                      itemBuilder: (context, index) {
                        final appt = appointments[index];
                        final isPast = appt.end.isBefore(now);
                        return Opacity(
                          opacity: isPast ? 0.6 : 1,
                          child: ProviderAppointmentCard(
                            appointment: appt,
                            onTap: () => _openDetail(context, appt),
                            onNavigate: () {},
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openDetail(BuildContext context, SampleAppointment appt) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AppointmentDetailPage(appointment: appt),
      ),
    );
  }
}

class _ClockBanner extends StatelessWidget {
  const _ClockBanner({required this.onClockIn});
  final VoidCallback onClockIn;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: ListTile(
        leading: const Icon(Icons.warning_amber_rounded),
        title: const Text("You're not clocked in"),
        trailing: FilledButton(
          onPressed: onClockIn,
          child: const Text('Clock In'),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: const [
            Icon(Icons.event_busy, size: 48),
            SizedBox(height: 8),
            Text('No appointments today'),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$month/$day';
}

// ---------------------------------------------------------------------------
// Sample data (placeholder until wired to real repository)
// ---------------------------------------------------------------------------

class SampleAppointment {
  const SampleAppointment({
    required this.id,
    required this.service,
    required this.clientName,
    required this.address,
    required this.start,
    required this.end,
    this.status = 'confirmed',
  });

  final String id;
  final String service;
  final String clientName;
  final String address;
  final DateTime start;
  final DateTime end;
  final String status;
}

final _today = DateTime.now();
final _sampleAppointments = [
  SampleAppointment(
    id: 'a1',
    service: 'Home Cleaning',
    clientName: 'Jordan Lee',
    address: '123 Main St, Springfield',
    start: DateTime(_today.year, _today.month, _today.day, 9, 0),
    end: DateTime(_today.year, _today.month, _today.day, 10, 0),
    status: 'confirmed',
  ),
  SampleAppointment(
    id: 'a2',
    service: 'Window Wash',
    clientName: 'Avery Chen',
    address: '456 Pine Ave, Springfield',
    start: DateTime(_today.year, _today.month, _today.day, 11, 0),
    end: DateTime(_today.year, _today.month, _today.day, 12, 0),
    status: 'pending',
  ),
  SampleAppointment(
    id: 'a3',
    service: 'Deep Clean',
    clientName: 'Sam Patel',
    address: '789 Oak Rd, Springfield',
    start: DateTime(_today.year, _today.month, _today.day, 14, 0),
    end: DateTime(_today.year, _today.month, _today.day, 15, 30),
    status: 'confirmed',
  ),
];
