import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/pos_transaction.dart';
import 'order_card.dart';

/// Group of orders for a specific date.
class OrderDateGroup extends StatelessWidget {
  const OrderDateGroup({
    required this.date,
    required this.orders,
    required this.dateFormat,
    required this.timeFormat,
    required this.primaryColor,
    required this.onOrderTap,
    super.key,
  });

  final DateTime date;
  final List<PosTransaction> orders;
  final DateFormat dateFormat;
  final DateFormat timeFormat;
  final Color primaryColor;
  final void Function(PosTransaction) onOrderTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isToday = _isToday(date);
    final isYesterday = _isYesterday(date);

    String dateLabel;
    if (isToday) {
      dateLabel = 'Today';
    } else if (isYesterday) {
      dateLabel = 'Yesterday';
    } else {
      dateLabel = dateFormat.format(date);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
          child: Text(
            dateLabel,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ...orders.map((order) => OrderCard(
              order: order,
              timeFormat: timeFormat,
              primaryColor: primaryColor,
              onTap: () => onOrderTap(order),
            )),
      ],
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  bool _isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }
}
