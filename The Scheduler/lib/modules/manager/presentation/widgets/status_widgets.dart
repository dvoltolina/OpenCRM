import 'package:flutter/material.dart';

import '../../providers/manager_providers.dart';

class ClockStatusIndicator extends StatelessWidget {
  const ClockStatusIndicator({
    super.key,
    required this.status,
    required this.label,
  });

  final ClockStatus status;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      ClockStatus.clockedIn => Colors.green,
      ClockStatus.onBreak => Colors.orange,
      ClockStatus.pending => Colors.blueGrey,
      ClockStatus.off => Colors.grey,
    };

    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }
}

class TeamStatusCard extends StatelessWidget {
  const TeamStatusCard({
    super.key,
    required this.label,
    required this.count,
    required this.color,
    this.onTap,
  });

  final String label;
  final int count;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: color.withValues(alpha: 0.12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$count',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class PendingApprovalCard extends StatelessWidget {
  const PendingApprovalCard({
    super.key,
    required this.count,
    required this.subtitle,
    this.onTap,
  });

  final int count;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.pending_actions_outlined),
        title: const Text('Pending Approvals'),
        subtitle: Text(subtitle),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (count > 0)
              CircleAvatar(
                radius: 12,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  '$count',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
