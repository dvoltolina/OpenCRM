import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/providers.dart';
import '../../../../core/services/stripe_service.dart';
import '../../../../core/ui/components/components.dart';
import '../../../../core/utils/safe_error_handler.dart';
import '../../../../data/models/payment.dart';

/// Widget for collecting payment during booking flow with premium styling
///
/// This widget integrates with Stripe to collect payment for appointments.
/// It should be added to the booking flow when payment is required.
///
/// Usage:
/// ```dart
/// PaymentCollectionWidget(
///   amountCents: 5000, // $50.00
///   appointmentId: 'appt_123',
///   businessId: 'biz_123',
///   clientId: 'client_123',
///   onPaymentSuccess: (payment) {
///     // Handle successful payment
///   },
///   onPaymentFailed: (error) {
///     // Handle failed payment
///   },
/// )
/// ```
class PaymentCollectionWidget extends ConsumerStatefulWidget {
  final int amountCents;
  final String appointmentId;
  final String businessId;
  final String clientId;
  final PaymentType paymentType;
  final Function(Payment) onPaymentSuccess;
  final Function(String error) onPaymentFailed;
  final String? cloudFunctionUrl;
  final String? destinationAccountId;

  const PaymentCollectionWidget({
    super.key,
    required this.amountCents,
    required this.appointmentId,
    required this.businessId,
    required this.clientId,
    required this.onPaymentSuccess,
    required this.onPaymentFailed,
    this.paymentType = PaymentType.full,
    this.cloudFunctionUrl,
    this.destinationAccountId,
  });

  @override
  ConsumerState<PaymentCollectionWidget> createState() =>
      _PaymentCollectionWidgetState();
}

class _PaymentCollectionWidgetState extends ConsumerState<PaymentCollectionWidget> {
  bool _isProcessing = false;
  String? _error;

  int _computePlatformFee(int amountCents) {
    // 0.05% + $0.30 in cents
    return (amountCents * 0.0005).floor() + 30;
  }

  @override
  Widget build(BuildContext context) {
    final branding = ref.watch(appConfigProvider).branding;
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: branding.primaryColor.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: branding.accentColor.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [branding.primaryColor, branding.accentColor],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.payment, color: Colors.white, size: 20),
                ),
                HSpace.sm,
                Text(
                  'Payment',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: branding.primaryColor,
                  ),
                ),
              ],
            ),
            VSpace.md,
            _buildPaymentSummary(theme),
            if (_error != null) ...[
              VSpace.md,
              _buildErrorMessage(theme),
            ],
            VSpace.md,
            _buildPaymentButton(theme),
            VSpace.sm,
            _buildSecurityNote(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSummary(ThemeData theme) {
    final branding = ref.watch(appConfigProvider).branding;
    final amountDollars = widget.amountCents / 100;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            branding.primaryColor.withValues(alpha: 0.05),
            branding.accentColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: branding.accentColor.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getPaymentTypeLabel(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: branding.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [branding.primaryColor, branding.accentColor],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '\$${amountDollars.toStringAsFixed(2)}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          if (widget.paymentType == PaymentType.deposit) ...[
            VSpace.xs,
            Text(
              'Full payment will be collected at appointment time',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorMessage(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.error, size: AppIconSize.sm),
          HSpace.xs,
          Expanded(
            child: Text(
              _error!,
              style: TextStyle(color: theme.colorScheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentButton(ThemeData theme) {
    return GradientButton(
      onPressed: _isProcessing ? null : _processPayment,
      isLoading: _isProcessing,
      height: 56,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!_isProcessing) const Icon(Icons.lock, size: 20),
          if (!_isProcessing) const SizedBox(width: 8),
          Text(
            _isProcessing
                ? 'Processing...'
                : 'Pay \$${(widget.amountCents / 100).toStringAsFixed(2)}',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityNote(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.shield, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          'Secured by Stripe',
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  String _getPaymentTypeLabel() {
    switch (widget.paymentType) {
      case PaymentType.deposit:
        return 'Deposit Required';
      case PaymentType.full:
        return 'Amount Due';
      case PaymentType.subscription:
        return 'Subscription Payment';
      case PaymentType.rescheduleFee:
        return 'Reschedule Fee';
      case PaymentType.cancellationFee:
        return 'Cancellation Fee';
      case PaymentType.refund:
        return 'Refund';
    }
  }

  Future<void> _processPayment() async {
    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      final stripeService = StripeService.instance;

      if (!stripeService.isInitialized) {
        throw Exception('Stripe is not initialized');
      }

      // Get cloud function URL from environment or use default
      final functionUrl = widget.cloudFunctionUrl ??
          'https://us-central1-project.cloudfunctions.net/createPaymentIntent';

      final feeCents = _computePlatformFee(widget.amountCents);

      // Create payment intent via cloud function
      final result = await stripeService.createPaymentIntent(
        cloudFunctionUrl: functionUrl,
        amountCents: widget.amountCents,
        metadata: {
          'appointmentId': widget.appointmentId,
          'businessId': widget.businessId,
          'clientId': widget.clientId,
          'paymentType': widget.paymentType.name,
        },
        destinationAccountId: widget.destinationAccountId,
        applicationFeeAmountCents: feeCents,
      );

      final clientSecret = result['clientSecret'] as String;
      final paymentIntentId = result['paymentIntentId'] as String;

      // Present payment sheet
      final success = await stripeService.presentPaymentSheet(
        clientSecret: clientSecret,
      );

      if (success) {
        // Create payment record
        final payment = Payment(
          id: paymentIntentId,
          businessId: widget.businessId,
          appointmentId: widget.appointmentId,
          clientId: widget.clientId,
          amountCents: widget.amountCents,
          status: PaymentStatus.completed,
          type: widget.paymentType,
          stripePaymentIntentId: paymentIntentId,
          createdAt: DateTime.now(),
          completedAt: DateTime.now(),
        );

        widget.onPaymentSuccess(payment);
      } else {
        setState(() {
          _error = 'Payment was not completed. Please try again.';
        });
        widget.onPaymentFailed('Payment was not completed');
      }
    } catch (e) {
      final safeMessage = SafeErrorHandler.handle(e, context: 'processing payment');
      setState(() {
        _error = safeMessage;
      });
      widget.onPaymentFailed(safeMessage);
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
}

/// Simple payment info display widget for completed payments
class PaymentInfoWidget extends StatelessWidget {
  final Payment payment;

  const PaymentInfoWidget({
    super.key,
    required this.payment,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildStatusIcon(),
                const SizedBox(width: 12),
                Text(
                  _getStatusLabel(),
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Amount', '\$${payment.amountDollars.toStringAsFixed(2)}', theme),
            const SizedBox(height: 8),
            _buildInfoRow('Payment Method', payment.paymentMethodDisplay, theme),
            const SizedBox(height: 8),
            _buildInfoRow('Date', _formatDate(payment.completedAt ?? payment.createdAt), theme),
            if (payment.isRefunded) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                'Refunded',
                '\$${payment.refundAmountDollars.toStringAsFixed(2)}',
                theme,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    if (payment.isCompleted) {
      return const Icon(Icons.check_circle, color: Colors.green);
    } else if (payment.isPending) {
      return const Icon(Icons.schedule, color: Colors.orange);
    } else if (payment.isFailed) {
      return const Icon(Icons.error, color: Colors.red);
    } else if (payment.isRefunded) {
      return const Icon(Icons.undo, color: Colors.blue);
    }
    return const Icon(Icons.help_outline, color: Colors.grey);
  }

  String _getStatusLabel() {
    if (payment.isCompleted) {
      return 'Payment Completed';
    } else if (payment.isPending) {
      return 'Payment Pending';
    } else if (payment.isFailed) {
      return 'Payment Failed';
    } else if (payment.isRefunded) {
      return 'Payment Refunded';
    }
    return 'Payment Status Unknown';
  }

  Widget _buildInfoRow(String label, String value, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
        Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
