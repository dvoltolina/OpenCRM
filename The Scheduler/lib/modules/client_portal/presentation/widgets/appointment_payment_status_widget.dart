import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/appointment.dart';
import '../../../../data/models/payment.dart';

/// Widget to display payment status and refund information for an appointment.
class AppointmentPaymentStatusWidget extends StatelessWidget {
  const AppointmentPaymentStatusWidget({
    super.key,
    required this.appointment,
    this.payment,
    this.onViewReceipt,
  });

  final Appointment appointment;
  final Payment? payment;
  final VoidCallback? onViewReceipt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    if (!appointment.requiresPayment) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.payment,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Payment Details',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Payment status
            _buildDetailRow(
              context,
              'Status',
              _getPaymentStatusChip(context, appointment.paymentStatus),
            ),

            // Amount
            if (appointment.paymentAmountCents != null)
              _buildDetailRow(
                context,
                'Amount',
                Text(
                  currencyFormat.format(appointment.paymentAmountCents! / 100),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

            // Payment method
            if (payment != null && payment!.paymentMethodDisplay.isNotEmpty)
              _buildDetailRow(
                context,
                'Method',
                Text(
                  payment!.paymentMethodDisplay,
                  style: theme.textTheme.bodyMedium,
                ),
              ),

            // Refund information
            if (appointment.refundStatus != null &&
                appointment.refundStatus != PaymentStatus.none) ...[
              const Divider(height: 24),
              Row(
                children: [
                  Icon(
                    Icons.refresh,
                    color: theme.colorScheme.secondary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Refund Information',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                context,
                'Refund Status',
                _getPaymentStatusChip(context, appointment.refundStatus!),
              ),
              if (appointment.refundAmountCents != null)
                _buildDetailRow(
                  context,
                  'Refund Amount',
                  Text(
                    currencyFormat
                        .format(appointment.refundAmountCents! / 100),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ),
              if (appointment.refundProcessedAt != null)
                _buildDetailRow(
                  context,
                  'Processed',
                  Text(
                    DateFormat.yMMMd()
                        .add_jm()
                        .format(appointment.refundProcessedAt!),
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
            ],

            // Reschedule fee
            if (appointment.rescheduleFeeRequired &&
                appointment.rescheduleFeeCents != null) ...[
              const Divider(height: 24),
              _buildDetailRow(
                context,
                'Reschedule Fee',
                Row(
                  children: [
                    Text(
                      currencyFormat
                          .format(appointment.rescheduleFeeCents! / 100),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _getPaymentStatusChip(
                        context, appointment.rescheduleFeeStatus),
                  ],
                ),
              ),
            ],

            // Cancellation fee
            if (appointment.cancellationFeeRequired &&
                appointment.cancellationFeeCents != null) ...[
              const Divider(height: 24),
              _buildDetailRow(
                context,
                'Cancellation Fee',
                Row(
                  children: [
                    Text(
                      currencyFormat
                          .format(appointment.cancellationFeeCents! / 100),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _getPaymentStatusChip(
                        context, appointment.cancellationFeeStatus),
                  ],
                ),
              ),
            ],

            // Receipt button
            if (payment != null &&
                payment!.status == PaymentStatus.completed &&
                onViewReceipt != null) ...[
              const SizedBox(height: 16),
              Center(
                child: OutlinedButton.icon(
                  onPressed: onViewReceipt,
                  icon: const Icon(Icons.receipt_long),
                  label: const Text('View Receipt'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, Widget value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 16),
          Flexible(child: value),
        ],
      ),
    );
  }

  Widget _getPaymentStatusChip(BuildContext context, PaymentStatus status) {
    final theme = Theme.of(context);

    Color backgroundColor;
    Color textColor;
    IconData icon;
    String label;

    switch (status) {
      case PaymentStatus.none:
        backgroundColor = theme.colorScheme.surfaceContainerHighest;
        textColor = theme.colorScheme.onSurfaceVariant;
        icon = Icons.remove_circle_outline;
        label = 'No Payment';
        break;
      case PaymentStatus.pending:
        backgroundColor = theme.colorScheme.tertiaryContainer;
        textColor = theme.colorScheme.onTertiaryContainer;
        icon = Icons.schedule;
        label = 'Pending';
        break;
      case PaymentStatus.completed:
        backgroundColor = theme.colorScheme.primaryContainer;
        textColor = theme.colorScheme.onPrimaryContainer;
        icon = Icons.check_circle;
        label = 'Paid';
        break;
      case PaymentStatus.failed:
        backgroundColor = theme.colorScheme.errorContainer;
        textColor = theme.colorScheme.onErrorContainer;
        icon = Icons.error;
        label = 'Failed';
        break;
      case PaymentStatus.refunded:
        backgroundColor = theme.colorScheme.secondaryContainer;
        textColor = theme.colorScheme.onSecondaryContainer;
        icon = Icons.refresh;
        label = 'Refunded';
        break;
      case PaymentStatus.partiallyRefunded:
        backgroundColor = theme.colorScheme.secondaryContainer;
        textColor = theme.colorScheme.onSecondaryContainer;
        icon = Icons.refresh;
        label = 'Partially Refunded';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: textColor,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
