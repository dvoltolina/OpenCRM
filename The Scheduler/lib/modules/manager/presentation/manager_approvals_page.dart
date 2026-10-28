import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/providers.dart';
import '../../../data/models/timesheet_summary.dart';
import '../providers/manager_providers.dart';
import '../services/approval_service.dart';
import 'timesheet_detail_page.dart';

class ManagerApprovalsPage extends ConsumerWidget {
  const ManagerApprovalsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timesheetsAsync = ref.watch(pendingTimesheetsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Approvals')),
      body: timesheetsAsync.when(
        data: (timesheets) {
          if (timesheets.isEmpty) {
            return const Center(child: Text('No pending timesheets.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: timesheets.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final timesheet = timesheets[index];
              return _TimesheetCard(timesheet: timesheet);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            Center(child: Text('Unable to load approvals: $error')),
      ),
    );
  }
}

class _TimesheetCard extends ConsumerStatefulWidget {
  const _TimesheetCard({required this.timesheet});

  final TimesheetSummary timesheet;

  @override
  ConsumerState<_TimesheetCard> createState() => _TimesheetCardState();
}

class _TimesheetCardState extends ConsumerState<_TimesheetCard> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final ts = widget.timesheet;
    final dateRange =
        '${DateFormat('MMM d').format(ts.periodStart)} - ${DateFormat('MMM d, yyyy').format(ts.periodEnd)}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ts.staffName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        dateRange,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Text(
                  '${ts.totalWorkedHours.toStringAsFixed(1)} hrs',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ManagerTimesheetDetailPage(ts),
                    ),
                  ),
                  child: const Text('View Details'),
                ),
                const Spacer(),
                OutlinedButton(
                  onPressed: _isProcessing
                      ? null
                      : () => _reject(context, ref, ts),
                  child: const Text('Reject'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _isProcessing
                      ? null
                      : () => _approve(context, ref, ts),
                  child: _isProcessing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Approve'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approve(
    BuildContext context,
    WidgetRef ref,
    TimesheetSummary timesheet,
  ) async {
    final ctx = ref.read(securityContextProvider).valueOrNull;
    if (ctx == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approve Timesheet'),
        content: Text(
          'Approve all pending entries for ${timesheet.staffName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isProcessing = true);
    try {
      final service = ApprovalService(
        timeEntryRepository: ref.read(timeEntryRepositoryProvider),
        auditLogRepository: ref.read(auditLogRepositoryProvider),
      );
      await service.approveTimesheet(ctx, timesheet);
      ref.invalidate(pendingTimesheetsProvider);
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Approved timesheet for ${timesheet.staffName}'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _reject(
    BuildContext context,
    WidgetRef ref,
    TimesheetSummary timesheet,
  ) async {
    final ctx = ref.read(securityContextProvider).valueOrNull;
    if (ctx == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reject Timesheet'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(labelText: 'Reason (required)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext, true);
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (confirmed != true || reasonController.text.trim().isEmpty) return;

    setState(() => _isProcessing = true);
    try {
      final service = ApprovalService(
        timeEntryRepository: ref.read(timeEntryRepositoryProvider),
        auditLogRepository: ref.read(auditLogRepositoryProvider),
      );
      await service.rejectTimesheet(
        ctx,
        timesheet,
        reasonController.text.trim(),
      );
      ref.invalidate(pendingTimesheetsProvider);
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Rejected timesheet for ${timesheet.staffName}'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}
