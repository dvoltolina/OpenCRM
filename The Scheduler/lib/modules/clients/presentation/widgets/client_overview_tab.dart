import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/ui/components/components.dart';
import '../../../../data/models/client.dart';
import '../../../../data/models/security_context.dart';
import '../../../../data/repositories/clients_repository.dart';

/// Client overview tab showing contact info, notes, tags, and metadata
/// Updated by Agent U3 (2025-11-29) - Uses design tokens and AppCard
class ClientOverviewTab extends StatefulWidget {
  const ClientOverviewTab({
    super.key,
    required this.client,
    required this.securityContext,
    required this.clientsRepository,
  });

  final Client client;
  final SecurityContext securityContext;
  final ClientsRepository clientsRepository;

  @override
  State<ClientOverviewTab> createState() => _ClientOverviewTabState();
}

class _ClientOverviewTabState extends State<ClientOverviewTab> {
  late Client _client;

  @override
  void initState() {
    super.initState();
    _client = widget.client;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: AppSpacing.pagePadding,
      children: [
        _buildContactInfoCard(),
        VSpace.md,
        _buildNotesCard(),
        VSpace.md,
        _buildTagsCard(),
        VSpace.md,
        _buildMetadataCard(),
      ],
    );
  }

  Widget _buildContactInfoCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact Information',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const Divider(),
          _buildInfoRow(Icons.email, 'Email', _client.email ?? 'Not provided'),
          VSpace.sm,
          _buildInfoRow(Icons.phone, 'Phone', _client.phone ?? 'Not provided'),
          VSpace.sm,
          _buildInfoRow(
            Icons.location_on,
            'Address',
            _client.address ?? 'Not provided',
          ),
          if (_client.birthDate != null) ...[
            VSpace.sm,
            _buildInfoRow(
              Icons.cake,
              'Birthday',
              DateFormat.yMMMd().format(_client.birthDate!),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotesCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notes',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const Divider(),
          Text(
            _client.notes ?? 'No notes yet',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: _client.notes == null
                      ? Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5)
                      : null,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tags',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'Add tag',
                onPressed: _promptAddTag,
              ),
            ],
          ),
          const Divider(),
          if (_client.tags.isEmpty)
            Text(
              'No tags yet',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
            )
          else
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: _client.tags
                  .map(
                    (tag) => InputChip(
                      label: Text(tag),
                      onDeleted: () => _removeTag(tag),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildMetadataCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Client Information',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const Divider(),
          _buildInfoRow(
            Icons.person_add,
            'Added',
            DateFormat.yMMMd().format(_client.createdAt),
          ),
          if (_client.lastContactDate != null) ...[
            VSpace.sm,
            _buildInfoRow(
              Icons.chat,
              'Last Contact',
              DateFormat.yMMMd().format(_client.lastContactDate!),
            ),
          ],
          if (_client.lastAppointmentDate != null) ...[
            VSpace.sm,
            _buildInfoRow(
              Icons.calendar_today,
              'Last Appointment',
              DateFormat.yMMMd().format(_client.lastAppointmentDate!),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: AppIconSize.sm),
        HSpace.sm,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
              ),
              VSpace.xxs,
              Text(value),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _promptAddTag() async {
    final controller = TextEditingController();
    final newTag = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Tag'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'e.g., VIP'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newTag == null || newTag.isEmpty) return;

    final updated = _client.copyWith(
      tags: {..._client.tags, newTag}.toList(),
      updatedAt: DateTime.now(),
    );
    await widget.clientsRepository.upsertClient(
      context: widget.securityContext,
      client: updated,
    );
    setState(() => _client = updated);
  }

  Future<void> _removeTag(String tag) async {
    final updatedTags = List<String>.from(_client.tags)..remove(tag);
    final updated = _client.copyWith(
      tags: updatedTags,
      updatedAt: DateTime.now(),
    );
    await widget.clientsRepository.upsertClient(
      context: widget.securityContext,
      client: updated,
    );
    setState(() => _client = updated);
  }
}
