import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/payment.dart';
import '../../../../data/models/appointment.dart';
import '../../../../data/models/service.dart';
import 'payment_status_chip.dart';

/// Displays a payment in a card format with all relevant details
class PaymentCardWidget extends StatelessWidget {
  const PaymentCardWidget({
    required this.payment,
    required this.onTap,
    required this.onDownloadReceipt,
    this.appointment,
    this.service,
    super.key,
  });

  final Payment payment;
  final VoidCallback onTap;
  final VoidCallback onDownloadReceipt;
  final Appointment? appointment;
  final Service? service;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, y');
    final timeFormat = DateFormat('h:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Date and Amount
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dateFormat.format(payment.createdAt),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    payment.isRefund
                        ? '-\$${payment.amountDollars.toStringAsFixed(2)}'
                        : '\$${payment.amountDollars.toStringAsFixed(2)}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: payment.isRefund
                          ? theme.colorScheme.error
                          : theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Service name (if available)
              if (service != null) ...[
                Text(
                  service!.name,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
              ],

              // Appointment date (if available)
              if (appointment != null) ...[
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${dateFormat.format(appointment!.startTime)} at '
                      '${timeFormat.format(appointment!.startTime)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],

              // Payment method
              Row(
                children: [
                  Icon(
                    Icons.credit_card_outlined,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    payment.paymentMethodDisplay,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Status chip and actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  PaymentStatusChip(status: payment.status),
                  if (payment.isCompleted)
                    TextButton.icon(
                      onPressed: onDownloadReceipt,
                      icon: const Icon(Icons.download_outlined, size: 16),
                      label: const Text('Receipt'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        minimumSize: const Size(48, 48),
                      ),
                    ),
                ],
              ),

              // Refund info (if refunded)
              if (payment.isRefunded) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Refunded: \$${payment.refundAmountDollars.toStringAsFixed(2)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
