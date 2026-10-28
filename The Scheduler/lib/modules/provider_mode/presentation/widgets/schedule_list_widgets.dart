import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/appointment.dart';
import '../../../../data/models/security_context.dart';
import 'appointment_action_sheet.dart';
import 'schedule_view_toggle.dart';

/// Empty schedule display.
class EmptySchedule extends StatelessWidget {
  const EmptySchedule({super.key, required this.viewMode});

  final ScheduleView viewMode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_available,
            size: 64,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            viewMode == ScheduleView.day
                ? 'No appointments today'
                : 'No appointments this week',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Your schedule is clear',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Day schedule list view.
class DayScheduleList extends StatelessWidget {
  const DayScheduleList({
    super.key,
    required this.appointments,
    required this.securityContext,
  });

  final List<Appointment> appointments;
  final SecurityContext securityContext;

  @override
  Widget build(BuildContext context) {
    // Sort by start time
    final sortedAppointments = List<Appointment>.from(appointments)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: sortedAppointments.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final appointment = sortedAppointments[index];
        return AppointmentCard(
          appointment: appointment,
          securityContext: securityContext,
        );
      },
    );
  }
}

/// Week schedule list view.
class WeekScheduleList extends StatelessWidget {
  const WeekScheduleList({
    super.key,
    required this.appointments,
    required this.selectedDate,
    required this.securityContext,
  });

  final List<Appointment> appointments;
  final DateTime selectedDate;
  final SecurityContext securityContext;

  @override
  Widget build(BuildContext context) {
    // Group appointments by day
    final weekStart = _getWeekStart(selectedDate);
    final groupedAppointments = <DateTime, List<Appointment>>{};

    for (var i = 0; i < 7; i++) {
      final day = weekStart.add(Duration(days: i));
      final dayKey = DateTime(day.year, day.month, day.day);
      groupedAppointments[dayKey] = [];
    }

    for (final appointment in appointments) {
      final dayKey = DateTime(
        appointment.date.year,
        appointment.date.month,
        appointment.date.day,
      );
      groupedAppointments[dayKey]?.add(appointment);
    }

    // Sort appointments within each day
    groupedAppointments.forEach((key, value) {
      value.sort((a, b) => a.startTime.compareTo(b.startTime));
    });

    final sortedDays = groupedAppointments.keys.toList()..sort();

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: sortedDays.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final day = sortedDays[index];
        final dayAppointments = groupedAppointments[day]!;

        return DaySection(
          date: day,
          appointments: dayAppointments,
          securityContext: securityContext,
        );
      },
    );
  }

  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
  }
}

/// Day section for week view.
class DaySection extends StatelessWidget {
  const DaySection({
    super.key,
    required this.date,
    required this.appointments,
    required this.securityContext,
  });

  final DateTime date;
  final List<Appointment> appointments;
  final SecurityContext securityContext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('EEEE, MMM d');
    final isToday = _isToday(date);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              dateFormat.format(date),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: isToday ? theme.colorScheme.primary : null,
              ),
            ),
            if (isToday) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Today',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
            const Spacer(),
            Text(
              '${appointments.length} ${appointments.length == 1 ? 'appointment' : 'appointments'}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        if (appointments.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'No appointments',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
                fontStyle: FontStyle.italic,
              ),
            ),
          )
        else
          ...appointments.map((appointment) {
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: AppointmentCard(
                appointment: appointment,
                securityContext: securityContext,
                compact: true,
              ),
            );
          }),
      ],
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}

/// Appointment card widget.
class AppointmentCard extends ConsumerWidget {
  const AppointmentCard({
    super.key,
    required this.appointment,
    required this.securityContext,
    this.compact = false,
  });

  final Appointment appointment;
  final SecurityContext securityContext;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final timeFormat = DateFormat('h:mm a');

    return Card(
      child: InkWell(
        onTap: () => _showAppointmentActions(context, ref),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  StatusIndicator(status: appointment.status),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${timeFormat.format(appointment.startTime)} - ${timeFormat.format(appointment.endTime)}',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (appointment.serviceType != null)
                          Text(
                            appointment.serviceType!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (appointment.isRecurring)
                    Chip(
                      label: const Text('Recurring'),
                      avatar: const Icon(Icons.repeat, size: 16),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
              if (!compact) ...[
                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Client: ${appointment.clientId}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                if (appointment.notes != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.note_outlined,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          appointment.notes!,
                          style: theme.textTheme.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showAppointmentActions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AppointmentActionSheet(
        appointment: appointment,
        securityContext: securityContext,
      ),
    );
  }
}

/// Status indicator widget.
class StatusIndicator extends StatelessWidget {
  const StatusIndicator({super.key, required this.status});

  final AppointmentStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _getStatusColor(theme);
    final icon = _getStatusIcon();

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        color: color,
        size: 20,
      ),
    );
  }

  Color _getStatusColor(ThemeData theme) {
    switch (status) {
      case AppointmentStatus.pending:
        return Colors.orange;
      case AppointmentStatus.confirmed:
        return Colors.blue;
      case AppointmentStatus.completed:
        return Colors.green;
      case AppointmentStatus.cancelled:
        return Colors.red;
      case AppointmentStatus.noShow:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (status) {
      case AppointmentStatus.pending:
        return Icons.schedule;
      case AppointmentStatus.confirmed:
        return Icons.check_circle_outline;
      case AppointmentStatus.completed:
        return Icons.check_circle;
      case AppointmentStatus.cancelled:
        return Icons.cancel_outlined;
      case AppointmentStatus.noShow:
        return Icons.event_busy;
    }
  }
}
