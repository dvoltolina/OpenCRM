import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../data/local/staff_database.dart';
import '../../providers/time_clock_providers.dart';
import 'time_entry_card.dart';

/// Displays a list of today's time entries for the current staff member.
///
/// Features:
/// - Shows all time entries from today
/// - Active entry highlighted with blue timer
/// - Completed entries show duration and status
/// - Empty state when no entries exist
/// - Pull-to-refresh support
class TodaysActivityList extends ConsumerWidget {
  const TodaysActivityList({
    super.key,
    this.onEntryTap,
  });

  /// Callback when a time entry is tapped.
  final void Function(TimeEntriesTableData entry)? onEntryTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(todaysEntriesProvider);

    return entriesAsync.when(
      loading: () => const _LoadingState(),
      error: (error, stack) => _ErrorState(
        error: error.toString(),
        onRetry: () => ref.invalidate(todaysEntriesProvider),
      ),
      data: (entries) {
        if (entries.isEmpty) {
          return const _EmptyState();
        }
        return _EntryList(
          entries: entries,
          onEntryTap: onEntryTap,
        );
      },
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.error,
    required this.onRetry,
  });

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load entries',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.schedule_outlined,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No Activity Today',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Clock in to start tracking your time',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _EntryList extends StatelessWidget {
  const _EntryList({
    required this.entries,
    this.onEntryTap,
  });

  final List<TimeEntriesTableData> entries;
  final void Function(TimeEntriesTableData entry)? onEntryTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = DateFormat.yMMMd().format(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Icon(
                Icons.today,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                "Today's Activity",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                today,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        // Summary row
        _TodaySummary(entries: entries),
        const SizedBox(height: 8),

        // Entry cards
        ...entries.map(
          (entry) => TimeEntryCard(
            entry: entry,
            onTap: onEntryTap != null ? () => onEntryTap!(entry) : null,
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

/// Shows a summary of today's total worked and break time.
class _TodaySummary extends StatelessWidget {
  const _TodaySummary({required this.entries});

  final List<TimeEntriesTableData> entries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Calculate totals
    int totalWorkedMinutes = 0;
    int totalBreakMinutes = 0;
    int completedCount = 0;
    bool hasActive = false;

    for (final entry in entries) {
      if (entry.clockOutTime == null) {
        hasActive = true;
      } else {
        completedCount++;
      }
      totalWorkedMinutes += entry.workedMinutes ?? 0;
      totalBreakMinutes += entry.breakMinutes ?? 0;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Worked time
            Expanded(
              child: _SummaryItem(
                icon: Icons.work_outline,
                label: 'Worked',
                value: _formatMinutes(totalWorkedMinutes),
                color: theme.colorScheme.primary,
              ),
            ),

            // Divider
            Container(
              height: 32,
              width: 1,
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
            ),

            // Break time
            Expanded(
              child: _SummaryItem(
                icon: Icons.coffee_outlined,
                label: 'Breaks',
                value: _formatMinutes(totalBreakMinutes),
                color: theme.colorScheme.tertiary,
              ),
            ),

            // Divider
            Container(
              height: 32,
              width: 1,
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
            ),

            // Entry count
            Expanded(
              child: _SummaryItem(
                icon: hasActive ? Icons.timer : Icons.check_circle_outline,
                label: 'Entries',
                value: hasActive
                    ? '${completedCount + 1} (1 active)'
                    : '$completedCount',
                color:
                    hasActive ? theme.colorScheme.primary : Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatMinutes(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0) {
      return '${hours}h ${mins}m';
    }
    return '${mins}m';
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
