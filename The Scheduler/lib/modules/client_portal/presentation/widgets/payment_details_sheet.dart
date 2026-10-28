import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/payment.dart';

/// Bottom sheet displaying detailed payment information
class PaymentDetailsSheet extends StatelessWidget {
  const PaymentDetailsSheet({
    required this.payment,
    super.key,
  });

  final Payment payment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, y \'at\' h:mm a');

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Payment Details',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _buildDetailRow('Amount', '\$${payment.amountDollars.toStringAsFixed(2)}'),
          const Divider(height: 20),
          _buildDetailRow('Status', _getStatusText(payment.status)),
          const Divider(height: 20),
          _buildDetailRow('Payment Method', payment.paymentMethodDisplay),
          const Divider(height: 20),
          _buildDetailRow('Date', dateFormat.format(payment.createdAt)),
          if (payment.isRefunded) ...[
            const Divider(height: 20),
            _buildDetailRow(
              'Refund Amount',
              '\$${payment.refundAmountDollars.toStringAsFixed(2)}',
            ),
          ],
          if (payment.notes != null) ...[
            const Divider(height: 20),
            _buildDetailRow('Notes', payment.notes!),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            label: const Text('Close'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(color: Colors.grey),
          ),
        ),
      ],
    );
  }

  String _getStatusText(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.completed:
        return 'Completed';
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.refunded:
        return 'Refunded';
      case PaymentStatus.partiallyRefunded:
        return 'Partially Refunded';
      case PaymentStatus.none:
        return 'No Payment';
    }
  }
}
