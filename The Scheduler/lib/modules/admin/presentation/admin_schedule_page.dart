import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/models/appointment.dart';
import '../../manager/providers/manager_providers.dart';
import '../providers/admin_providers.dart';

/// Admin schedule page - view all providers' appointments.
///
/// Provides overview of all appointments with filters for date range
/// and specific providers. For detailed scheduling, links to web dashboard.
///
/// HIPAA: Contains PHI (appointments, client info) - audit access.
class AdminSchedulePage extends ConsumerWidget {
  const AdminSchedulePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context, ref),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: _DateSelector(),
        ),
      ),
      body: Column(
        children: [
          // View mode toggle
          _ViewModeToggle(),
          const Divider(height: 1),

          // Provider filter
          _ProviderFilter(),

          // Appointments list
          Expanded(child: _AppointmentsList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Add appointment
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add appointment - coming soon')),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showFilterDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Schedule'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('All Providers'),
              onTap: () {
                ref.read(adminSelectedProviderIdProvider.notifier).state = null;
                Navigator.of(context).pop();
              },
            ),
            // TODO: Add provider selection
          ],
        ),
      ),
    );
  }
}

class _DateSelector extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(adminSelectedDateProvider);
    final dateFormat = DateFormat.yMMMd();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              final viewMode = ref.read(adminScheduleViewModeProvider);
              final days = viewMode == ScheduleViewMode.today ? 1 : 7;
              ref.read(adminSelectedDateProvider.notifier).state =
                  selectedDate.subtract(Duration(days: days));
            },
          ),
          Expanded(
            child: Center(
              child: TextButton(
                onPressed: () => _selectDate(context, ref),
                child: Text(
                  dateFormat.format(selectedDate),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              final viewMode = ref.read(adminScheduleViewModeProvider);
              final days = viewMode == ScheduleViewMode.today ? 1 : 7;
              ref.read(adminSelectedDateProvider.notifier).state =
                  selectedDate.add(Duration(days: days));
            },
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, WidgetRef ref) async {
    final selectedDate = ref.read(adminSelectedDateProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      ref.read(adminSelectedDateProvider.notifier).state = picked;
    }
  }
}

class _ViewModeToggle extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewMode = ref.watch(adminScheduleViewModeProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: SegmentedButton<ScheduleViewMode>(
        segments: const [
          ButtonSegment(
            value: ScheduleViewMode.today,
            label: Text('Today'),
            icon: Icon(Icons.today),
          ),
          ButtonSegment(
            value: ScheduleViewMode.week,
            label: Text('Week'),
            icon: Icon(Icons.view_week),
          ),
        ],
        selected: {viewMode},
        onSelectionChanged: (Set<ScheduleViewMode> newSelection) {
          ref.read(adminScheduleViewModeProvider.notifier).state = newSelection.first;
        },
      ),
    );
  }
}

class _ProviderFilter extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedProviderId = ref.watch(adminSelectedProviderIdProvider);
    final staffAsync = ref.watch(teamMembersProvider);

    return staffAsync.when(
      data: (staff) {
        if (staff.isEmpty) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All Providers'),
                  selected: selectedProviderId == null,
                  onSelected: (selected) {
                    if (selected) {
                      ref.read(adminSelectedProviderIdProvider.notifier).state = null;
                    }
                  },
                ),
                const SizedBox(width: 8),
                ...staff.map((member) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(member.displayName),
                      selected: selectedProviderId == member.id,
                      onSelected: (selected) {
                        ref.read(adminSelectedProviderIdProvider.notifier).state =
                            selected ? member.id : null;
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) => const SizedBox.shrink(),
    );
  }
}

class _AppointmentsList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentsAsync = ref.watch(adminFilteredAppointmentsProvider);

    return appointmentsAsync.when(
      data: (appointments) {
        if (appointments.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.event_busy, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No appointments scheduled',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ],
            ),
          );
        }

        // Group by date for week view
        final viewMode = ref.watch(adminScheduleViewModeProvider);
        if (viewMode == ScheduleViewMode.week) {
          return _WeekView(appointments: appointments);
        }

        return _DayView(appointments: appointments);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $error'),
          ],
        ),
      ),
    );
  }
}

class _DayView extends StatelessWidget {
  const _DayView({required this.appointments});

  final List<Appointment> appointments;

  @override
  Widget build(BuildContext context) {
    // Sort by start time
    final sorted = [...appointments]..sort((a, b) => a.startTime.compareTo(b.startTime));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sorted.length,
      itemBuilder: (context, index) => _AppointmentCard(sorted[index]),
    );
  }
}

class _WeekView extends StatelessWidget {
  const _WeekView({required this.appointments});

  final List<Appointment> appointments;

  @override
  Widget build(BuildContext context) {
    // Group by date
    final grouped = <DateTime, List<Appointment>>{};
    for (final appt in appointments) {
      final date = DateTime(appt.date.year, appt.date.month, appt.date.day);
      grouped.putIfAbsent(date, () => []).add(appt);
    }

    final sortedDates = grouped.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final dateAppointments = grouped[date]!;
        dateAppointments.sort((a, b) => a.startTime.compareTo(b.startTime));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                DateFormat.yMMMd().format(date),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ...dateAppointments.map((appt) => _AppointmentCard(appt)),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard(this.appointment);

  final Appointment appointment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeFormat = DateFormat.jm();

    Color statusColor;
    switch (appointment.status) {
      case AppointmentStatus.confirmed:
        statusColor = Colors.green;
        break;
      case AppointmentStatus.pending:
        statusColor = Colors.orange;
        break;
      case AppointmentStatus.cancelled:
        statusColor = Colors.red;
        break;
      case AppointmentStatus.completed:
        statusColor = Colors.blue;
        break;
      case AppointmentStatus.noShow:
        statusColor = Colors.grey;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _showAppointmentDetails(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 60,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${timeFormat.format(appointment.startTime)} - ${timeFormat.format(appointment.endTime)}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      appointment.serviceType ?? 'Service',
                      style: theme.textTheme.bodyMedium,
                    ),
                    Text(
                      'Provider ID: ${appointment.providerId}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: statusColor, width: 1),
                ),
                child: Text(
                  appointment.status.name.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAppointmentDetails(BuildContext context) {
    // TODO: Navigate to appointment details page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Appointment details - coming soon')),
    );
  }
}
