import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/safe_error_handler.dart';
import '../../../../data/models/appointment.dart';
import '../../../../data/models/group_attendee.dart';
import '../../../../data/models/payment.dart';
import '../../../../data/models/security_context.dart';
import '../utils/group_session_billing.dart';

/// Dialog for staff to manage attendee payment actions (mark paid, refund, etc.)
class AttendeePaymentActionsDialog extends StatefulWidget {
  const AttendeePaymentActionsDialog({
    super.key,
    required this.appointment,
    required this.attendee,
    required this.billingHelper,
    required this.securityContext,
  });

  final Appointment appointment;
  final GroupAttendee attendee;
  final GroupSessionBillingHelper billingHelper;
  final SecurityContext securityContext;

  @override
  State<AttendeePaymentActionsDialog> createState() =>
      _AttendeePaymentActionsDialogState();
}

class _AttendeePaymentActionsDialogState
    extends State<AttendeePaymentActionsDialog> {
  bool _isProcessing = false;
  String? _errorMessage;
  final _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Default to $50 if not set
    _amountController.text = '50.00';
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text('Payment Actions - ${widget.attendee.displayName}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current status
            _buildStatusSection(theme),
            const SizedBox(height: 16),

            // Amount input
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '\$',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: theme.colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Preview cancellation
            if (widget.attendee.paymentStatus == PaymentStatus.completed) ...[
              const Divider(),
              const SizedBox(height: 12),
              Text(
                'Cancellation Preview',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              FutureBuilder<AttendeeCancellationResult>(
                future: _previewCancellation(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }

                  final preview = snapshot.data!;
                  return _buildCancellationPreview(theme, preview);
                },
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        if (widget.attendee.paymentStatus != PaymentStatus.completed)
          FilledButton.icon(
            onPressed: _isProcessing ? null : _markAsPaid,
            icon: const Icon(Icons.check_circle),
            label: const Text('Mark Paid'),
          ),
        if (widget.attendee.paymentStatus == PaymentStatus.completed)
          FilledButton.icon(
            onPressed: _isProcessing ? null : _processRefund,
            icon: const Icon(Icons.refresh),
            label: const Text('Process Refund'),
          ),
      ],
    );
  }

  Widget _buildStatusSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Payment Status:',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              _getStatusChip(theme, widget.attendee.paymentStatus),
            ],
          ),
          if (widget.attendee.refundStatus != PaymentStatus.none) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Refund Status:',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 8),
                _getStatusChip(theme, widget.attendee.refundStatus),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCancellationPreview(
    ThemeData theme,
    AttendeeCancellationResult preview,
  ) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: preview.isLateCancel
            ? Color.alphaBlend(
                theme.colorScheme.errorContainer.withAlpha(128),
                theme.colorScheme.surface,
              )
            : Color.alphaBlend(
                theme.colorScheme.primaryContainer.withAlpha(128),
                theme.colorScheme.surface,
              ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            preview.message ?? 'Refund calculation',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          if (preview.refundAmountCents > 0)
            _buildPreviewRow(
              'Refund',
              currencyFormat.format(preview.refundAmountDollars),
              theme.colorScheme.secondary,
            ),
          if (preview.cancellationFeeCents > 0)
            _buildPreviewRow(
              'Fee',
              currencyFormat.format(preview.cancellationFeeDollars),
              theme.colorScheme.error,
            ),
          if (preview.netRefundCents != preview.refundAmountCents) ...[
            const Divider(height: 12),
            _buildPreviewRow(
              'Net Refund',
              currencyFormat.format(preview.netRefundCents / 100),
              theme.colorScheme.primary,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPreviewRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _getStatusChip(ThemeData theme, PaymentStatus status) {
    Color backgroundColor;
    Color textColor;
    String label;

    switch (status) {
      case PaymentStatus.none:
        backgroundColor = theme.colorScheme.surfaceContainerHighest;
        textColor = theme.colorScheme.onSurfaceVariant;
        label = 'None';
        break;
      case PaymentStatus.pending:
        backgroundColor = theme.colorScheme.tertiaryContainer;
        textColor = theme.colorScheme.onTertiaryContainer;
        label = 'Pending';
        break;
      case PaymentStatus.completed:
        backgroundColor = theme.colorScheme.primaryContainer;
        textColor = theme.colorScheme.onPrimaryContainer;
        label = 'Paid';
        break;
      case PaymentStatus.failed:
        backgroundColor = theme.colorScheme.errorContainer;
        textColor = theme.colorScheme.onErrorContainer;
        label = 'Failed';
        break;
      case PaymentStatus.refunded:
        backgroundColor = theme.colorScheme.secondaryContainer;
        textColor = theme.colorScheme.onSecondaryContainer;
        label = 'Refunded';
        break;
      case PaymentStatus.partiallyRefunded:
        backgroundColor = theme.colorScheme.secondaryContainer;
        textColor = theme.colorScheme.onSecondaryContainer;
        label = 'Partial';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Future<AttendeeCancellationResult> _previewCancellation() async {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final amountCents = (amount * 100).round();

    return widget.billingHelper.previewCancellation(
      appointment: widget.appointment,
      attendee: widget.attendee,
      originalPaymentCents: amountCents,
    );
  }

  Future<void> _markAsPaid() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      setState(() {
        _errorMessage = 'Please enter a valid amount';
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      await widget.billingHelper.markPaid(
        actorContext: widget.securityContext,
        appointment: widget.appointment,
        attendee: widget.attendee,
        amountCents: (amount * 100).round(),
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attendee marked as paid'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      final safeMessage = SafeErrorHandler.handle(e, context: 'marking attendee as paid');
      setState(() {
        _isProcessing = false;
        _errorMessage = safeMessage;
      });
    }
  }

  Future<void> _processRefund() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      setState(() {
        _errorMessage = 'Please enter a valid amount';
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      await widget.billingHelper.processAttendeeCancellation(
        actorContext: widget.securityContext,
        appointment: widget.appointment,
        attendee: widget.attendee,
        originalPaymentCents: (amount * 100).round(),
        cancellationReason: 'Staff-initiated refund',
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Refund processed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      final safeMessage = SafeErrorHandler.handle(e, context: 'processing refund');
      setState(() {
        _isProcessing = false;
        _errorMessage = safeMessage;
      });
    }
  }
}
