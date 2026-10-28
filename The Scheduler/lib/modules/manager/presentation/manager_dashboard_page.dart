import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/ui/components/components.dart';
import '../providers/manager_providers.dart';
import 'manager_approvals_page.dart';
import 'widgets/status_widgets.dart';

class ManagerDashboardPage extends ConsumerWidget {
  const ManagerDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clockCounts = ref.watch(clockStatusCountsProvider);
    final pendingCount = ref.watch(pendingApprovalsCountProvider);
    final today = DateTime.now();
    final scheduleAsync = ref.watch(teamScheduleProvider(today));

    final appointments = scheduleAsync.valueOrNull ?? const [];
    final totalAppointments = appointments.length;
    final totalMinutes = appointments.fold<int>(
      0,
      (sum, appt) => sum + appt.endTime.difference(appt.startTime).inMinutes,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Text(
                DateFormat('MMM d').format(today),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: AppSpacing.pagePadding,
        child: ListView(
          children: [
            Row(
              children: [
                Expanded(
                  child: TeamStatusCard(
                    label: 'Clocked In',
                    count: clockCounts.clockedIn,
                    color: Colors.green,
                    onTap: _goToTeamTab,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TeamStatusCard(
                    label: 'On Break',
                    count: clockCounts.onBreak,
                    color: Colors.orange,
                    onTap: _goToTeamTab,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TeamStatusCard(
                    label: 'Pending',
                    count: clockCounts.pending,
                    color: Colors.blueGrey,
                    onTap: _goToTeamTab,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            PendingApprovalCard(
              count: pendingCount,
              subtitle: pendingCount > 0
                  ? '$pendingCount timesheets pending'
                  : 'No pending approvals',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ManagerApprovalsPage()),
              ),
            ),
            const SizedBox(height: 16),
            _AlertsCard(),
            const SizedBox(height: 16),
            _QuickStats(
              totalAppointments: totalAppointments,
              totalMinutes: totalMinutes,
            ),
          ],
        ),
      ),
    );
  }

  void _goToTeamTab() {
    // No-op placeholder for now; navigation handled in shell tabs.
  }
}

class _AlertsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_outlined),
                const SizedBox(width: 8),
                Text(
                  'Today\'s Alerts',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Coverage gaps and late clock-ins will appear here.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickStats extends StatelessWidget {
  const _QuickStats({
    required this.totalAppointments,
    required this.totalMinutes,
  });

  final int totalAppointments;
  final int totalMinutes;

  @override
  Widget build(BuildContext context) {
    final hours = (totalMinutes / 60).toStringAsFixed(1);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quick Stats', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                _StatChip(
                  icon: Icons.event_available_outlined,
                  label: 'Appointments',
                  value: '$totalAppointments',
                ),
                const SizedBox(width: 12),
                _StatChip(
                  icon: Icons.schedule,
                  label: 'Hours scheduled',
                  value: hours,
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.titleMedium),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
