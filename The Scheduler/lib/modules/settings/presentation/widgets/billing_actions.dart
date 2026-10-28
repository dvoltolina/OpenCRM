import 'package:flutter/material.dart';

import '../../../../data/models/subscription.dart';

/// Billing actions section for managing subscription
class BillingActions extends StatelessWidget {
  final Subscription subscription;
  final dynamic branding;
  final VoidCallback onOpenCustomerPortal;
  final VoidCallback onViewInvoices;
  final VoidCallback onCancelSubscription;
  final VoidCallback onReactivateSubscription;

  const BillingActions({
    super.key,
    required this.subscription,
    required this.branding,
    required this.onOpenCustomerPortal,
    required this.onViewInvoices,
    required this.onCancelSubscription,
    required this.onReactivateSubscription,
  });

  @override
  Widget build(BuildContext context) {
    if (subscription.tier == SubscriptionTier.free) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onOpenCustomerPortal,
            icon: const Icon(Icons.credit_card),
            label: const Text('Manage Payment Method'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onViewInvoices,
            icon: const Icon(Icons.receipt_long),
            label: const Text('View Invoices'),
          ),
        ),
        const SizedBox(height: 12),
        if (subscription.cancelAtPeriodEnd)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onReactivateSubscription,
              icon: const Icon(Icons.restart_alt),
              label: const Text('Reactivate Subscription'),
              style: ElevatedButton.styleFrom(
                backgroundColor: branding.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          )
        else
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onCancelSubscription,
              icon: const Icon(Icons.cancel),
              label: const Text('Cancel Subscription'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red[700],
              ),
            ),
          ),
      ],
    );
  }
}
