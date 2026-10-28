import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/providers.dart';
import '../../../../data/models/audit_log.dart';
import '../../../../data/models/time_entry.dart';
import '../../../../data/models/timesheet_summary.dart';

/// Quick approval card for timesheet approval from admin dashboard.
///
/// Allows one-tap approval with confirmation toast.
/// HIPAA: Contains staff name - audit logged.
class QuickApprovalCard extends ConsumerWidget {
  const QuickApprovalCard({
    required this.timesheet,
    super.key,
  });

  final TimesheetSummary timesheet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Timesheet: ${timesheet.staffName}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatDate(timesheet.periodStart)} - ${_formatDate(timesheet.periodEnd)} | ${timesheet.totalWorkedHours.toStringAsFixed(1)} hrs',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => _handleReject(context, ref),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
              ),
              child: const Text('Reject'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () => _handleApprove(context, ref),
              child: const Text('Approve'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}';
  }

  Future<void> _handleApprove(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Timesheet'),
        content: Text(
          'Approve timesheet for ${timesheet.staffName}?\n'
          '${timesheet.totalWorkedHours.toStringAsFixed(1)} hours',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    try {
      final securityContext = ref.read(securityContextProvider).valueOrNull;
      if (securityContext == null) {
        throw Exception('Not authenticated');
      }

      final timeEntryRepo = ref.read(timeEntryRepositoryProvider);

      // Approve all entries in the period
      for (final entry in timesheet.entries) {
        if (entry.status == TimeEntryStatus.pending) {
          await timeEntryRepo.approveTimeEntry(
            context: securityContext,
            timeEntryId: entry.id,
          );
        }
      }

      // Audit log (no PHI - only staffId)
      await ref.read(auditLogRepositoryProvider).logEvent(
        AuditLogEntry(
          businessId: securityContext.businessId,
          userId: securityContext.userId,
          actionType: AuditActionType.phiWrite,
          entityType: 'Timesheet',
          entityId: timesheet.staffId,
          metadata: {
            'action': 'approve',
            'periodStart': timesheet.periodStart.toIso8601String(),
            'periodEnd': timesheet.periodEnd.toIso8601String(),
            'hours': timesheet.totalWorkedHours,
          },
          timestamp: DateTime.now(),
        ),
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Timesheet approved'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to approve: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _handleReject(BuildContext context, WidgetRef ref) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => _RejectDialog(),
    );

    if (reason == null || reason.isEmpty) return;
    if (!context.mounted) return;

    try {
      final securityContext = ref.read(securityContextProvider).valueOrNull;
      if (securityContext == null) {
        throw Exception('Not authenticated');
      }

      final timeEntryRepo = ref.read(timeEntryRepositoryProvider);

      // Reject all entries in the period
      for (final entry in timesheet.entries) {
        if (entry.status == TimeEntryStatus.pending) {
          await timeEntryRepo.rejectTimeEntry(
            context: securityContext,
            timeEntryId: entry.id,
            reason: reason,
          );
        }
      }

      // Audit log (no PHI - only staffId)
      await ref.read(auditLogRepositoryProvider).logEvent(
        AuditLogEntry(
          businessId: securityContext.businessId,
          userId: securityContext.userId,
          actionType: AuditActionType.phiWrite,
          entityType: 'Timesheet',
          entityId: timesheet.staffId,
          metadata: {
            'action': 'reject',
            'periodStart': timesheet.periodStart.toIso8601String(),
            'periodEnd': timesheet.periodEnd.toIso8601String(),
            'reason': reason,
          },
          timestamp: DateTime.now(),
        ),
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Timesheet rejected'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reject: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}

class _RejectDialog extends StatefulWidget {
  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<_RejectDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reject Timesheet'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Please provide a reason for rejection:'),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'Reason',
              hintText: 'e.g., Hours don\'t match schedule',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            autofocus: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_controller.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please provide a reason')),
              );
              return;
            }
            Navigator.of(context).pop(_controller.text.trim());
          },
          child: const Text('Reject'),
        ),
      ],
    );
  }
}
