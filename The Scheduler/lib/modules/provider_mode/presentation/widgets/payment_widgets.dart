import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/payment.dart';

/// Date group card widget for payment grouping
class PaymentDateGroupCard extends StatelessWidget {
  const PaymentDateGroupCard({
    super.key,
    required this.date,
    required this.payments,
    required this.onTap,
  });

  final DateTime date;
  final List<Payment> payments;
  final Function(Payment) onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('EEEE, MMM d, yyyy');
    final totalAmount = payments.fold<int>(0, (sum, p) => sum + p.netAmountCents);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateFormat.format(date),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '\$${(totalAmount / 100).toStringAsFixed(2)}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...payments.map((payment) => PaymentTile(
                payment: payment,
                onTap: () => onTap(payment),
              )),
        ],
      ),
    );
  }
}

/// Payment tile widget
class PaymentTile extends StatelessWidget {
  const PaymentTile({
    super.key,
    required this.payment,
    required this.onTap,
  });

  final Payment payment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeFormat = DateFormat('h:mm a');

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor:
            PaymentHelpers.statusColor(payment.status, theme).withValues(alpha: 0.2),
        child: Icon(
          PaymentHelpers.statusIcon(payment.status),
          color: PaymentHelpers.statusColor(payment.status, theme),
          size: 20,
        ),
      ),
      title: Text(
        PaymentHelpers.paymentTypeDisplay(payment.type),
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        timeFormat.format(payment.createdAt),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '\$${payment.amountDollars.toStringAsFixed(2)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (payment.isRefunded)
            Text(
              'Refunded',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
        ],
      ),
    );
  }
}

/// Filter dialog for payments
class PaymentFilterDialog extends StatefulWidget {
  const PaymentFilterDialog({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.statusFilter,
    required this.onApply,
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final PaymentStatus? statusFilter;
  final Function(DateTime?, DateTime?, PaymentStatus?) onApply;

  @override
  State<PaymentFilterDialog> createState() => _PaymentFilterDialogState();
}

class _PaymentFilterDialogState extends State<PaymentFilterDialog> {
  DateTime? _startDate;
  DateTime? _endDate;
  PaymentStatus? _statusFilter;

  @override
  void initState() {
    super.initState();
    _startDate = widget.startDate;
    _endDate = widget.endDate;
    _statusFilter = widget.statusFilter;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, yyyy');

    return AlertDialog(
      title: const Text('Filter Payments'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Date Range', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(
                    _startDate != null
                        ? dateFormat.format(_startDate!)
                        : 'Start Date',
                    style: theme.textTheme.bodySmall,
                  ),
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _startDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => _startDate = date);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(
                    _endDate != null
                        ? dateFormat.format(_endDate!)
                        : 'End Date',
                    style: theme.textTheme.bodySmall,
                  ),
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _endDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => _endDate = date);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Status', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          DropdownButtonFormField<PaymentStatus?>(
            initialValue: _statusFilter,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('All')),
              ...PaymentStatus.values.map((status) => DropdownMenuItem(
                    value: status,
                    child: Text(PaymentHelpers.statusDisplay(status)),
                  )),
            ],
            onChanged: (value) => setState(() => _statusFilter = value),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            setState(() {
              _startDate = null;
              _endDate = null;
              _statusFilter = null;
            });
          },
          child: const Text('Clear'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            widget.onApply(_startDate, _endDate, _statusFilter);
            Navigator.pop(context);
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

/// Payment detail bottom sheet
class PaymentDetailSheet extends StatelessWidget {
  const PaymentDetailSheet({
    super.key,
    required this.payment,
  });

  final Payment payment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, yyyy h:mm a');

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => Container(
        padding: const EdgeInsets.all(24),
        child: ListView(
          controller: scrollController,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Payment Details',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _DetailRow(label: 'Amount', value: '\$${payment.amountDollars.toStringAsFixed(2)}'),
            _DetailRow(label: 'Status', value: PaymentHelpers.statusDisplay(payment.status)),
            _DetailRow(label: 'Type', value: PaymentHelpers.paymentTypeDisplay(payment.type)),
            _DetailRow(label: 'Date', value: dateFormat.format(payment.createdAt)),
            if (payment.paymentMethodDisplay != 'Unknown')
              _DetailRow(label: 'Payment Method', value: payment.paymentMethodDisplay),
            if (payment.isRefunded) ...[
              const Divider(height: 32),
              _DetailRow(
                label: 'Refund Amount',
                value: '\$${payment.refundAmountDollars.toStringAsFixed(2)}',
              ),
              if (payment.refundedAt != null)
                _DetailRow(
                  label: 'Refunded On',
                  value: dateFormat.format(payment.refundedAt!),
                ),
            ],
            if (payment.notes != null) ...[
              const Divider(height: 32),
              Text('Notes', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Text(payment.notes!, style: theme.textTheme.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper functions for payment display
class PaymentHelpers {
  static IconData statusIcon(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.completed:
        return Icons.check_circle;
      case PaymentStatus.pending:
        return Icons.pending;
      case PaymentStatus.failed:
        return Icons.error;
      case PaymentStatus.refunded:
      case PaymentStatus.partiallyRefunded:
        return Icons.undo;
      case PaymentStatus.none:
        return Icons.remove_circle_outline;
    }
  }

  static Color statusColor(PaymentStatus status, ThemeData theme) {
    switch (status) {
      case PaymentStatus.completed:
        return Colors.green;
      case PaymentStatus.pending:
        return Colors.orange;
      case PaymentStatus.failed:
        return theme.colorScheme.error;
      case PaymentStatus.refunded:
      case PaymentStatus.partiallyRefunded:
        return Colors.grey;
      case PaymentStatus.none:
        return theme.colorScheme.outline;
    }
  }

  static String paymentTypeDisplay(PaymentType type) {
    switch (type) {
      case PaymentType.deposit:
        return 'Deposit';
      case PaymentType.full:
        return 'Full Payment';
      case PaymentType.subscription:
        return 'Subscription';
      case PaymentType.rescheduleFee:
        return 'Reschedule Fee';
      case PaymentType.cancellationFee:
        return 'Cancellation Fee';
      case PaymentType.refund:
        return 'Refund';
    }
  }

  static String statusDisplay(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.none:
        return 'None';
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.completed:
        return 'Completed';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.refunded:
        return 'Refunded';
      case PaymentStatus.partiallyRefunded:
        return 'Partially Refunded';
    }
  }
}
