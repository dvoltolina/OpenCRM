import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/config/external_portal_config.dart';
import '../../../core/providers/providers.dart';
import '../../../core/ui/components/components.dart';
import '../../../data/models/appointment.dart';
import '../../crm/utils/web_links.dart';
import '../providers/sales_providers.dart';
import 'sales_client_detail_page.dart';
import 'widgets/quick_add_note_dialog.dart';

class SalesTodayPage extends ConsumerWidget {
  const SalesTodayPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final securityContext = ref.watch(securityContextProvider).valueOrNull;
    final crmConfigured = ExternalPortalConfig.hasCrmPortal;
    final meetingsAsync = ref.watch(salesTodayMeetingsProvider);
    final callCountAsync = ref.watch(salesTodayCallCountProvider);
    final meetings = meetingsAsync.valueOrNull ?? const <Appointment>[];
    final callCount = callCountAsync.valueOrNull ?? 0;
    final todayLabel = DateFormat('MMM d').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Text('Today · $todayLabel'),
        actions: const [_SharedDataBadge()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.note_add_outlined),
        label: const Text('Add Note'),
        onPressed: () => _openQuickAddNote(context),
      ),
      body: Padding(
        padding: AppSpacing.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (securityContext?.providerId == null) const _ProviderLinkHint(),
            if (securityContext?.providerId == null) VSpace.md,
            _QuickStatsRow(
              meetingsCount: meetings.length,
              callsCount: callCount,
              loading: meetingsAsync.isLoading || callCountAsync.isLoading,
            ),
            VSpace.lg,
            Expanded(
              child: meetingsAsync.when(
                data: (items) {
                  if (items.isEmpty) {
                    return _EmptyMeetings(
                      crmConfigured: crmConfigured,
                      onOpenCrm: securityContext == null || !crmConfigured
                          ? null
                          : () => _openCrm(context, securityContext.businessId),
                    );
                  }
                  return ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, _) => VSpace.sm,
                    itemBuilder: (context, index) {
                      final appointment = items[index];
                      return _SalesMeetingTile(appointment: appointment);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Text(
                    'Unable to load today\'s meetings',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openQuickAddNote(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (_) => const QuickAddNoteDialog(),
    );
  }

  Future<void> _openCrm(BuildContext context, String businessId) async {
    final launched = await CrmWebLinks.openDashboard(businessId);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open CRM web app right now.')),
      );
    }
  }
}

class _ProviderLinkHint extends StatelessWidget {
  const _ProviderLinkHint();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          const Icon(Icons.info_outline),
          HSpace.md,
          Expanded(
            child: Text(
              'No provider link found for this sales user. Ask an admin to link your staff record so Today shows your meetings.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickStatsRow extends StatelessWidget {
  const _QuickStatsRow({
    required this.meetingsCount,
    required this.callsCount,
    required this.loading,
  });

  final int meetingsCount;
  final int callsCount;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _StatCard(
        label: 'Meetings',
        value: meetingsCount,
        icon: Icons.event_available_outlined,
      ),
      _StatCard(
        label: 'Calls logged',
        value: callsCount,
        icon: Icons.call_outlined,
      ),
    ];

    if (loading) {
      return Row(
        children: cards
            .map((card) => Expanded(child: Opacity(opacity: 0.65, child: card)))
            .toList(),
      );
    }

    return Row(children: cards.map((card) => Expanded(child: card)).toList());
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(16),
      margin: EdgeInsets.zero,
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Icon(icon, color: theme.colorScheme.primary),
          ),
          HSpace.md,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$value',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SalesMeetingTile extends ConsumerWidget {
  const _SalesMeetingTile({required this.appointment});

  final Appointment appointment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientAsync = ref.watch(clientByIdProvider(appointment.clientId));
    final timeLabel = DateFormat('h:mm a').format(appointment.startTime);
    final service = appointment.serviceType ?? 'Meeting';

    return AppCard(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                SalesClientDetailPage(clientId: appointment.clientId),
          ),
        );
      },
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: const Icon(Icons.event_note_outlined),
          ),
          HSpace.md,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  clientAsync.valueOrNull?.fullName ?? 'Client',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '$service • $timeLabel',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}

class _EmptyMeetings extends StatelessWidget {
  const _EmptyMeetings({required this.crmConfigured, required this.onOpenCrm});

  final bool crmConfigured;
  final VoidCallback? onOpenCrm;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.calendar_today_outlined, size: 48),
          VSpace.sm,
          Text(
            'No meetings today',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          VSpace.xs,
          Text(
            crmConfigured
                ? 'Assign or update meetings in the CRM web app.'
                : 'CRM web handoff is not configured for this build.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          VSpace.sm,
          FilledButton.icon(
            onPressed: onOpenCrm,
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open CRM Web App'),
          ),
        ],
      ),
    );
  }
}

class _SharedDataBadge extends StatelessWidget {
  const _SharedDataBadge();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 12, top: 12, bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(Icons.link, size: 16, color: theme.colorScheme.primary),
            HSpace.xs,
            Text(
              'Shared data',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
