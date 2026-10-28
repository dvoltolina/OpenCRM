import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/config/app_config.dart';
import '../../../core/providers/providers.dart';
import '../../../core/ui/components/components.dart';
import '../../../data/models/pos_transaction.dart';
import '../../../data/models/security_context.dart';
import 'widgets/order_date_group.dart';
import 'widgets/order_details_sheet.dart';

/// Client-facing order history page.
///
/// Shows the client's past product purchases from the shop.
class ClientOrderHistoryPage extends ConsumerStatefulWidget {
  const ClientOrderHistoryPage({
    required this.securityContext,
    required this.config,
    super.key,
  });

  final SecurityContext securityContext;
  final AppConfig config;

  @override
  ConsumerState<ClientOrderHistoryPage> createState() => _ClientOrderHistoryPageState();
}

class _ClientOrderHistoryPageState extends ConsumerState<ClientOrderHistoryPage> {
  final _dateFormat = DateFormat('MMM d, yyyy');
  final _timeFormat = DateFormat('h:mm a');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final branding = widget.config.branding;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    branding.primaryColor,
                    branding.primaryColor.withValues(alpha: 0.8),
                  ],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order History',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your past purchases',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Orders list
          _buildOrdersList(theme),
        ],
      ),
    );
  }

  Widget _buildOrdersList(ThemeData theme) {
    final branding = widget.config.branding;
    final posService = ref.watch(posServiceProvider);

    return FutureBuilder<List<PosTransaction>>(
      future: posService.getTransactionsForClient(
        widget.securityContext,
        widget.securityContext.userId,
        limit: 50,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: theme.colorScheme.error,
                  ),
                  VSpace.md,
                  Text(
                    'Failed to load orders',
                    style: theme.textTheme.titleMedium,
                  ),
                  VSpace.xs,
                  TextButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final orders = snapshot.data ?? [];

        if (orders.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 64,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                    VSpace.md,
                    Text(
                      'No orders yet',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    VSpace.xs,
                    Text(
                      'Your purchase history will appear here',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Group orders by date
        final groupedOrders = _groupOrdersByDate(orders);

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final entry = groupedOrders.entries.elementAt(index);
              return OrderDateGroup(
                date: entry.key,
                orders: entry.value,
                dateFormat: _dateFormat,
                timeFormat: _timeFormat,
                primaryColor: branding.primaryColor,
                onOrderTap: (order) => _showOrderDetails(order),
              );
            },
            childCount: groupedOrders.length,
          ),
        );
      },
    );
  }

  Map<DateTime, List<PosTransaction>> _groupOrdersByDate(List<PosTransaction> orders) {
    final grouped = <DateTime, List<PosTransaction>>{};

    for (final order in orders) {
      final date = DateTime(
        order.createdAt.year,
        order.createdAt.month,
        order.createdAt.day,
      );
      grouped.putIfAbsent(date, () => []).add(order);
    }

    // Sort by date descending
    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    return {for (final key in sortedKeys) key: grouped[key]!};
  }

  void _showOrderDetails(PosTransaction order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => OrderDetailsSheet(
        order: order,
        dateFormat: _dateFormat,
        timeFormat: _timeFormat,
        primaryColor: widget.config.branding.primaryColor,
      ),
    );
  }
}
