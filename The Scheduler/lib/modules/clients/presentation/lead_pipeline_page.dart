import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../core/ui/animations.dart';
import '../../../core/ui/components/components.dart';
import '../../../core/utils/secure_error_handler.dart';
import '../../../data/models/client.dart';
import '../../../data/models/security_context.dart';
import 'client_detail_page.dart';

/// Mobile lifecycle board over shared Scheduler client records.
///
/// This is not the full CRM pipeline. It reflects `Client.lifecycle` values
/// from Scheduler data and keeps the mobile label honest about that boundary.
class LeadPipelinePage extends ConsumerStatefulWidget {
  const LeadPipelinePage({super.key});

  @override
  ConsumerState<LeadPipelinePage> createState() => _LeadPipelinePageState();
}

class _LeadPipelinePageState extends ConsumerState<LeadPipelinePage> {
  @override
  Widget build(BuildContext context) {
    final securityContextAsync = ref.watch(securityContextProvider);
    final clientsRepository = ref.read(clientsRepositoryProvider);

    return securityContextAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) =>
          Center(child: Text(SecureErrorHandler.loadingFailed)),
      data: (securityContext) {
        if (securityContext == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return AppPageScaffold(
          title: 'Client Lifecycle',
          showBackButton: false,
          showAppBar: false,
          body: Column(
            children: [
              AppCard(
                child: Text(
                  'This board reflects shared Scheduler client lifecycle data. '
                  'Full lead and deal management stays in the CRM web app.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              VSpace.md,
              Expanded(
                child: StreamBuilder<List<Client>>(
                  stream: clientsRepository.watchClients(securityContext),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: ErrorFeedback(
                          message: SecureErrorHandler.loadingFailed,
                        ),
                      );
                    }

                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final clients = snapshot.data!;

                    final newClients = clients
                        .where((c) => c.lifecycle == ClientLifecycle.newClient)
                        .toList();
                    final activeClients = clients
                        .where((c) => c.lifecycle == ClientLifecycle.active)
                        .toList();
                    final inactiveClients = clients
                        .where((c) => c.lifecycle == ClientLifecycle.inactive)
                        .toList();
                    final churnedClients = clients
                        .where((c) => c.lifecycle == ClientLifecycle.churned)
                        .toList();

                    return AppKanbanBoard<Client>(
                      columns: [
                        AppKanbanColumn<Client>(
                          id: 'new',
                          title: 'New Clients',
                          items: newClients,
                          itemBuilder: _buildClientCard,
                          trailing: _buildColumnCount(newClients.length),
                        ),
                        AppKanbanColumn<Client>(
                          id: 'active',
                          title: 'Active Clients',
                          items: activeClients,
                          itemBuilder: _buildClientCard,
                          trailing: _buildColumnCount(activeClients.length),
                        ),
                        AppKanbanColumn<Client>(
                          id: 'inactive',
                          title: 'Inactive',
                          items: inactiveClients,
                          itemBuilder: _buildClientCard,
                          trailing: _buildColumnCount(inactiveClients.length),
                        ),
                        AppKanbanColumn<Client>(
                          id: 'churned',
                          title: 'Churned',
                          items: churnedClients,
                          itemBuilder: _buildClientCard,
                          trailing: _buildColumnCount(churnedClients.length),
                        ),
                      ],
                      onItemMoved:
                          (client, fromColumnId, toColumnId, toIndex) =>
                              _onClientMoved(
                                client,
                                fromColumnId,
                                toColumnId,
                                securityContext,
                              ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildColumnCount(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        '$count',
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildClientCard(
    BuildContext context,
    Client client,
    bool isDragging,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: isDragging ? null : () => _navigateToClientDetail(client),
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Client name and avatar
            Row(
              children: [
                CircleAvatar(
                  radius: AppIconSize.sm / 2,
                  backgroundColor: Color(
                    client.lifecycleColorValue,
                  ).withValues(alpha: 0.2),
                  child: Text(
                    client.initials,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Color(client.lifecycleColorValue),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                HSpace.xs,
                Expanded(
                  child: Text(
                    client.fullName,
                    style: theme.textTheme.titleSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            VSpace.xs,
            // Contact info
            if (client.hasEmail) ...[
              Row(
                children: [
                  Icon(
                    Icons.email_outlined,
                    size: AppIconSize.xs,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  HSpace.xxs,
                  Expanded(
                    child: Text(
                      client.email!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            if (client.hasPhone) ...[
              VSpace.xxs,
              Row(
                children: [
                  Icon(
                    Icons.phone_outlined,
                    size: AppIconSize.xs,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  HSpace.xxs,
                  Text(
                    client.phone!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
            // Tags
            if (client.tags.isNotEmpty) ...[
              VSpace.xs,
              Wrap(
                spacing: AppSpacing.xxs,
                runSpacing: AppSpacing.xxs,
                children: client.tags.take(2).map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: AppSpacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                    ),
                    child: Text(tag, style: theme.textTheme.labelSmall),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _navigateToClientDetail(Client client) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ClientDetailPage(clientId: client.id),
      ),
    );
  }

  Future<void> _onClientMoved(
    Client client,
    String fromColumnId,
    String toColumnId,
    SecurityContext securityContext,
  ) async {
    if (fromColumnId == toColumnId) return;

    // Map column ID to lifecycle
    final newLifecycle = _columnIdToLifecycle(toColumnId);
    if (newLifecycle == null) return;

    // Update client lifecycle
    final clientsRepository = ref.read(clientsRepositoryProvider);
    final updatedClient = client.copyWith(
      lifecycle: newLifecycle,
      updatedAt: DateTime.now(),
    );

    try {
      await clientsRepository.upsertClient(
        context: securityContext,
        client: updatedClient,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${client.fullName} moved to ${newLifecycle.name}'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(SecureErrorHandler.updateFailed),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  ClientLifecycle? _columnIdToLifecycle(String columnId) {
    switch (columnId) {
      case 'new':
        return ClientLifecycle.newClient;
      case 'active':
        return ClientLifecycle.active;
      case 'inactive':
        return ClientLifecycle.inactive;
      case 'churned':
        return ClientLifecycle.churned;
      default:
        return null;
    }
  }
}
