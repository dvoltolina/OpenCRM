import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/ui/components/components.dart';
import '../../../data/models/security_context.dart';
import '../../../data/models/time_entry.dart';
import '../../../data/models/timesheet_summary.dart';
import '../providers/timesheet_providers.dart';
import 'widgets/bulk_actions_bar.dart';
import 'widgets/reject_entry_dialog.dart';
import 'widgets/time_entry_card.dart';
import 'widgets/timesheet_day_header.dart';
import 'widgets/timesheet_empty_state.dart';
import 'widgets/timesheet_error_view.dart';
import 'widgets/timesheet_summary_card.dart';

/// Detail page showing a single staff member's timesheet for the selected period.
///
/// Displays individual time entries with approval/rejection actions,
/// day-by-day breakdown, and summary statistics.
class TimesheetDetailPage extends ConsumerStatefulWidget {
  const TimesheetDetailPage({
    super.key,
    required this.staffId,
    required this.staffName,
  });

  final String staffId;
  final String staffName;

  @override
  ConsumerState<TimesheetDetailPage> createState() => _TimesheetDetailPageState();
}

class _TimesheetDetailPageState extends ConsumerState<TimesheetDetailPage> {
  @override
  Widget build(BuildContext context) {
    final securityContext = ref.watch(currentSecurityContextProvider);

    if (securityContext == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final timesheetAsync = ref.watch(
      staffTimesheetProvider((context: securityContext, staffId: widget.staffId)),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.staffName),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(
                staffTimesheetProvider((context: securityContext, staffId: widget.staffId)),
              );
            },
          ),
        ],
      ),
      body: timesheetAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => TimesheetErrorView(
          error: error.toString(),
          onRetry: () {
            ref.invalidate(
              staffTimesheetProvider((context: securityContext, staffId: widget.staffId)),
            );
          },
        ),
        data: (timesheet) => _TimesheetContent(
          timesheet: timesheet,
          securityContext: securityContext,
        ),
      ),
    );
  }
}

class _TimesheetContent extends ConsumerWidget {
  const _TimesheetContent({
    required this.timesheet,
    required this.securityContext,
  });

  final TimesheetSummary timesheet;
  final SecurityContext securityContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesByDay = _groupEntriesByDay(timesheet.entries);
    final sortedDays = entriesByDay.keys.toList()..sort();

    return SingleChildScrollView(
      padding: AppSpacing.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary card
          TimesheetSummaryCard(timesheet: timesheet),
          VSpace.lg,

          // Bulk actions (if pending entries exist)
          if (timesheet.pendingEntriesCount > 0)
            BulkActionsBar(
              pendingCount: timesheet.pendingEntriesCount,
              onApproveAll: () => _approveAll(context, ref),
            ),

          VSpace.md,

          // Day-by-day entries
          for (final day in sortedDays) ...[
            TimesheetDayHeader(
              date: day,
              entries: entriesByDay[day]!,
            ),
            VSpace.xs,
            for (final entry in entriesByDay[day]!)
              TimeEntryCard(
                entry: entry,
                onApprove: entry.status == TimeEntryStatus.pending
                    ? () => _approveEntry(context, ref, entry)
                    : null,
                onReject: entry.status == TimeEntryStatus.pending
                    ? () => _rejectEntry(context, ref, entry)
                    : null,
              ),
            VSpace.md,
          ],

          // Empty state if no entries
          if (timesheet.entries.isEmpty)
            const TimesheetEmptyState(),
        ],
      ),
    );
  }

  Map<DateTime, List<TimeEntry>> _groupEntriesByDay(List<TimeEntry> entries) {
    final map = <DateTime, List<TimeEntry>>{};
    for (final entry in entries) {
      final day = DateTime(
        entry.clockInTime.year,
        entry.clockInTime.month,
        entry.clockInTime.day,
      );
      map.putIfAbsent(day, () => []).add(entry);
    }
    // Sort entries within each day by clock-in time
    for (final list in map.values) {
      list.sort((a, b) => a.clockInTime.compareTo(b.clockInTime));
    }
    return map;
  }

  Future<void> _approveAll(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approve All Entries'),
        content: Text(
          'Approve all ${timesheet.pendingEntriesCount} pending entries?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Approve All'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final repository = ref.read(timeEntryRepositoryProvider);
      final pendingEntries = timesheet.entries
          .where((e) => e.status == TimeEntryStatus.pending)
          .map((e) => e.id)
          .toList();

      await repository.bulkApproveTimeEntries(
        context: securityContext,
        timeEntryIds: pendingEntries,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All entries approved'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Refresh
      ref.invalidate(staffTimesheetProvider);
      ref.invalidate(timesheetSummariesProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to approve: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _approveEntry(
    BuildContext context,
    WidgetRef ref,
    TimeEntry entry,
  ) async {
    try {
      final repository = ref.read(timeEntryRepositoryProvider);
      await repository.approveTimeEntry(
        context: securityContext,
        timeEntryId: entry.id,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Entry approved'),
            backgroundColor: Colors.green,
          ),
        );
      }

      ref.invalidate(staffTimesheetProvider);
      ref.invalidate(timesheetSummariesProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to approve: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectEntry(
    BuildContext context,
    WidgetRef ref,
    TimeEntry entry,
  ) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => RejectEntryDialog(entry: entry),
    );

    if (reason == null || reason.isEmpty) return;

    try {
      final repository = ref.read(timeEntryRepositoryProvider);
      await repository.rejectTimeEntry(
        context: securityContext,
        timeEntryId: entry.id,
        reason: reason,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Entry rejected'),
            backgroundColor: Colors.orange,
          ),
        );
      }

      ref.invalidate(staffTimesheetProvider);
      ref.invalidate(timesheetSummariesProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reject: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
