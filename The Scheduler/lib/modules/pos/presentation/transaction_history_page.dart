import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/providers.dart';
import '../../../core/services/pos_service.dart';
import '../../../core/ui/components/components.dart';
import '../../../core/ui/ui_exports.dart';
import '../../../data/models/payment.dart';
import '../../../data/models/pos_transaction.dart';
import '../../../data/models/security_context.dart';
import 'widgets/transaction_detail_dialog.dart';

/// TransactionHistoryPage displays past POS transactions.
///
/// Features:
/// - Date range filtering
/// - Status filtering (completed, voided, pending)
/// - Search by receipt number
/// - Transaction detail view with void capability
class TransactionHistoryPage extends ConsumerStatefulWidget {
  const TransactionHistoryPage({super.key});

  @override
  ConsumerState<TransactionHistoryPage> createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends ConsumerState<TransactionHistoryPage> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  PaymentStatus? _statusFilter;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  PosService get _posService => ref.read(posServiceProvider);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Future<void> _showTransactionDetail(
    PosTransaction transaction,
    SecurityContext securityContext,
  ) async {
    await showDialog(
      context: context,
      builder: (context) => TransactionDetailDialog(
        transaction: transaction,
        securityContext: securityContext,
        posService: _posService,
        onVoided: () => setState(() {}),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final securityContextAsync = ref.watch(securityContextProvider);

    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Search and filter controls
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                      decoration: InputDecoration(
                        hintText: 'Search by receipt number...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.date_range),
                    tooltip: 'Select Date Range',
                    onPressed: _selectDateRange,
                  ),
                  PopupMenuButton<PaymentStatus?>(
                    icon: const Icon(Icons.filter_list),
                    tooltip: 'Filter by Status',
                    onSelected: (status) => setState(() => _statusFilter = status),
                    itemBuilder: (context) => [
                      CheckedPopupMenuItem(
                        checked: _statusFilter == null,
                        value: null,
                        child: const Text('All'),
                      ),
                      const PopupMenuDivider(),
                      CheckedPopupMenuItem(
                        checked: _statusFilter == PaymentStatus.completed,
                        value: PaymentStatus.completed,
                        child: const Text('Completed'),
                      ),
                      CheckedPopupMenuItem(
                        checked: _statusFilter == PaymentStatus.pending,
                        value: PaymentStatus.pending,
                        child: const Text('Pending'),
                      ),
                      CheckedPopupMenuItem(
                        checked: _statusFilter == PaymentStatus.refunded,
                        value: PaymentStatus.refunded,
                        child: const Text('Refunded'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: securityContextAsync.when(
                data: (securityContext) {
                  if (securityContext == null) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return _buildBody(securityContext, theme);
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: ErrorFeedback(message: 'Error: $error'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(SecurityContext securityContext, ThemeData theme) {
    return Column(
      children: [
        // Date range display
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 16,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              HSpace.xs,
              Text(
                '${DateFormat.MMMd().format(_startDate)} - ${DateFormat.MMMd().format(_endDate)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const Spacer(),
              if (_statusFilter != null)
                Chip(
                  label: Text(_statusFilter!.name.toUpperCase()),
                  onDeleted: () => setState(() => _statusFilter = null),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ),

        // Transactions list
        Expanded(
          child: StreamBuilder<List<PosTransaction>>(
            stream: _posService.watchTransactions(
              securityContext,
              startDate: _startDate,
              endDate: _endDate.add(const Duration(days: 1)),
              status: _statusFilter,
              limit: 100,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: ErrorFeedback(message: 'Error: ${snapshot.error}'),
                );
              }

              var transactions = snapshot.data ?? [];

              // Apply search filter
              if (_searchQuery.isNotEmpty) {
                transactions = transactions.where((t) {
                  return (t.receiptNumber?.toLowerCase().contains(_searchQuery) ?? false) ||
                      t.id.toLowerCase().contains(_searchQuery) ||
                      (t.clientName?.toLowerCase().contains(_searchQuery) ?? false);
                }).toList();
              }

              if (transactions.isEmpty) {
                return _buildEmptyState(theme);
              }

              return ListView.builder(
                padding: AppSpacing.cardPadding,
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final transaction = transactions[index];
                  return _TransactionListItem(
                    transaction: transaction,
                    onTap: () => _showTransactionDetail(
                      transaction,
                      securityContext,
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
          ),
          VSpace.md,
          Text(
            'No transactions found',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          VSpace.xs,
          Text(
            'Adjust filters or date range to see transactions',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}

/// Transaction list item widget.
class _TransactionListItem extends StatelessWidget {
  const _TransactionListItem({
    required this.transaction,
    required this.onTap,
  });

  final PosTransaction transaction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeFormat = DateFormat.jm();
    final dateFormat = DateFormat.MMMd();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Row(
            children: [
              // Receipt icon with status color
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getStatusColor(theme).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(
                  _getStatusIcon(),
                  color: _getStatusColor(theme),
                ),
              ),
              HSpace.md,

              // Transaction info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '#${transaction.receiptDisplay}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        HSpace.xs,
                        _StatusBadge(status: transaction.paymentStatus),
                        if (transaction.isVoided) ...[
                          HSpace.xxs,
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.error,
                              borderRadius: BorderRadius.circular(AppRadius.xs),
                            ),
                            child: Text(
                              'VOID',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onError,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    VSpace.xxs,
                    Row(
                      children: [
                        Text(
                          '${dateFormat.format(transaction.transactionDate)} at ${timeFormat.format(transaction.transactionDate)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        if (transaction.clientName != null) ...[
                          const Text(' • '),
                          Text(
                            transaction.clientName!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ],
                    ),
                    VSpace.xxs,
                    Row(
                      children: [
                        Icon(
                          _getPaymentMethodIcon(transaction.paymentMethod),
                          size: 14,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        HSpace.xxs,
                        Text(
                          transaction.paymentMethodDisplay,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        const Text(' • '),
                        Text(
                          '${transaction.totalItemCount} item${transaction.totalItemCount == 1 ? '' : 's'}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Total
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    transaction.totalDisplay,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: transaction.isVoided
                          ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
                          : theme.colorScheme.primary,
                      decoration: transaction.isVoided
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                ],
              ),

              HSpace.xs,
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(ThemeData theme) {
    if (transaction.isVoided) return theme.colorScheme.error;
    switch (transaction.paymentStatus) {
      case PaymentStatus.completed:
        return Colors.green;
      case PaymentStatus.pending:
        return Colors.orange;
      case PaymentStatus.failed:
        return theme.colorScheme.error;
      case PaymentStatus.refunded:
        return Colors.blue;
      default:
        return theme.colorScheme.onSurface;
    }
  }

  IconData _getStatusIcon() {
    if (transaction.isVoided) return Icons.cancel;
    switch (transaction.paymentStatus) {
      case PaymentStatus.completed:
        return Icons.check_circle;
      case PaymentStatus.pending:
        return Icons.schedule;
      case PaymentStatus.failed:
        return Icons.error;
      case PaymentStatus.refunded:
        return Icons.replay;
      default:
        return Icons.receipt;
    }
  }

  IconData _getPaymentMethodIcon(PosPaymentMethod method) {
    switch (method) {
      case PosPaymentMethod.card:
        return Icons.credit_card;
      case PosPaymentMethod.cash:
        return Icons.payments;
      case PosPaymentMethod.giftCard:
        return Icons.card_giftcard;
      case PosPaymentMethod.split:
        return Icons.call_split;
      case PosPaymentMethod.account:
        return Icons.account_balance_wallet;
    }
  }
}

/// Status badge widget.
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final PaymentStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (color, label) = _getStatusInfo(theme);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.xs),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  (Color, String) _getStatusInfo(ThemeData theme) {
    switch (status) {
      case PaymentStatus.completed:
        return (Colors.green, 'Paid');
      case PaymentStatus.pending:
        return (Colors.orange, 'Pending');
      case PaymentStatus.failed:
        return (theme.colorScheme.error, 'Failed');
      case PaymentStatus.refunded:
        return (Colors.blue, 'Refunded');
      case PaymentStatus.partiallyRefunded:
        return (Colors.blue, 'Partial Refund');
      default:
        return (theme.colorScheme.onSurface, 'Unknown');
    }
  }
}
