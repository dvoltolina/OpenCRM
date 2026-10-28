import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/pos_transaction.dart';
import 'order_item_tile.dart';

/// Order details bottom sheet.
class OrderDetailsSheet extends StatelessWidget {
  const OrderDetailsSheet({
    required this.order,
    required this.dateFormat,
    required this.timeFormat,
    required this.primaryColor,
    super.key,
  });

  final PosTransaction order;
  final DateFormat dateFormat;
  final DateFormat timeFormat;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.outline.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Icon(Icons.receipt_long, color: primaryColor),
                const SizedBox(width: 12),
                Text(
                  'Order #${order.receiptNumber}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              '${dateFormat.format(order.createdAt)} at ${timeFormat.format(order.createdAt)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),

          // Items list
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  'Items',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ...order.lineItems.map((item) => OrderItemTile(item: item)),
                const SizedBox(height: 24),

                // Summary
                _buildSummaryRow(
                  theme,
                  'Subtotal',
                  '\$${(order.subtotalCents / 100).toStringAsFixed(2)}',
                ),
                if (order.discountCents > 0) ...[
                  const SizedBox(height: 8),
                  _buildSummaryRow(
                    theme,
                    'Discount',
                    '-\$${(order.discountCents / 100).toStringAsFixed(2)}',
                    isDiscount: true,
                  ),
                ],
                if (order.taxCents > 0) ...[
                  const SizedBox(height: 8),
                  _buildSummaryRow(
                    theme,
                    'Tax',
                    '\$${(order.taxCents / 100).toStringAsFixed(2)}',
                  ),
                ],
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                _buildSummaryRow(
                  theme,
                  'Total',
                  '\$${(order.totalCents / 100).toStringAsFixed(2)}',
                  isBold: true,
                ),
                const SizedBox(height: 24),

                // Payment method
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getPaymentIcon(),
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Payment Method',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              _getPaymentMethodName(),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    ThemeData theme,
    String label,
    String value, {
    bool isBold = false,
    bool isDiscount = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isBold
              ? theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
              : theme.textTheme.bodyMedium,
        ),
        Text(
          value,
          style: isBold
              ? theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
              : theme.textTheme.bodyMedium?.copyWith(
                  color: isDiscount ? Colors.green : null,
                ),
        ),
      ],
    );
  }

  IconData _getPaymentIcon() {
    switch (order.paymentMethod) {
      case PosPaymentMethod.cash:
        return Icons.payments;
      case PosPaymentMethod.card:
        return Icons.credit_card;
      case PosPaymentMethod.giftCard:
        return Icons.card_giftcard;
      default:
        return Icons.payment;
    }
  }

  String _getPaymentMethodName() {
    switch (order.paymentMethod) {
      case PosPaymentMethod.cash:
        return 'Cash';
      case PosPaymentMethod.card:
        return 'Credit/Debit Card';
      case PosPaymentMethod.giftCard:
        return 'Gift Card';
      case PosPaymentMethod.split:
        return 'Split Payment';
      case PosPaymentMethod.account:
        return 'Account';
    }
  }
}
