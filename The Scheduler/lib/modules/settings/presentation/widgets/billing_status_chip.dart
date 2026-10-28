import 'package:flutter/material.dart';

import '../../../../data/models/subscription.dart';

/// Status chip showing subscription status
class BillingStatusChip extends StatelessWidget {
  final Subscription subscription;
  final ThemeData theme;

  const BillingStatusChip({
    super.key,
    required this.subscription,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    String label;

    if (subscription.isTrialing) {
      bgColor = Colors.blue[100]!;
      textColor = Colors.blue[900]!;
      label = 'Trial';
    } else if (subscription.isActive) {
      bgColor = Colors.green[100]!;
      textColor = Colors.green[900]!;
      label = 'Active';
    } else if (subscription.requiresPaymentAction) {
      bgColor = Colors.orange[100]!;
      textColor = Colors.orange[900]!;
      label = 'Payment Required';
    } else {
      bgColor = Colors.red[100]!;
      textColor = Colors.red[900]!;
      label = 'Inactive';
    }

    return Chip(
      label: Text(label, style: TextStyle(color: textColor)),
      backgroundColor: bgColor,
    );
  }
}
