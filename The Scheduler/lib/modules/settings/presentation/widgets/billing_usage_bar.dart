import 'package:flutter/material.dart';

/// Usage bar showing current usage vs limit
class BillingUsageBar extends StatelessWidget {
  final String label;
  final int current;
  final int max;
  final ThemeData theme;

  const BillingUsageBar({
    super.key,
    required this.label,
    required this.current,
    required this.max,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final isUnlimited = max == -1;
    final percentage = isUnlimited ? 0.0 : (current / max).clamp(0.0, 1.0);
    final isNearLimit = percentage >= 0.8;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: theme.textTheme.bodyMedium),
            Text(
              isUnlimited ? '$current (Unlimited)' : '$current / $max',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isNearLimit ? Colors.orange[700] : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (!isUnlimited)
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation(
                isNearLimit ? Colors.orange : Colors.green,
              ),
              minHeight: 8,
            ),
          ),
      ],
    );
  }
}
