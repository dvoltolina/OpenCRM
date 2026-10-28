import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/timesheet_service.dart';
import '../../../../data/models/security_context.dart';
import '../../providers/timesheet_providers.dart';

/// Summary bar showing period totals at the bottom of the timesheets page.
class TimesheetSummaryBar extends ConsumerWidget {
  const TimesheetSummaryBar({
    super.key,
    required this.context,
  });

  final SecurityContext context;

  @override
  Widget build(BuildContext ctx, WidgetRef ref) {
    final theme = Theme.of(ctx);
    final statsAsync = ref.watch(payPeriodStatsProvider(context));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: statsAsync.when(
          loading: () => const Center(
            child: SizedBox(
              height: 48,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (error, _) => Text(
            'Error loading stats',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          data: (stats) => _SummaryContent(stats: stats),
        ),
      ),
    );
  }
}

class _SummaryContent extends StatelessWidget {
  const _SummaryContent({required this.stats});

  final PayPeriodStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        // Staff count
        _SummaryItem(
          label: 'Staff',
          value: stats.totalStaff.toString(),
          icon: Icons.people,
        ),

        const SizedBox(width: 24),

        // Total hours
        _SummaryItem(
          label: 'Total Hours',
          value: stats.totalWorkedHours.toStringAsFixed(1),
          icon: Icons.schedule,
        ),

        const SizedBox(width: 24),

        // Overtime
        if (stats.totalOvertimeHours > 0) ...[
          _SummaryItem(
            label: 'Overtime',
            value: stats.totalOvertimeHours.toStringAsFixed(1),
            icon: Icons.trending_up,
            isHighlighted: true,
          ),
          const SizedBox(width: 24),
        ],

        // Pending count
        if (stats.pendingApprovals > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.hourglass_empty,
                  size: 16,
                  color: Colors.orange.shade900,
                ),
                const SizedBox(width: 4),
                Text(
                  '${stats.pendingApprovals} pending',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.orange.shade900,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

        const Spacer(),

        // Approval rate (if entries exist)
        if (stats.totalEntries > 0)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${stats.approvalRate.toStringAsFixed(0)}%',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              Text(
                'approved',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.label,
    required this.value,
    required this.icon,
    this.isHighlighted = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isHighlighted ? Colors.orange : theme.colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 12,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
