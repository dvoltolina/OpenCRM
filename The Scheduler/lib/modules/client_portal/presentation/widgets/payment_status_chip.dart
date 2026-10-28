import 'package:flutter/material.dart';

import '../../../../data/models/payment.dart';

/// Displays a status chip for payment status
class PaymentStatusChip extends StatelessWidget {
  const PaymentStatusChip({
    required this.status,
    super.key,
  });

  final PaymentStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chipData = _getChipData(theme);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: chipData.backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(chipData.icon, size: 14, color: chipData.textColor),
          const SizedBox(width: 4),
          Text(
            chipData.label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: chipData.textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  _ChipData _getChipData(ThemeData theme) {
    switch (status) {
      case PaymentStatus.completed:
        return _ChipData(
          backgroundColor: theme.colorScheme.primaryContainer,
          textColor: theme.colorScheme.onPrimaryContainer,
          label: 'Completed',
          icon: Icons.check_circle_outline,
        );
      case PaymentStatus.pending:
        return _ChipData(
          backgroundColor: theme.colorScheme.secondaryContainer,
          textColor: theme.colorScheme.onSecondaryContainer,
          label: 'Pending',
          icon: Icons.schedule_outlined,
        );
      case PaymentStatus.failed:
        return _ChipData(
          backgroundColor: theme.colorScheme.errorContainer,
          textColor: theme.colorScheme.onErrorContainer,
          label: 'Failed',
          icon: Icons.error_outline,
        );
      case PaymentStatus.refunded:
      case PaymentStatus.partiallyRefunded:
        return _ChipData(
          backgroundColor: theme.colorScheme.tertiaryContainer,
          textColor: theme.colorScheme.onTertiaryContainer,
          label: status == PaymentStatus.refunded
              ? 'Refunded'
              : 'Partial Refund',
          icon: Icons.undo_outlined,
        );
      case PaymentStatus.none:
        return _ChipData(
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          textColor: theme.colorScheme.onSurfaceVariant,
          label: 'No Payment',
          icon: Icons.remove_circle_outline,
        );
    }
  }
}

class _ChipData {
  final Color backgroundColor;
  final Color textColor;
  final String label;
  final IconData icon;

  _ChipData({
    required this.backgroundColor,
    required this.textColor,
    required this.label,
    required this.icon,
  });
}
