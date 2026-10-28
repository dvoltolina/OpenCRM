import 'package:flutter/material.dart';

import '../../../../data/models/business_stats.dart';
import '../../../manager/providers/manager_providers.dart';

/// Single stat card showing a metric with optional trend indicator.
class StatCard extends StatelessWidget {
  const StatCard({
    required this.value,
    required this.label,
    this.trend,
    this.icon,
    this.color,
    super.key,
  });

  final String value;
  final String label;
  final String? trend;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = color ?? theme.colorScheme.primaryContainer;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null) ...[
              Icon(icon, color: cardColor, size: 24),
              const SizedBox(height: 8),
            ],
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (trend != null) ...[
              const SizedBox(height: 4),
              Text(
                trend!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.secondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Row of stat cards for business health overview.
class StatsRow extends StatelessWidget {
  const StatsRow({
    required this.stats,
    super.key,
  });

  final BusinessStats stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            value: '${stats.appointmentsToday}',
            label: 'Appts Today',
            trend: stats.appointmentsTrend,
            icon: Icons.calendar_today,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            value: stats.revenueTodayFormatted,
            label: 'Revenue',
            trend: stats.revenueTrend,
            icon: Icons.attach_money,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            value: '${stats.staffOnDuty}/${stats.staffTotal}',
            label: 'Staff On',
            icon: Icons.people,
          ),
        ),
      ],
    );
  }
}

/// Card showing pending actions that need admin attention.
class PendingActionsCard extends StatelessWidget {
  const PendingActionsCard({
    required this.count,
    required this.description,
    required this.onTap,
    super.key,
  });

  final int count;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (count == 0) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      color: theme.colorScheme.errorContainer,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: theme.colorScheme.onErrorContainer,
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Needs Your Attention',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ],
                ),
              ),
              Badge(
                label: Text('$count'),
                backgroundColor: theme.colorScheme.error,
                textColor: theme.colorScheme.onError,
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios,
                color: theme.colorScheme.onErrorContainer,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Visual bar showing team status (clocked in, on break, off).
class TeamStatusBar extends StatelessWidget {
  const TeamStatusBar({
    required this.counts,
    super.key,
  });

  final ClockStatusCounts counts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = counts.clockedIn + counts.onBreak + counts.off + counts.pending;

    if (total == 0) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Team Status',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatusBadge(
                    label: 'Working',
                    count: counts.clockedIn,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatusBadge(
                    label: 'On Break',
                    count: counts.onBreak,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatusBadge(
                    label: 'Off',
                    count: counts.off,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: theme.textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Card showing a brief summary section.
class SummaryCard extends StatelessWidget {
  const SummaryCard({
    required this.title,
    required this.child,
    this.action,
    super.key,
  });

  final String title;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (action != null) action!,
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
