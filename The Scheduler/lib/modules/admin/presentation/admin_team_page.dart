import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/providers/providers.dart';
import '../../manager/providers/manager_providers.dart';
import '../providers/admin_providers.dart';
import '../utils/web_links.dart';
import 'widgets/quick_approval_card.dart';
import 'widgets/stats_widgets.dart';

/// Admin team page - team status overview and quick actions.
///
/// Shows current team status, pending approvals, and provides
/// quick actions for contacting staff. For full team management,
/// links to web dashboard.
///
/// HIPAA: Contains staff info - audit access.
class AdminTeamPage extends ConsumerWidget {
  const AdminTeamPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final securityContext = ref.watch(securityContextProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Team'),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            tooltip: 'Manage Team on Web',
            onPressed: () {
              if (securityContext != null) {
                AdminWebLinks.openTeamManagement(securityContext.businessId);
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(teamMembersProvider);
          ref.invalidate(teamClockStatusProvider);
          ref.invalidate(adminPendingTimesheetsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Team status overview
            _TeamStatusSection(),
            const SizedBox(height: 16),

            // Pending approvals
            _PendingApprovalsSection(),
            const SizedBox(height: 16),

            // Staff list
            _StaffListSection(),
            const SizedBox(height: 16),

            // Link to full management
            _ManagementLinkSection(),
          ],
        ),
      ),
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

class _PendingApprovalsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timesheetsAsync = ref.watch(adminPendingTimesheetsProvider);

    return timesheetsAsync.when(
      data: (timesheets) {
        if (timesheets.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'No pending approvals',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Pending Approvals (${timesheets.length})',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            ...timesheets.map((ts) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: QuickApprovalCard(timesheet: ts),
                )),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Error loading approvals: $error'),
        ),
      ),
    );
  }
}

class _StaffListSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamStatusAsync = ref.watch(adminTeamStatusProvider);

    return teamStatusAsync.when(
      data: (teamStatus) {
        if (teamStatus.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No team members found'),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Team Members (${teamStatus.length})',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            ...teamStatus.map((status) => _StaffCard(status)),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Error loading team: $error'),
        ),
      ),
    );
  }
}

class _StaffCard extends StatelessWidget {
  const _StaffCard(this.status);

  final TeamMemberStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final member = status.member;

    Color statusColor;
    String statusText;
    switch (status.clockStatus) {
      case ClockStatus.clockedIn:
        statusColor = Colors.green;
        statusText = 'Working';
        break;
      case ClockStatus.onBreak:
        statusColor = Colors.orange;
        statusText = 'On Break';
        break;
      case ClockStatus.pending:
        statusColor = Colors.blue;
        statusText = 'Pending';
        break;
      case ClockStatus.off:
        statusColor = Colors.grey;
        statusText = 'Off';
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _showStaffActions(context, member),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: member.photoUrl != null
                    ? ClipOval(
                        child: Image.network(
                          member.photoUrl!,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stack) =>
                              Icon(Icons.person, size: 28),
                        ),
                      )
                    : Icon(Icons.person, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.displayName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      member.role.name.toUpperCase(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor, width: 1),
                ),
                child: Text(
                  statusText,
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

  void _showStaffActions(BuildContext context, member) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.phone),
              title: const Text('Call'),
              onTap: () {
                Navigator.of(context).pop();
                // TODO: Get phone from member profile and call
                _launchPhone(member.email); // Placeholder
              },
            ),
            ListTile(
              leading: const Icon(Icons.message),
              title: const Text('Message'),
              onTap: () {
                Navigator.of(context).pop();
                // TODO: Navigate to messaging
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Messaging - coming soon')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('View Schedule'),
              onTap: () {
                Navigator.of(context).pop();
                // TODO: Navigate to staff schedule
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('View schedule - coming soon')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('View Timesheet'),
              onTap: () {
                Navigator.of(context).pop();
                // TODO: Navigate to staff timesheet
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('View timesheet - coming soon')),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.cancel, color: Colors.red),
              title: const Text('Cancel', style: TextStyle(color: Colors.red)),
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

class _ManagementLinkSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final securityContext = ref.watch(securityContextProvider).valueOrNull;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Full Team Management',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              'For full team management including adding/removing staff, '
              'managing permissions, and detailed settings, use the web dashboard.',
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                if (securityContext != null) {
                  AdminWebLinks.openTeamManagement(securityContext.businessId);
                }
              },
              icon: const Icon(Icons.language),
              label: const Text('Open Team Management'),
            ),
          ],
        ),
      ),
    );
  }
}
