import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/pos_service.dart';
import '../../../../data/models/pos_transaction.dart';
import '../../../../data/models/security_context.dart';

/// Transaction detail dialog.
///
/// Shows complete transaction information including line items,
/// totals, payment details, and void capability.
class TransactionDetailDialog extends StatefulWidget {
  const TransactionDetailDialog({
    super.key,
    required this.transaction,
    required this.securityContext,
    required this.posService,
    required this.onVoided,
  });

  final PosTransaction transaction;
  final SecurityContext securityContext;
  final PosService posService;
  final VoidCallback onVoided;

  @override
  State<TransactionDetailDialog> createState() => _TransactionDetailDialogState();
}

class _TransactionDetailDialogState extends State<TransactionDetailDialog> {
  bool _isVoiding = false;

  Future<void> _voidTransaction() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => const VoidReasonDialog(),
    );

    if (reason == null) return;

    setState(() => _isVoiding = true);

    try {
      await widget.posService.voidTransaction(
        context: widget.securityContext,
        transactionId: widget.transaction.id,
        reason: reason,
      );

      if (!mounted) return;

      widget.onVoided();
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction voided successfully')),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _isVoiding = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error voiding transaction: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final transaction = widget.transaction;
    final dateFormat = DateFormat.yMMMd();
    final timeFormat = DateFormat.jm();

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.receipt),
          const SizedBox(width: 12),
          Expanded(child: Text('Receipt #${transaction.receiptDisplay}')),
          if (transaction.isVoided)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.error,
                borderRadius: BorderRadius.circular(4),
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
      ),
      content: SizedBox(
        width: 450,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Transaction info
              DetailRow(
                label: 'Date',
                value:
                    '${dateFormat.format(transaction.transactionDate)} at ${timeFormat.format(transaction.transactionDate)}',
              ),
              DetailRow(
                label: 'Payment Method',
                value: transaction.paymentMethodDisplay,
              ),
              DetailRow(
                label: 'Status',
                value: transaction.paymentStatusDisplay,
              ),
              if (transaction.clientName != null)
                DetailRow(label: 'Customer', value: transaction.clientName!),
              if (transaction.staffName != null)
                DetailRow(label: 'Staff', value: transaction.staffName!),

              const Divider(height: 24),

              // Line items
              Text(
                'Items',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...transaction.lineItems.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${item.quantity}x ${item.productName}',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                        Text(
                          '\$${item.totalDollars.toStringAsFixed(2)}',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  )),

              const Divider(height: 24),

              // Totals
              DetailRow(
                label: 'Subtotal',
                value: '\$${transaction.subtotalDollars.toStringAsFixed(2)}',
              ),
              if (transaction.hasDiscount)
                DetailRow(
                  label: 'Discount',
                  value: '-\$${transaction.discountDollars.toStringAsFixed(2)}',
                  valueColor: theme.colorScheme.error,
                ),
              DetailRow(
                label: 'Tax (${(transaction.taxRate * 100).toStringAsFixed(2)}%)',
                value: '\$${transaction.taxDollars.toStringAsFixed(2)}',
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    transaction.totalDisplay,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),

              // Cash payment details
              if (transaction.paymentMethod == PosPaymentMethod.cash &&
                  transaction.cashTenderedDollars != null) ...[
                const Divider(height: 24),
                DetailRow(
                  label: 'Cash Tendered',
                  value: '\$${transaction.cashTenderedDollars!.toStringAsFixed(2)}',
                ),
                if (transaction.changeDollars != null && transaction.changeDollars! > 0)
                  DetailRow(
                    label: 'Change',
                    value: '\$${transaction.changeDollars!.toStringAsFixed(2)}',
                  ),
              ],

              // Void info
              if (transaction.isVoided) ...[
                const Divider(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Voided',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (transaction.voidReason != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Reason: ${transaction.voidReason}',
                          style: TextStyle(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ],
                      if (transaction.voidedAt != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Voided on ${dateFormat.format(transaction.voidedAt!)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onErrorContainer
                                .withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        if (transaction.isCompleted && !transaction.isVoided)
          TextButton(
            onPressed: _isVoiding ? null : _voidTransaction,
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: _isVoiding
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Void Transaction'),
          ),
      ],
    );
  }
}

/// Detail row widget for displaying label-value pairs.
class DetailRow extends StatelessWidget {
  const DetailRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Void reason dialog for collecting void reason.
class VoidReasonDialog extends StatefulWidget {
  const VoidReasonDialog({super.key});

  @override
  State<VoidReasonDialog> createState() => _VoidReasonDialogState();
}

class _VoidReasonDialogState extends State<VoidReasonDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Void Transaction'),
      content: SizedBox(
        width: 350,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to void this transaction? This action cannot be undone.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Reason for voiding',
                hintText: 'e.g., Customer changed mind, Wrong item',
              ),
              maxLines: 2,
              autofocus: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final reason = _controller.text.trim();
            if (reason.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please provide a reason')),
              );
              return;
            }
            Navigator.pop(context, reason);
          },
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Void'),
        ),
      ],
    );
  }
}
