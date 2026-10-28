import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/payment.dart';
import '../../../../data/models/pos_transaction.dart';

/// Individual order card.
class OrderCard extends StatelessWidget {
  const OrderCard({
    required this.order,
    required this.timeFormat,
    required this.primaryColor,
    required this.onTap,
    super.key,
  });

  final PosTransaction order;
  final DateFormat timeFormat;
  final Color primaryColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final itemCount = order.lineItems.fold<int>(0, (sum, item) => sum + item.quantity);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Order icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.shopping_bag,
                    color: primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),

                // Order info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Order #${order.receiptNumber}',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildStatusChip(theme),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$itemCount item${itemCount == 1 ? '' : 's'} • ${timeFormat.format(order.createdAt)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                // Total
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${(order.totalCents / 100).toStringAsFixed(2)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(ThemeData theme) {
    Color chipColor;
    String label;

    if (order.isVoided) {
      chipColor = theme.colorScheme.error;
      label = 'Refunded';
    } else if (order.paymentStatus == PaymentStatus.completed) {
      chipColor = Colors.green;
      label = 'Completed';
    } else if (order.paymentStatus == PaymentStatus.pending) {
      chipColor = Colors.orange;
      label = 'Pending';
    } else {
      chipColor = theme.colorScheme.error;
      label = 'Failed';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: chipColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
