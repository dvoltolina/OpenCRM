import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/providers.dart';
import '../../../data/models/appointment.dart';
import '../../manager/providers/manager_providers.dart';
import '../providers/admin_providers.dart';
import '../utils/web_links.dart';
import 'widgets/quick_approval_card.dart';
import 'widgets/stats_widgets.dart';

/// Admin dashboard page - business health overview and pending actions.
///
/// This is the mobile admin's main view for quick business oversight.
/// For complex operations, links are provided to the web dashboard.
///
/// HIPAA: Contains PHI (appointments, staff names) - audit access.
class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final securityContext = ref.watch(securityContextProvider).valueOrNull;

    if (securityContext == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            tooltip: 'Open Web Dashboard',
            onPressed: () =>
                AdminWebLinks.openDashboard(securityContext.businessId),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) => _handleMenuAction(context, ref, value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'web_dashboard',
                child: ListTile(
                  leading: Icon(Icons.language),
                  title: Text('Open Web Dashboard'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'billing',
                child: ListTile(
                  leading: Icon(Icons.credit_card),
                  title: Text('Billing & Plan'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'support',
                child: ListTile(
                  leading: Icon(Icons.support_agent),
                  title: Text('Contact Support'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(businessStatsProvider);
          ref.invalidate(adminPendingTimesheetsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Business health cards
            _BusinessHealthSection(),
            const SizedBox(height: 16),

            // Pending actions
            _PendingActionsSection(),
            const SizedBox(height: 16),

            // Team status
            _TeamStatusSection(),
            const SizedBox(height: 16),

            // Today's snapshot
            _TodaySnapshotSection(),
            const SizedBox(height: 16),

            // Quick actions
            _QuickActionsSection(),
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(BuildContext context, WidgetRef ref, String action) {
    final businessId = ref
        .read(securityContextProvider)
        .valueOrNull
        ?.businessId;
    if (businessId == null) return;

    switch (action) {
      case 'web_dashboard':
        AdminWebLinks.openDashboard(businessId);
        break;
      case 'billing':
        AdminWebLinks.openBilling(businessId);
        break;
      case 'support':
        // TODO: Implement support contact
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Support contact coming soon')),
        );
        break;
    }
  }
}

class _BusinessHealthSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(businessStatsProvider);

    return statsAsync.when(
      data: (stats) => StatsRow(stats: stats),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Error loading stats: $error'),
        ),
      ),
    );
  }
}

class _PendingActionsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingCount = ref.watch(adminPendingActionsCountProvider);
    final timesheetsAsync = ref.watch(adminPendingTimesheetsProvider);

    return Column(
      children: [
        PendingActionsCard(
          count: pendingCount,
          description:
              '$pendingCount pending timesheet${pendingCount == 1 ? '' : 's'}',
          onTap: () {
            // Navigate to team tab (where approvals are shown)
            // This would be handled by the parent shell
          },
        ),
        const SizedBox(height: 12),
        // Show first pending timesheet for quick approval
        timesheetsAsync.when(
          data: (timesheets) {
            if (timesheets.isEmpty) return const SizedBox.shrink();
            return QuickApprovalCard(timesheet: timesheets.first);
          },
          loading: () => const SizedBox.shrink(),
          error: (error, stackTrace) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _TeamStatusSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counts = ref.watch(clockStatusCountsProvider);

    return TeamStatusBar(counts: counts);
  }
}

class _TodaySnapshotSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final range = DateRange(start: today, end: tomorrow);

    final appointmentsAsync = ref.watch(adminAllAppointmentsProvider(range));

    return SummaryCard(
      title: 'Today\'s Schedule',
      action: TextButton(
        onPressed: () {
          // Navigate to schedule tab
        },
        child: const Text('View All'),
      ),
      child: appointmentsAsync.when(
        data: (appointments) {
          if (appointments.isEmpty) {
            return const Text('No appointments scheduled for today');
          }

          // Show next 3 appointments
          final upcoming = appointments
              .where((a) => a.startTime.isAfter(now))
              .take(3)
              .toList();

          if (upcoming.isEmpty) {
            return const Text('No more appointments today');
          }

          return Column(
            children: upcoming.map((appt) => _AppointmentTile(appt)).toList(),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Text('Error: $error'),
      ),
    );
  }
}

class _AppointmentTile extends StatelessWidget {
  const _AppointmentTile(this.appointment);

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

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
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
                  timeFormat.format(appointment.startTime),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  appointment.serviceType ?? 'Service',
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
    );
  }
}

class _QuickActionsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final businessId = ref
        .watch(securityContextProvider)
        .valueOrNull
        ?.businessId;

    return SummaryCard(
      title: 'Quick Actions',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ActionChip(
            avatar: const Icon(Icons.language, size: 18),
            label: const Text('Web Dashboard'),
            onPressed: () {
              if (businessId != null) {
                AdminWebLinks.openDashboard(businessId);
              }
            },
          ),
          ActionChip(
            avatar: const Icon(Icons.people, size: 18),
            label: const Text('Manage Team'),
            onPressed: () {
              if (businessId != null) {
                AdminWebLinks.openTeamManagement(businessId);
              }
            },
          ),
          ActionChip(
            avatar: const Icon(Icons.credit_card, size: 18),
            label: const Text('Billing'),
            onPressed: () {
              if (businessId != null) {
                AdminWebLinks.openBilling(businessId);
              }
            },
          ),
          ActionChip(
            avatar: const Icon(Icons.settings, size: 18),
            label: const Text('Settings'),
            onPressed: () {
              if (businessId != null) {
                AdminWebLinks.openSettings(businessId);
              }
            },
          ),
        ],
      ),
    );
  }
}
