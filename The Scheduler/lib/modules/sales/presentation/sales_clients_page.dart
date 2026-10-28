import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ui/components/components.dart';
import '../../../data/models/client.dart';
import '../providers/sales_providers.dart';
import 'sales_client_detail_page.dart';
import 'widgets/sales_client_card.dart';

class SalesClientsPage extends ConsumerStatefulWidget {
  const SalesClientsPage({super.key});

  @override
  ConsumerState<SalesClientsPage> createState() => _SalesClientsPageState();
}

class _SalesClientsPageState extends ConsumerState<SalesClientsPage> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(salesClientsSearchProvider),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recentAsync = ref.watch(recentClientsProvider);
    final clientsAsync = ref.watch(filteredSalesClientsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Clients')),
      body: Padding(
        padding: AppSpacing.pagePadding,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search by name, email, phone',
              ),
              onChanged: (value) =>
                  ref.read(salesClientsSearchProvider.notifier).state = value
                      .trim(),
            ),
            VSpace.lg,
            recentAsync.when(
              data: (clients) => clients.isEmpty
                  ? const SizedBox.shrink()
                  : _RecentClientsSection(clients: clients),
              loading: () => const LinearProgressIndicator(minHeight: 2),
              error: (error, stackTrace) => const SizedBox.shrink(),
            ),
            VSpace.md,
            Expanded(
              child: clientsAsync.when(
                data: (clients) {
                  if (clients.isEmpty) {
                    return const _EmptyClients();
                  }

                  final sorted = [...clients]
                    ..sort((a, b) => a.lastName.compareTo(b.lastName));

                  return ListView.separated(
                    itemCount: sorted.length,
                    separatorBuilder: (context, index) => VSpace.sm,
                    itemBuilder: (context, index) {
                      final client = sorted[index];
                      return SalesClientCard(
                        client: client,
                        onTap: () => _openDetail(context, client),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Text(
                    'Unable to load clients',
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

  void _openDetail(BuildContext context, Client client) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SalesClientDetailPage(clientId: client.id),
      ),
    );
  }
}

class _RecentClientsSection extends StatelessWidget {
  const _RecentClientsSection({required this.clients});

  final List<Client> clients;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent', style: Theme.of(context).textTheme.titleSmall),
        VSpace.sm,
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: clients.length,
            separatorBuilder: (context, index) => HSpace.sm,
            itemBuilder: (context, index) {
              final client = clients[index];
              return SizedBox(
                width: 260,
                child: SalesClientCard(
                  client: client,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          SalesClientDetailPage(clientId: client.id),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _EmptyClients extends StatelessWidget {
  const _EmptyClients();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_search_outlined, size: 48),
          VSpace.sm,
          Text(
            'No clients yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          VSpace.xs,
          Text(
            'Search shared client records or add notes after meetings.',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
