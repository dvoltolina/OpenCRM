import 'package:flutter/material.dart';

import '../../../../core/config/app_config.dart';

/// Displays the reschedule policy information
class ReschedulePolicyNotice extends StatelessWidget {
  const ReschedulePolicyNotice({
    required this.policy,
    super.key,
  });

  final BookingPolicies policy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reschedule Policy',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Changes are allowed up to '
            '${policy.cancellationWindow.inHours} hours before your visit.',
          ),
          if (policy.requireManualApprovalInsideWindow) ...[
            const SizedBox(height: 4),
            const Text(
              'Requests inside the notice window may require manual approval.',
            ),
          ],
          if (policy.rescheduleFeeAmount != null) ...[
            const SizedBox(height: 4),
            Text(
              'Late changes may incur a fee of '
              '\$${policy.rescheduleFeeAmount!.toStringAsFixed(2)}.',
            ),
          ],
        ],
      ),
    );
  }
}
