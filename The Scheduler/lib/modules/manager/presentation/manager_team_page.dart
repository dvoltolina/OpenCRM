import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/ui/components/components.dart';
import '../../../data/models/staff_member.dart';
import '../providers/manager_providers.dart';
import 'staff_detail_page.dart';
import 'widgets/status_widgets.dart';

final _teamFilterProvider = StateProvider<_TeamFilter>((ref) => _TeamFilter.all);

enum _TeamFilter { all, clockedIn, onBreak, pending, off }

class ManagerTeamPage extends ConsumerWidget {
  const ManagerTeamPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(selectedTeamDateProvider);
    final membersAsync = ref.watch(teamMembersProvider);
    final statuses = ref.watch(teamClockStatusProvider).valueOrNull ?? {};
    final scheduleAsync = ref.watch(teamScheduleProvider(date));
    final appointments = scheduleAsync.valueOrNull ?? const [];
    final filter = ref.watch(_teamFilterProvider);
    final dateLabel = DateFormat('EEE, MMM d').format(date);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Team'),
        actions: [
          TextButton(
            onPressed: () => _pickDate(context, ref, date),
            child: Text(dateLabel),
          ),
        ],
      ),
      body: membersAsync.when(
        data: (members) {
          final filtered = members.where((member) {
            final status = statuses[member.providerId ?? member.id] ?? ClockStatus.off;
            switch (filter) {
              case _TeamFilter.clockedIn:
                return status == ClockStatus.clockedIn;
              case _TeamFilter.onBreak:
                return status == ClockStatus.onBreak;
              case _TeamFilter.pending:
                return status == ClockStatus.pending;
              case _TeamFilter.off:
                return status == ClockStatus.off;
              case _TeamFilter.all:
                return true;
            }
          }).toList()
            ..sort((a, b) => a.displayName.compareTo(b.displayName));

          return Column(
            children: [
              Padding(
                padding: AppSpacing.pagePadding.copyWith(bottom: 8),
                child: _FilterRow(),
              ),
              Expanded(
                child: ListView.separated(
                  padding: AppSpacing.pagePadding.copyWith(top: 0),
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) => VSpace.sm,
                  itemBuilder: (context, index) {
                    final member = filtered[index];
                    final status =
                        statuses[member.providerId ?? member.id] ?? ClockStatus.off;
                    final apptCount = appointments
                        .where((appt) => appt.providerId == member.providerId)
                        .length;

                    return _StaffTile(
                      member: member,
                      status: status,
                      appointmentCount: apptCount,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StaffDetailPage(
                            staffId: member.id,
                            staffName: member.displayName,
                            providerId: member.providerId,
                            date: date,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text('Unable to load team'),
        ),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context, WidgetRef ref, DateTime initial) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );

    if (selected != null) {
      ref.read(selectedTeamDateProvider.notifier).state = selected;
    }
  }
}

class _FilterRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(_teamFilterProvider);
    return Wrap(
      spacing: 8,
      children: _TeamFilter.values.map((f) {
        final label = switch (f) {
          _TeamFilter.all => 'All',
          _TeamFilter.clockedIn => 'Clocked In',
          _TeamFilter.onBreak => 'On Break',
          _TeamFilter.pending => 'Pending',
          _TeamFilter.off => 'Off',
        };
        final selected = filter == f;
        return ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => ref.read(_teamFilterProvider.notifier).state = f,
        );
      }).toList(),
    );
  }
}

class _StaffTile extends StatelessWidget {
  const _StaffTile({
    required this.member,
    required this.status,
    required this.appointmentCount,
    this.onTap,
  });

  final StaffMember member;
  final ClockStatus status;
  final int appointmentCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final statusLabel = switch (status) {
      ClockStatus.clockedIn => 'In',
      ClockStatus.onBreak => 'On Break',
      ClockStatus.pending => 'Pending',
      ClockStatus.off => 'Off',
    };
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage:
              member.photoUrl != null ? NetworkImage(member.photoUrl!) : null,
          child: member.photoUrl == null
              ? Text(member.displayName.isNotEmpty
                  ? member.displayName[0].toUpperCase()
                  : '?')
              : null,
        ),
        title: Text(member.displayName),
        subtitle: Text(
          '${member.role.name} • $appointmentCount appointments today',
        ),
        trailing: ClockStatusIndicator(status: status, label: statusLabel),
        onTap: onTap,
      ),
    );
  }
}
