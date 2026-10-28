import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../core/offline/offline_banner.dart';
import '../../../core/ui/components/components.dart';
import '../../../data/models/client.dart';
import '../../../data/models/security_context.dart';
import 'widgets/client_detail_sheet.dart';

/// My Clients page for Provider Mode.
///
/// Shows clients the provider has appointments with.
/// Includes:
/// - Client list with search
/// - Client detail view
/// - Appointments history
/// - Intake form status
/// - Files summary
///
/// Audit logs PHI reads via ClientsRepository.
class MyClientsPage extends ConsumerStatefulWidget {
  const MyClientsPage({super.key});

  @override
  ConsumerState<MyClientsPage> createState() => _MyClientsPageState();
}

class _MyClientsPageState extends ConsumerState<MyClientsPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final securityContext = ref.watch(securityContextProvider).valueOrNull;

    if (securityContext == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Clients'),
        actions: const [
          OfflineIndicator(),
        ],
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          _SearchBar(
            controller: _searchController,
            onChanged: (value) {
              setState(() => _searchQuery = value);
            },
          ),
          const Divider(height: 1),
          Expanded(
            child: _ClientsList(
              securityContext: securityContext,
              searchQuery: _searchQuery,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.pagePadding,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: 'Search clients...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                )
              : null,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        ),
        onChanged: onChanged,
      ),
    );
  }
}

class _ClientsList extends ConsumerWidget {
  const _ClientsList({
    required this.securityContext,
    required this.searchQuery,
  });

  final SecurityContext securityContext;
  final String searchQuery;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientsRepo = ref.watch(clientsRepositoryProvider);
    final appointmentsRepo = ref.watch(appointmentsRepositoryProvider);

    return StreamBuilder(
      stream: appointmentsRepo.watchUpcoming(securityContext),
      builder: (context, appointmentsSnapshot) {
        if (appointmentsSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (appointmentsSnapshot.hasError) {
          return Center(
            child: Text('Error loading appointments: ${appointmentsSnapshot.error}'),
          );
        }

        // Get unique client IDs from provider's appointments
        final appointments = appointmentsSnapshot.data ?? [];
        final clientIds = appointments.map((a) => a.clientId).toSet().toList();

        if (clientIds.isEmpty) {
          return const _EmptyClients();
        }

        return StreamBuilder(
          stream: clientsRepo.watchClients(securityContext),
          builder: (context, clientsSnapshot) {
            if (clientsSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (clientsSnapshot.hasError) {
              return Center(
                child: Text('Error loading clients: ${clientsSnapshot.error}'),
              );
            }

            final allClients = clientsSnapshot.data ?? [];
            // Filter to only clients with appointments
            var clients = allClients.where((c) => clientIds.contains(c.id)).toList();

            // Apply search filter
            if (searchQuery.isNotEmpty) {
              final query = searchQuery.toLowerCase();
              clients = clients.where((client) {
                return client.fullName.toLowerCase().contains(query) ||
                    (client.email?.toLowerCase().contains(query) ?? false) ||
                    (client.phone?.contains(query) ?? false);
              }).toList();
            }

            // Sort by last name
            clients.sort((a, b) => a.lastName.compareTo(b.lastName));

            if (clients.isEmpty) {
              return _NoResults(searchQuery: searchQuery);
            }

            return ListView.separated(
              padding: AppSpacing.pagePadding,
              itemCount: clients.length,
              separatorBuilder: (context, index) => VSpace.sm,
              itemBuilder: (context, index) {
                final client = clients[index];
                return _ClientCard(
                  client: client,
                  securityContext: securityContext,
                );
              },
            );
          },
        );
      },
    );
  }
}

class _EmptyClients extends StatelessWidget {
  const _EmptyClients();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: theme.colorScheme.outline,
          ),
          VSpace.md,
          Text(
            'No clients yet',
            style: theme.textTheme.titleMedium,
          ),
          VSpace.xs,
          Text(
            'Your client list will appear here',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults({required this.searchQuery});

  final String searchQuery;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: theme.colorScheme.outline,
          ),
          VSpace.md,
          Text(
            'No results for "$searchQuery"',
            style: theme.textTheme.titleMedium,
          ),
          VSpace.xs,
          Text(
            'Try a different search term',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClientCard extends ConsumerWidget {
  const _ClientCard({
    required this.client,
    required this.securityContext,
  });

  final Client client;
  final SecurityContext securityContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return AppCard(
      onTap: () => _showClientDetail(context),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Text(
              client.initials,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          HSpace.md,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  client.fullName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                VSpace.xxs,
                if (client.email != null)
                  Text(
                    client.email!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                if (client.phone != null)
                  Text(
                    client.phone!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          Chip(
            label: Text(client.lifecycleDisplay),
            visualDensity: VisualDensity.compact,
          ),
          HSpace.xs,
          Icon(
            Icons.chevron_right,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  void _showClientDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => ClientDetailSheet(
        client: client,
        securityContext: securityContext,
      ),
    );
  }
}
