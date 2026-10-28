import 'dart:async';

import '../../../data/models/audit_log.dart';
import '../../../data/models/security_context.dart';
import '../../../data/models/time_entry.dart';
import '../../../data/models/timesheet_summary.dart';
import '../../../data/repositories/audit_log_repository.dart';
import '../../../data/repositories/time_entry_repository.dart';

/// Approval workflow for manager timesheet actions.
class ApprovalService {
  ApprovalService({
    TimeEntryRepository? timeEntryRepository,
    AuditLogRepository? auditLogRepository,
  })  : _timeEntryRepository = timeEntryRepository ?? TimeEntryRepository(),
        _auditLogRepository = auditLogRepository ?? AuditLogRepository();

  final TimeEntryRepository _timeEntryRepository;
  final AuditLogRepository _auditLogRepository;

  /// Approve all pending entries in a timesheet.
  Future<void> approveTimesheet(
    SecurityContext context,
    TimesheetSummary timesheet,
  ) async {
    await _updateEntries(
      context: context,
      timesheet: timesheet,
      nextStatus: TimeEntryStatus.approved,
      reason: null,
    );
  }

  /// Reject all pending entries in a timesheet with a reason.
  Future<void> rejectTimesheet(
    SecurityContext context,
    TimesheetSummary timesheet,
    String reason,
  ) async {
    await _updateEntries(
      context: context,
      timesheet: timesheet,
      nextStatus: TimeEntryStatus.rejected,
      reason: reason,
    );
  }

  Future<void> _updateEntries({
    required SecurityContext context,
    required TimesheetSummary timesheet,
    required TimeEntryStatus nextStatus,
    String? reason,
  }) async {
    if (!context.role.canManageAllAppointments) {
      throw SecurityException('Only managers/admins can approve timesheets');
    }

    final pendingEntries = timesheet.entries
        .where((entry) => entry.status == TimeEntryStatus.pending)
        .toList();

    for (final entry in pendingEntries) {
      final updated = entry.copyWith(
        status: nextStatus,
        approvedByUserId: context.userId,
        approvedAt: DateTime.now(),
        rejectionReason: nextStatus == TimeEntryStatus.rejected ? reason : null,
        updatedAt: DateTime.now(),
      );

      await _timeEntryRepository.updateTimeEntry(
        context: context,
        entry: updated,
      );

      // Audit per entry (best effort, no PHI)
      unawaited(_auditLogRepository.logEvent(AuditLogEntry(
        businessId: context.businessId,
        userId: context.userId,
        actionType: AuditActionType.phiWrite,
        entityType: 'TimeEntry',
        entityId: entry.id,
        metadata: {
          'action': nextStatus == TimeEntryStatus.approved ? 'approved' : 'rejected',
          'periodStart': timesheet.periodStart.toIso8601String(),
          'periodEnd': timesheet.periodEnd.toIso8601String(),
        },
      )));
    }

    // Audit log once for the timesheet action (best effort).
    unawaited(_auditLogRepository.logEvent(AuditLogEntry(
      businessId: context.businessId,
      userId: context.userId,
      actionType: AuditActionType.phiWrite,
      entityType: 'Timesheet',
      entityId: timesheet.staffId,
      metadata: {
        'periodStart': timesheet.periodStart.toIso8601String(),
        'periodEnd': timesheet.periodEnd.toIso8601String(),
        'action': nextStatus == TimeEntryStatus.approved ? 'approved' : 'rejected',
      },
    )));
  }
}
