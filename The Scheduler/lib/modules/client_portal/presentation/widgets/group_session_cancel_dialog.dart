import 'package:flutter/material.dart';

import '../../../../data/models/appointment.dart';
import '../../../booking/presentation/utils/group_session_billing.dart';

class GroupSessionCancelDialog extends StatelessWidget {
  const GroupSessionCancelDialog({
    required this.session,
    required this.preview,
    super.key,
  });

  final Appointment session;
  final AttendeeCancellationResult preview;

  static Future<bool> show({
    required BuildContext context,
    required Appointment session,
    required AttendeeCancellationResult preview,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => GroupSessionCancelDialog(
            session: session,
            preview: preview,
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cancel Registration'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Are you sure you want to cancel your spot?'),
          const SizedBox(height: 16),
          if (preview.refundAmountCents > 0 ||
              preview.cancellationFeeCents > 0) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Financial Summary',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  if (preview.refundAmountCents > 0)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Refund:'),
                        Text(
                          '\$${preview.refundAmountDollars.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  if (preview.cancellationFeeCents > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Cancellation fee:'),
                        Text(
                          '-\$${preview.cancellationFeeDollars.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (preview.netRefundCents != preview.refundAmountCents &&
                      preview.netRefundCents > 0) ...[
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Net refund:'),
                        Text(
                          '\$${(preview.netRefundCents / 100).toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (preview.isLateCancel)
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This is a late cancellation.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Keep Spot'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          child: const Text('Cancel Registration'),
        ),
      ],
    );
  }
}
