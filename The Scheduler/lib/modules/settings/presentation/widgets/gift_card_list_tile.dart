import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/gift_card.dart';

/// List tile for displaying a gift card
class GiftCardListTile extends StatelessWidget {
  const GiftCardListTile({
    required this.giftCard,
    required this.onTap,
    super.key,
  });

  final GiftCard giftCard;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat.yMMMd();

    return ListTile(
      onTap: onTap,
      leading: GiftCardStatusBadge(status: giftCard.status),
      title: Row(
        children: [
          Text(
            giftCard.code,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.copy, size: 16),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: giftCard.code));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Code copied'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            tooltip: 'Copy code',
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
            iconSize: 16,
          ),
        ],
      ),
      subtitle: Text(
        '${giftCard.purchaserEmail} - ${dateFormat.format(giftCard.purchasedAt)}',
        style: TextStyle(color: Colors.grey.shade600),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '\$${giftCard.remainingBalanceDollars.toStringAsFixed(2)}',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: giftCard.remainingBalanceCents > 0
                  ? theme.colorScheme.primary
                  : Colors.grey,
            ),
          ),
          if (giftCard.remainingBalanceCents != giftCard.originalAmountCents)
            Text(
              'of \$${giftCard.originalAmountDollars.toStringAsFixed(2)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade500,
              ),
            ),
        ],
      ),
    );
  }
}

/// Status badge for gift cards
class GiftCardStatusBadge extends StatelessWidget {
  const GiftCardStatusBadge({required this.status, super.key});

  final GiftCardStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: _statusColor(status).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        _statusIcon(status),
        color: _statusColor(status),
        size: 24,
      ),
    );
  }

  Color _statusColor(GiftCardStatus status) {
    switch (status) {
      case GiftCardStatus.pending:
        return Colors.orange;
      case GiftCardStatus.active:
        return Colors.green;
      case GiftCardStatus.depleted:
        return Colors.grey;
      case GiftCardStatus.expired:
        return Colors.red;
      case GiftCardStatus.voided:
        return Colors.red.shade900;
    }
  }

  IconData _statusIcon(GiftCardStatus status) {
    switch (status) {
      case GiftCardStatus.pending:
        return Icons.hourglass_empty;
      case GiftCardStatus.active:
        return Icons.card_giftcard;
      case GiftCardStatus.depleted:
        return Icons.check_circle_outline;
      case GiftCardStatus.expired:
        return Icons.timer_off;
      case GiftCardStatus.voided:
        return Icons.cancel_outlined;
    }
  }
}
