import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/ui/components/components.dart';
import '../../../data/models/appointment.dart';
import '../../../data/models/client.dart';
import '../providers/sales_providers.dart';
import 'widgets/client_note_card.dart';
import 'widgets/quick_add_note_dialog.dart';

class SalesClientDetailPage extends ConsumerWidget {
  const SalesClientDetailPage({super.key, required this.clientId});

  final String clientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientAsync = ref.watch(clientByIdProvider(clientId));

    return Scaffold(
      appBar: AppBar(
        title: Text(clientAsync.valueOrNull?.fullName ?? 'Client'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.note_add_outlined),
        label: const Text('Add Note'),
        onPressed: () => _openQuickAddNote(context, clientId),
      ),
      body: clientAsync.when(
        data: (client) {
          if (client == null) {
            return const Center(child: Text('Client not found'));
          }
          return _ClientDetailBody(client: client);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            'Unable to load client',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ),
    );
  }

  Future<void> _openQuickAddNote(BuildContext context, String clientId) async {
    await showDialog<void>(
      context: context,
      builder: (_) => QuickAddNoteDialog(initialClientId: clientId),
    );
  }
}

class _ClientDetailBody extends ConsumerWidget {
  const _ClientDetailBody({required this.client});

  final Client client;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(clientNotesProvider(client.id));
    final upcomingAsync = ref.watch(clientUpcomingAppointmentsProvider(client.id));

    return SingleChildScrollView(
      padding: AppSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeaderCard(client: client),
          VSpace.md,
          _ContactCard(client: client),
          VSpace.lg,
          Text(
            'Notes',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          VSpace.sm,
          notesAsync.when(
            data: (notes) {
              if (notes.isEmpty) {
                return const Text('No notes yet.');
              }
              return Column(
                children: notes
                    .map(
                      (note) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ClientNoteCard(note: note),
                      ),
                    )
                    .toList(),
              );
            },
            loading: () => const LinearProgressIndicator(minHeight: 2),
            error: (error, _) => Text(
              'Unable to load notes',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          VSpace.lg,
          Text(
            'Upcoming',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          VSpace.sm,
          upcomingAsync.when(
            data: (appointments) {
              if (appointments.isEmpty) {
                return Text(
                  'No upcoming meetings scheduled.',
                  style: Theme.of(context).textTheme.bodySmall,
                );
              }
              final next = appointments.first;
              return _UpcomingTile(appointment: next);
            },
            loading: () => const LinearProgressIndicator(minHeight: 2),
            error: (error, _) => Text(
              'Cannot load upcoming meetings',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.client});

  final Client client;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            child: Text(client.initials),
          ),
          HSpace.md,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                client.fullName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                client.lifecycleDisplay,
                style: theme.textTheme.bodySmall?.copyWith(
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

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.client});

  final Client client;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Contact', style: theme.textTheme.titleSmall),
          VSpace.sm,
          if (client.phone != null && client.phone!.isNotEmpty)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.call_outlined),
              title: Text(client.phone!),
              onTap: () => _launchUri(Uri.parse('tel:${client.phone}')),
              trailing: Wrap(
                spacing: 8,
                children: [
                  IconButton(
                    icon: const Icon(Icons.message_outlined),
                    onPressed: () =>
                        _launchUri(Uri.parse('sms:${client.phone}')),
                  ),
                  IconButton(
                    icon: const Icon(Icons.call),
                    onPressed: () =>
                        _launchUri(Uri.parse('tel:${client.phone}')),
                  ),
                ],
              ),
            ),
          if (client.email != null && client.email!.isNotEmpty)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.mail_outline),
              title: Text(client.email!),
              onTap: () => _launchUri(Uri.parse('mailto:${client.email}')),
            ),
          if (client.address != null && client.address!.isNotEmpty)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.location_on_outlined),
              title: Text(client.address!),
            ),
        ],
      ),
    );
  }

  static Future<void> _launchUri(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

class _UpcomingTile extends StatelessWidget {
  const _UpcomingTile({required this.appointment});

  final Appointment appointment;

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('MMM d • h:mm a').format(appointment.startTime);
    return AppCard(
      child: Row(
        children: [
          const Icon(Icons.event_outlined),
          HSpace.md,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.serviceType ?? 'Meeting',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  dateLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
