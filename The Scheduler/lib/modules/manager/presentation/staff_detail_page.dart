import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/ui/components/components.dart';
import '../../../data/models/appointment.dart';
import '../../../data/models/staff_member.dart';
import '../../../data/models/time_entry.dart';
import '../../../data/models/timesheet_summary.dart';
import '../providers/manager_providers.dart';
import 'timesheet_detail_page.dart';
import 'widgets/status_widgets.dart';

class StaffDetailPage extends ConsumerWidget {
  const StaffDetailPage({
    super.key,
    required this.staffId,
    required this.staffName,
    this.providerId,
    required this.date,
  });

  final String staffId;
  final String staffName;
  final String? providerId;
  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(teamMembersProvider).valueOrNull ?? const [];
    final member = members.cast<StaffMember?>().firstWhere(
      (m) => m?.id == staffId,
      orElse: () => null,
    );
    final scheduleAsync = ref.watch(
      staffDailyScheduleProvider((date: date, staffId: providerId ?? staffId)),
    );
    final activeEntryAsync = ref.watch(staffActiveEntryProvider(staffId));
    final timesheetAsync = ref.watch(managerStaffTimesheetProvider(staffId));

    final status = activeEntryAsync.valueOrNull;
    final statusLabel = _statusLabel(status);

    return Scaffold(
      appBar: AppBar(title: Text(member?.displayName ?? staffName)),
      body: SingleChildScrollView(
        padding: AppSpacing.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: member?.photoUrl != null
                      ? NetworkImage(member!.photoUrl!)
                      : null,
                  child: member?.photoUrl == null
                      ? Text(
                          (member?.displayName ?? staffName)
                              .substring(0, 1)
                              .toUpperCase(),
                        )
                      : null,
                ),
                title: Text(member?.displayName ?? staffName),
                subtitle: Text(member?.role.name ?? 'Staff'),
                trailing: ClockStatusIndicator(
                  status: status?.isOnBreak == true
                      ? ClockStatus.onBreak
                      : status?.isActive == true
                      ? ClockStatus.clockedIn
                      : ClockStatus.off,
                  label: statusLabel,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Today\'s Schedule',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            scheduleAsync.when(
              data: (appointments) {
                if (appointments.isEmpty) {
                  return const Text('No appointments scheduled.');
                }
                return Column(
                  children: appointments
                      .map((appt) => _AppointmentTile(appointment: appt))
                      .toList(),
                );
              },
              loading: () => const LinearProgressIndicator(minHeight: 2),
              error: (error, _) => Text('Unable to load schedule'),
            ),
            const SizedBox(height: 16),
            Text('This Period', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            timesheetAsync.when(
              data: (timesheet) => _TimesheetSummaryCard(timesheet: timesheet),
              loading: () => const LinearProgressIndicator(minHeight: 2),
              error: (error, _) => Text('No timesheet data available'),
            ),
            const SizedBox(height: 16),
            if (timesheetAsync.valueOrNull != null)
              FilledButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ManagerTimesheetDetailPage(timesheetAsync.value!),
                    ),
                  );
                },
                child: const Text('View Timesheet'),
              ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(TimeEntry? entry) {
    if (entry == null) return 'Off';
    if (entry.isOnBreak) return 'On Break';
    if (entry.isActive) return 'Clocked In';
    if (entry.isPendingApproval) return 'Pending';
    return 'Off';
  }
}

class _AppointmentTile extends StatelessWidget {
  const _AppointmentTile({required this.appointment});

  final Appointment appointment;

  @override
  Widget build(BuildContext context) {
    final timeLabel =
        '${DateFormat('h:mm a').format(appointment.startTime)} - ${DateFormat('h:mm a').format(appointment.endTime)}';
    return Card(
      child: ListTile(
        leading: const Icon(Icons.event_note),
        title: Text(appointment.serviceType ?? 'Appointment'),
        subtitle: Text(timeLabel),
      ),
    );
  }
}

class _TimesheetSummaryCard extends StatelessWidget {
  const _TimesheetSummaryCard({required this.timesheet});

  final TimesheetSummary timesheet;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${dateFormat.format(timesheet.periodStart)} - ${dateFormat.format(timesheet.periodEnd)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _Line(
              label: 'Hours',
              value: timesheet.totalWorkedHours.toStringAsFixed(1),
            ),
            _Line(
              label: 'Overtime',
              value: timesheet.overtimeHours.toStringAsFixed(1),
            ),
            _Line(label: 'Shifts', value: timesheet.totalShifts.toString()),
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value});

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
