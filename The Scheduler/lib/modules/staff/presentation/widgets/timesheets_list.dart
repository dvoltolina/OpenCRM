import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/security_context.dart';
import '../../../../data/models/timesheet_summary.dart';
import '../../providers/timesheet_providers.dart';
import 'timesheet_card.dart';

/// List widget displaying all filtered timesheets.
class TimesheetsList extends ConsumerWidget {
  const TimesheetsList({
    super.key,
    required this.context,
    required this.onTimesheetTap,
    required this.onApprove,
  });

  final SecurityContext context;
  final ValueChanged<TimesheetSummary> onTimesheetTap;
  final ValueChanged<TimesheetSummary> onApprove;

  @override
  Widget build(BuildContext ctx, WidgetRef ref) {
    final timesheetsAsync = ref.watch(filteredTimesheetsProvider(context));
    final periodStart = ref.watch(selectedPayPeriodStartProvider);
    final periodEnd = ref.watch(selectedPayPeriodEndProvider);

    return timesheetsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => TimesheetsErrorState(
        error: error.toString(),
        onRetry: () => ref.invalidate(timesheetSummariesProvider(context)),
      ),
      data: (timesheets) {
        if (timesheets.isEmpty) {
          return TimesheetsEmptyState(
            periodStart: periodStart,
            periodEnd: periodEnd,
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(timesheetSummariesProvider(context));
          },
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: timesheets.length,
            itemBuilder: (_, index) {
              final timesheet = timesheets[index];
              return TimesheetCard(
                timesheet: timesheet,
                onTap: () => onTimesheetTap(timesheet),
                onApprove: timesheet.isPendingApproval
                    ? () => onApprove(timesheet)
                    : null,
              );
            },
          ),
        );
      },
    );
  }
}

/// Empty state widget for when no timesheets are found.
class TimesheetsEmptyState extends StatelessWidget {
  const TimesheetsEmptyState({
    super.key,
    required this.periodStart,
    required this.periodEnd,
  });

  final DateTime periodStart;
  final DateTime periodEnd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat.MMMd();

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.schedule_outlined,
            size: 64,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No timesheets found',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${dateFormat.format(periodStart)} - ${dateFormat.format(periodEnd)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Staff time entries will appear here once recorded.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}

/// Error state widget for when timesheet loading fails.
class TimesheetsErrorState extends StatelessWidget {
  const TimesheetsErrorState({
    super.key,
    required this.error,
    required this.onRetry,
  });

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load timesheets',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
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
    );
  }
}
